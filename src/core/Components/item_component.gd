class_name ItemComponent
extends BaseItemComponent

## ===============================================================
## ItemComponent - Verantwortlich für Snap-Feedback und Platzierbarkeit
## ===============================================================

# Visuelles Feedback
@export var normal_color: Color = Color.WHITE
@export var valid_color: Color = Color.LIME_GREEN
@export var invalid_color: Color = Color.CRIMSON

@export var ItemComponentArea2D: Area2D = null

var candidate: PlacementCandidate = PlacementCandidate.new()

class PlacementCandidate:
	var highest_item: ItemComponent			= null
	var highest_storage: StorageComponent	= null
	var placeable_storage: StorageComponent	= null
	var direction: Vector2					= Vector2.ZERO
	var distance: float						= INF
	var highest_item_height: float			= -INF
	var highest_storage_height: float		= -INF

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
	status = PlacementState.PLACED	# Standardwert setzen (muss im _ready passieren, sonst wird Setter nicht aufgerufen)
	if not ItemComponentArea2D: ItemComponentArea2D = _get_Area2D()

func get_placement_candidate() -> PlacementCandidate:
	candidate = PlacementCandidate.new()
	_collect_environment()
	_find_placeable_storage()
	return candidate

## ===============================================================
## [br]Sammelt alle relevanten Informationen über die Umgebung
## [br]dieser ItemComponent.
## [br] 
## [br]Diese Funktion führt KEINE Entscheidungen über Platzierbarkeit
## [br]durch.
## [br] 
## [br] Sie bestimmt ausschließlich:
## [br] 
## [br]- höchste sichtbare ItemComponent
## [br]- höchste sichtbare StorageComponent
## [br]- deren Höhenwerte
## [br]- Distanz und Richtung (geometrische Basisdaten)
## [br] 
## [br]Ergebnis wird im PlacementCandidate gespeichert.
## [br]===============================================================
func _collect_environment() -> void:
	var relevant_components: Array = _get_Array_with_Item_and_StorageComponents()

	var highest_item: ItemComponent= _find_highest_component(relevant_components, ItemComponent) as ItemComponent
	var highest_storage: StorageComponent = _find_highest_component(relevant_components, StorageComponent) as StorageComponent

	candidate.highest_item = highest_item
	candidate.highest_storage = highest_storage

	if highest_item:
		candidate.highest_item_height = highest_item.myItem.total_height

	if highest_storage:
		candidate.highest_storage_height = highest_storage.myItem.total_height
		candidate.direction = highest_storage.global_position - self.global_position
		candidate.distance = candidate.direction.length()

## ===============================================================
## [br]Entscheidet, ob das aktuell gefundene Storage
## [br]tatsächlich als Platzierungsziel verwendet werden darf.
## [br] 
## [br]Voraussetzung:
## [br]_collect_environment() wurde bereits ausgeführt.
## [br] 
## [br]Regel:
## [br]Ein Storage ist nur gültig, wenn kein höheres Item
## [br]darüber liegt.
## [br] 
## [br]Ergebnis:
## [br]- placeable_storage bleibt gesetzt
## [br]- oder wird auf null gesetzt
## [br]===============================================================
func _find_placeable_storage() -> void:
	
	# Kein Storage gefunden → nichts zu tun
	if not candidate.highest_storage:
		candidate.placeable_storage = null
		return

	# Kein Item darüber → frei platzierbar
	if not candidate.highest_item:
		candidate.placeable_storage = candidate.highest_storage
		return

	# Entscheidungsregel:
	# höheres Item blockiert Storage
	if candidate.highest_item_height > candidate.highest_storage_height:
		candidate.placeable_storage = null
	else:
		candidate.placeable_storage = candidate.highest_storage
	
## Sucht nach höchstem Component bei aktuellem ItemComponent (also: self)[br][br]Gibt Node2D zurück, was eine Item- oder StorageComponent sein kann
func _find_highest_component(all_Components: Array, component_type: Variant) -> BaseItemComponent:
	if all_Components.is_empty():	return null
	
	var current_height: float = -INF
	var highest_Component: BaseItemComponent = null
	var closest_distance: float = INF
	
	for component: BaseItemComponent in all_Components:
		if not is_instance_of(component, component_type):	continue	# Nur eine Sorte Components
			
		var component_height: float = component.myItem.total_height
		if component_height < current_height: 				continue	# nur Höhere

		var distance: float = self.global_position.distance_to(component.global_position)
		if component_height == current_height:
			if distance > closest_distance:					continue	# Gleich hoch → näheren nehmen
		
		current_height = component_height
		highest_Component = component
		closest_distance = distance
	
	return highest_Component

## Sucht nach allen Storage und ItemComponents, die nicht [color=red]self[/color] sind.
func _get_Array_with_Item_and_StorageComponents() -> Array:
	var areas: Array = ItemComponentArea2D.get_overlapping_areas()
	var itemOrStorageComponents: Array = []
	for area: Area2D in areas:
		var component: BaseItemComponent = _get_BaseItemComponent(area)

		if component is StorageComponent or component is ItemComponent:
			if _is_self_or_my_child(component): continue
			itemOrStorageComponents.append(component)
	return itemOrStorageComponents

## sucht aus einer Component die nächst höhere Component oder gibt NULL zurück, wenn die nächst höhere Component BaseItem oder ItemRoot ist[br][br]Hauptsächlich für Area2D benötigt
func _get_BaseItemComponent(component: Node)-> BaseItemComponent:
	var parent: Node = component.get_parent()
	if not parent: return null
	if parent is BaseItem: return null
	if parent is ItemRoot: return null
	if parent is BaseItemComponent: return parent
	return _get_BaseItemComponent(parent)
