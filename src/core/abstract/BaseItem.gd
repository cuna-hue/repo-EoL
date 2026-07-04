class_name BaseItem
extends Node2D

## Höhe in cm
@export var height: float = 1.0

## Gewicht in g
@export var weight: float = 1000.0

var total_height: float = 0.0:
	get: return total_height
	set(value): 
		total_height = value + height
		_set_children_on_own_height()
		print("%s-height: %.2f cm" % [name, total_height])

var movement_distance: float = 0.0
var total_movement_distance: float = 0.0

var Visual_comp: 	Node2D				= null
var ItemArea:	 	BaseItemArea 		= null
var item_root: 		ItemRoot 			= null
var itemParts_comp: ItemPartsComponent 	= null
var inventory_Comp: InventoryComponent	= null

var drag_offset: 	Vector2 			= Vector2.ZERO
var is_dragging: 	bool 				= false

## Gibt an, ob das BaseItem sich bewegt.[br][br]Trennung von Drag ist bewusst: auch andere Systeme können Bewegung auslösen (Snap, Reparent, Events, AI, etc.).
var is_moving: bool = false		

var _shake_tween: Tween = null
const SHAKE_CANCEL_DISTANCE: float = 10.0

#Code-Beginn ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Initialisiert das Item nach Node-Aufbau.[br]
## Verbindet Drag-Signale, setzt Referenzen auf Kernkomponenten und registriert sich im ItemRoot.
func _ready() -> void:
	var drag_comp: DragComponent = get_node_or_null("DragComponent")  
	if drag_comp:
		drag_comp.drag_stopped.connect(_on_drag_stopped)
		drag_comp.drag_started.connect(_on_drag_started)
		drag_comp.drag_moved.connect(_on_drag_moved)
		
	ItemArea   = get_node_or_null("Area2D") 
	if ItemArea: ItemArea.myItem = self

	Visual_comp		= get_node_or_null("VisualComponent")
	itemParts_comp 	= get_node_or_null("ItemPartsComponent") 
	inventory_Comp 	= get_node_or_null("InventoryComponent") 
	
	await get_tree().process_frame

	item_root = GameManager.item_root
	if not item_root:
		push_error("GameManager.item_root nicht gefunden!")
		return

	_init_components()

## Initialisiert Drag-Zustand.[br]
## Bringt Item nach vorne, berechnet Offset zur Maus und setzt Bewegungsstatus zurück.
func _on_drag_started(mouse_pos: Vector2) -> void:
	_bring_to_front()
	drag_offset = mouse_pos - global_position
	total_height = 0.0
	is_moving = true
	movement_distance = 0.0

## Finalisiert Drag-Vorgang und entscheidet über Platzierung.[br]
## Prüft Placement-State und führt Snap, Free-Place oder Abbruch aus.
func _on_drag_stopped(drag: DragComponent) -> void:
	if not drag:
		push_warning("WARNING: eine DragComponent hat ein 'drag_stop'-Signal ohne DragComponent (self) gesendet.")
		return

	if not itemParts_comp: 
		drag.end_drag()
		push_warning("WARNING: Item ohne ItemPartsComponent gefunden! Kann nicht abgelegt werden: ", name, " - ", get_path())
	else:
		var bi_status: ItemComponent.PlacementState = itemParts_comp.can_be_placed()

		if bi_status == ItemComponent.PlacementState.CAN_SNAP:
			_reparent_to_storage(itemParts_comp.best_target.storage)
			total_height = _recalculate_height()
			is_moving = false
			position += itemParts_comp.best_target.direction
			drag.end_drag()

		if bi_status == ItemComponent.PlacementState.CAN_PLACE_FREE:
			_reparent_to_storage(itemParts_comp.best_target.storage)
			total_height = _recalculate_height()
			is_moving = false
			drag.end_drag()

		if bi_status == ItemComponent.PlacementState.CANNOT_PLACE:
			shake()

## Aktualisiert Position während Drag und triggert Placement-Analyse.[br]
## Berechnet Bewegung, setzt globale Position und aktualisiert Placement-Status.
func _on_drag_moved(newPos: Vector2) -> void:
	var target_pos: Vector2 = newPos - drag_offset
	var travel_distance: float = global_position.distance_to(target_pos)
	movement_distance 		+= 	travel_distance
	total_movement_distance += 	travel_distance
	global_position 		= 	target_pos
	itemParts_comp.can_be_placed()

## Ordnet Item einem Storage zu und hängt es in dessen Inventory ein.[br]
## Behält globale Position bei, um visuelle Sprünge zu vermeiden.
func _reparent_to_storage(storage: StorageComponent) -> void:
	if not storage: return

	var storageInventoryComponent: InventoryComponent = storage.myItem.inventory_Comp
	if not storageInventoryComponent: return

	var global_pos: Vector2 = global_position
	var old_parent: Node = get_parent()

	if old_parent:
		old_parent.remove_child(self)
	
	storageInventoryComponent.add_child(self)
	global_position = global_pos

## Stellt sicher, dass das Item im ItemRoot ganz oben gerendert wird.[br]
## Erhält globale Position trotz Reparenting. (= Man muss sich nicht um die Position kümmern)
func _bring_to_front() -> void:
	var old_position: Vector2 = global_position

	if get_parent() == item_root:		
		item_root.move_child(self, -1)
		global_position = old_position
		return
	
	var old_parent: Node = get_parent()
	if old_parent:
		old_parent.remove_child(self)

	item_root.add_child(self)
	item_root.move_child(self, -1)
	global_position = old_position

## Berechnet Gesamt-Höhe basierend auf Parent-Höhe
func _recalculate_height() -> float:
	## Ermittelt effektive Stapelhöhe basierend auf Parent BaseItem oder ItemRoot.
	var myParent_ItemOrRoot: Node2D = _get_parent_BaseItem_or_ItemRoot(self)

	if myParent_ItemOrRoot is BaseItem:
		return myParent_ItemOrRoot.total_height
	if myParent_ItemOrRoot is ItemRoot:
		return myParent_ItemOrRoot.height
	return 0.0

## Findet direkten relevanten Parent (BaseItem oder ItemRoot)
func _get_parent_BaseItem_or_ItemRoot(item: BaseItem) -> Node2D:
	## Traversiert Parent-Hierarchie bis BaseItem oder ItemRoot gefunden wird.
	var parentNode: Node2D = null
	var current: Node = item.get_parent()

	while current:
		if current is BaseItem: return current
		if current is ItemRoot: return current
		current = current.get_parent()
	return parentNode

## Sorgt dafür, dass alle Kind-Items konsistente Höhenwerte erhalten.
func _set_children_on_own_height() -> void:
	for child in get_children():
		if child is not BaseItem: continue	
		child.total_height = self.total_height

## Liefert die Area2D für Kollisions- und Interaktionsabfragen.
func get_interaction_area() -> Area2D:
	return ItemArea
	
## Startpunkt für komponentenbasiertes Initialisierungssystem.
func _init_components() -> void:
	_initialize_components_recursive(self)

## Rekursive Initialisierung aller BaseItemComponents im Baum[br]
## Durchläuft Node-Hierarchie und initialisiert alle Komponenten.
func _initialize_components_recursive(node: Node) -> void:
	for child in node.get_children():
		if child is BaseItemComponent:
			child.initialize(self)
		_initialize_components_recursive(child)

## Sucht eine spezifische Component im direkten Child-Level[br]
## Gibt erste passende Component des angegebenen Typs zurück.
func get_component(component_type: Variant) -> BaseItemComponent:
	for component in get_children():
		if is_instance_of(component, component_type):
			return component
	return null

## Lässt das Item kurz nach links und rechts wackeln.

func shake() -> void:
	shake_stop()
	
	_shake_tween = create_tween()
	_shake_tween.set_trans(Tween.TRANS_SINE)
	_shake_tween.set_ease(Tween.EASE_IN_OUT)
	
	_shake_tween.tween_property(Visual_comp, "position:x", Visual_comp.position.x - 16, 0.1)
	_shake_tween.tween_property(Visual_comp, "position:x", Visual_comp.position.x + 16, 0.2)
	_shake_tween.tween_property(Visual_comp, "position:x", Visual_comp.position.x, 0.1)

	_shake_tween.finished.connect(func() -> void:
		_shake_tween = null
	)
func shake_stop() -> void:
	if _shake_tween:
		_shake_tween.kill()
		_shake_tween = null
		Visual_comp.position = Vector2.ZERO
