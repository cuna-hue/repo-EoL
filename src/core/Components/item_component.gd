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
var placeable_storage: StorageComponent = null	# höchstes Storage, das belegt werden kann (Achtung: es ist i.d.R. hovering_storage, aber nur wenn nicht von hovering_item verdeckt

## Enum: [br]- PLACED[br]- CAN_SNAP[br]- CAN_PLACE_FREE[br]- CANNOT_PLACE[br]- UNKNOWN
enum PlacementState {
	PLACED,				# abgelegt
	CAN_SNAP,			# snap möglich
	CAN_PLACE_FREE,		# freies ablegen möglich
	CANNOT_PLACE,		# kein ablegen möglich
	UNKNOWN				# Irgendwas ist schief gegangen und der Status ist undefiniert
}

var status: PlacementState:
	get: return status
	set(Value): 
		if Value == PlacementState.UNKNOWN:
			push_warning(myItem.name, ": ItemComponent hat PlacementState 'Unknown' erhalten. (", self, ") ~ geändert auf CANNOT_PLACE")
			Value = PlacementState.CANNOT_PLACE
		match Value:
			PlacementState.PLACED:
				modulate = normal_color
			PlacementState.CAN_SNAP, PlacementState.CAN_PLACE_FREE:
				modulate = valid_color
			_:	modulate = invalid_color
		status = Value

func _ready() -> void:
	myItem = _find_parent(self)
	status = PlacementState.PLACED	# Standardwert setzen (muss im _ready passieren, sonst wird Setter nicht aufgerufen)

## sucht rekursiv nach einem BaseItem.[br][br]Bricht ab beim ItemRoot oder wenn es keine Node gibt
func _find_parent(current_Parent: Node) -> BaseItem:
	if not current_Parent:
		push_warning("ItemComponent außerhalb von BaseItem und ItemRoot: %s" % get_path())
		return null
	current_Parent = current_Parent.get_parent()
	if current_Parent is BaseItem:
		return current_Parent
	if current_Parent is ItemRoot:
		push_warning("ItemComponent außerhalb von BaseItem (aber innerhalb ItemRoot): %s" % get_path())
		return null
	return _find_parent(current_Parent)

## Aktualisiert den Status dieser ItemComponent. Prüft welche Area2D mit ihm interagieren. (ItemComponents und StorageComponents)[br][br]Wählt aus allen Area2D die höchste aus und entscheidet ob es platziert werden kann oder nicht.[br][br]Keine direkte Rückmeldung - Änderung im [color=red]status[/color]
func find_placeable_storage() -> StorageComponent:
	var relevant_components: Array = _get_Array_with_Storage_and_ItemComponents()	
	
	hovering_item = _find_highest_component(relevant_components, ItemComponent) as ItemComponent
	hovering_storage = _find_highest_component(relevant_components, StorageComponent) as StorageComponent
	
	placeable_storage = hovering_storage
	if not hovering_item or not hovering_storage:
		return placeable_storage

	# === Beide existieren (komplexester Fall) ===
	var item_height:	float = hovering_item.myItem.total_height
	var storage_height: float = hovering_storage.myItem.total_height
	
	if item_height > storage_height:
		# Item liegt höher als das Storage → blockiert
		placeable_storage = null

	return placeable_storage


	
## Sucht nach höchstem Component bei aktuellem ItemComponent (also: self)[br][br]Gibt Node2D zurück, was eine Item- oder StorageComponent sein kann
func _find_highest_component(all_Components: Array, component_type: Variant) -> Area2D:
	if all_Components.is_empty():	return null
	
	var current_height: float = -INF
	var highest_Component: Node2D = null
	var closest_distance: float = INF
	
	for component: Area2D in all_Components:
		if not is_instance_of(component, component_type):	continue	# Nur eine Sorte Components
		if _is_own_storage_or_item(component):				continue	# Nicht selbst + Nicht Children
			
		var component_height: float = component.myItem.total_height
		if component_height < current_height: 				continue	# nur Höhere

		var distance: float = self.position.distance_to(component.position)
		if component_height == current_height:
			if distance > closest_distance:					continue	# Gleich hoch → näheren nehmen
		
		current_height = component_height
		highest_Component = component
		closest_distance = distance
	
	return highest_Component

## Sucht nach allen Storage und ItemComponents, die nicht [color=red]self[/color] sind.
func _get_Array_with_Storage_and_ItemComponents() -> Array:
	var areas: Array = get_overlapping_areas()
	var itemOrStorageComponents: Array = []
	for area: Area2D in areas:
		if area is StorageComponent or area is ItemComponent:
			if not _is_own_storage_or_item(area):
				itemOrStorageComponents.append(area)
	return itemOrStorageComponents

## Prüft ob Area2D ein Storage oder ItemComponent ist und ob es zum selben Item gehört.
func _is_own_storage_or_item(area: Area2D) -> bool:
	# Jede StorageComponent und jede ItemComponent gehört IMMER zu einem BaseItem, sodass myItem immer definiert ist!
	if area is StorageComponent:
		return area.myItem == myItem or myItem.is_ancestor_of(area.myItem)
	if area is ItemComponent:
		return area.myItem == myItem or myItem.is_ancestor_of(area.myItem)
	return false
