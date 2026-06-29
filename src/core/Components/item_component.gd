class_name ItemComponent
extends Area2D

## ===============================================================
## ItemComponent - Verantwortlich für Snap-Feedback und Platzierbarkeit
## ===============================================================

# Referenz zum übergeordneten Item (BaseItem)
var myItem: BaseItem = null

# Visuelles Feedback
@export var normal_color: Color = Color.WHITE
@export var valid_color: Color = Color.LIME_GREEN
@export var invalid_color: Color = Color.CRIMSON

var hovering_storage: StorageComponent = null   # aktuell unter der Maus befindliche Storage
var hovering_item: ItemComponent = null			# aktuell ItemComponent unter diesem Item
var hovering_highest_BaseItem: BaseItem = null	# höchstes BaseItem

enum PlacementState {
	PLACED,				# abgelegt
	CAN_SNAP,			# snap möglich
	CAN_PLACE_FREE,		# freies ablegen möglich
	CANNOT_PLACE,		# kein ablegen möglich
	UNKNOWN				# Irgendwas ist schief gegangen und der Status ist undefiniert
}

var status: PlacementState = PlacementState.PLACED:
	get: return status
	set(Value): 
		if Value == PlacementState.UNKNOWN:
			push_warning(myItem.name, ": ItemComponent hat PlacementState 'Unknown' erhalten. (", self, ") ~ geändert auf CANNOT_PLACE")
			Value = PlacementState.CANNOT_PLACE
		status = Value

func _ready() -> void:
	myItem = _find_parent(self)
	if not myItem:
		push_warning("ItemComponent muss direktes oder indirektes Child eines BaseItem sein")
		return
	
	# Standardfarbe setzen
	modulate = normal_color

## sucht rekursiv nach einem BaseItem.[br][br]Bricht ab beim ItemRoot oder wenn es keine Node gibt
func _find_parent(current_Parent: Node) -> BaseItem:
	if not current_Parent:
		push_warning("ItemComponent außerhalb von BaseItem und ItemRoot")
		return null
	current_Parent = current_Parent.get_parent()
	if current_Parent is BaseItem:
		return current_Parent
	if current_Parent is ItemRoot:
		push_warning("ItemComponent außerhalb von BaseItem (aber innerhalb ItemRoot)")
		return null
	return _find_parent(current_Parent)

## Aktualisiert den Status dieser ItemComponent. Prüft welche Area2D mit ihm interagieren. (ItemComponents und StorageComponents)[br][br]Wählt aus allen Area2D die höchste aus und entscheidet ob es platziert werden kann oder nicht.[br][br]Keine direkte Rückmeldung - Änderung im [color=red]status[/color]
func update_placement_status() -> PlacementState:
	var relevant_icon_storage_Components: Array = _get_Array_with_Storage_and_ItemComponents()
	hovering_item = _find_highest_component(relevant_icon_storage_Components, ItemComponent) as ItemComponent
	hovering_storage = _find_highest_component(relevant_icon_storage_Components, StorageComponent) as StorageComponent

	status = PlacementState.UNKNOWN # Fallback, falls nicht alle Kombis wirken (wird nach Warnung auf CANNOT_PLACE geändert

	if not hovering_storage and not hovering_item:
		# Item ist über nichts und kann beliebig platziert werden
		status = PlacementState.CAN_PLACE_FREE
	
	if not hovering_item or hovering_item.myItem == hovering_storage.myItem or hovering_item.myItem.total_height <= hovering_storage.myItem.total_height:
		# Item ist über storage und kann platziert werden (SNAP) --- das gefundene ItemComponent gehört zum Storage
		status = PlacementState.CAN_SNAP
		
	if not hovering_storage or hovering_item.myItem.total_height > hovering_storage.myItem.total_height:
		# Item ist über ItemComponent und kann nicht platziert werden (kein SNAP, kein Ablegen) --- das gefunden Storage liegt tiefer
		status = PlacementState.CANNOT_PLACE
		
	return status

## Sucht nach höchstem Component bei aktuellem ItemComponent (also: self)[br][br]Gibt Node2D zurück, was eine Item- oder StorageComponent sein kann
func _find_highest_component(all_Components: Array, component_type: Variant) -> Node2D:
	if all_Components.is_empty():	return null
	
	var current_height: float = -INF
	var highest_Component: Node2D = null
	var closest_distance: float = INF
	
	for component: Node2D in all_Components:
		if not is_instance_of(component, component_type):	continue	# Nur eine Sorte Components
		if component.myItem == self.myItem:					continue	# Nicht selbst
		if component.is_ancestor_of(self):					continue	# Nicht Children
			
		var component_height: float = component.myItem.total_height
		if component_height < current_height: 				continue	# nur Höhere

		var distance: float = self.position.distance_to(component.position)
		if component_height == current_height:
			if distance > closest_distance:					continue	# Gleich hoch → näheren nehmen
		
		current_height = component_height
		highest_Component = component
		closest_distance = distance
	
	return highest_Component

## Prüft, ob dieses ItemComponent frei abgelegt werden kann (keine anderen Components darunter)
func _get_Array_with_Storage_and_ItemComponents() -> Array:
	var areas: Array = get_overlapping_areas()
	var itemOrStorageComponents: Array = []
	for area: Area2D in areas:
		if area is StorageComponent or area is ItemComponent:
			if not _is_own_storage_or_item(area):
				itemOrStorageComponents.append(area)
	return itemOrStorageComponents

func _is_own_storage_or_item(area: Area2D) -> bool:
	if area is StorageComponent:
		return area.myItem == myItem or myItem.is_ancestor_of(area.myItem)
	if area is ItemComponent:
		return area.myItem == myItem or myItem.is_ancestor_of(area.myItem)
	return false
