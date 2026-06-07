# DragComponent.gd
class_name DragComponent
extends Area2D

var is_dragging: bool 		= false
var drag_offset: Vector2 	= Vector2.ZERO
var originalparent: Node	#parent vom Item (zum Sortieren - Achtung: da Item in anderes Item gestopft werden kann bitte jedes mal neu ermitteln)
var drag_distance: float	= 0.0
var parent: ItemBase

signal drag_started(item: ItemBase)
signal drag_stopped(item: ItemBase)
#signal drag_moved(global_pos: Vector2) 			#--- später für Kraftaufwendung notwendig
#signal drag_direction_changed(direction: Vector2) 	#--- später für auslaufende Gegenstände notwendig

func _ready() -> void:
	parent = get_parent()

func _input(event: InputEvent) -> void:
	if not is_dragging:
		return
	
	if event is InputEventMouseMotion:
		var new_position: Vector2 = get_global_mouse_position() - drag_offset
		drag_distance += parent.global_position.distance_to(new_position)
		print("Mausbewegung: ", drag_distance)
		parent.global_position = new_position
	
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if not event.pressed:           # RMB losgelassen
			stop_drag()

# Nur zum Starten des Drags bleibt _input_event()
func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		start_drag()

func start_drag() -> void:
	if is_dragging: return
	if not is_topmost_item(): return

	is_dragging = true

	drag_offset = get_global_mouse_position() - parent.global_position
	originalparent = parent.get_parent()
	
	# Bring to front
	if originalparent:
		originalparent.move_child(parent, -1)
	
	drag_started.emit(self)

func stop_drag() -> void:
	if not is_dragging: return
	is_dragging = false
	drag_distance = 0.0

	drag_stopped.emit(self)

func is_topmost_item() -> bool:
	var my_container = parent.get_parent()
	if not my_container:
		return true
	
	var my_index = parent.get_index()
	
	var results = _get_areas_under_mouse()
	if results.is_empty():
		return false
	
	# Prüfe jedes gefundene Area
	for result in results:
		var other_drag = result.collider as DragComponent
		
		if not other_drag:
			continue
		if other_drag == self:
			continue
		
		if not _is_in_same_container(other_drag, my_container):
			continue
		
		if _is_above_me(other_drag, my_index):
			return false  # es gibt ein höheres Item
	
	return true

# Hilfsfunktionen für bessere Lesbarkeit
func _get_areas_under_mouse() -> Array:
	var mouse_pos = get_global_mouse_position()
	var space = get_world_2d().direct_space_state
	
	var params = PhysicsPointQueryParameters2D.new()
	params.position = mouse_pos
	params.collide_with_areas = true
	params.collide_with_bodies = false
	
	return space.intersect_point(params)


func _is_in_same_container(other_drag: DragComponent, my_container: Node) -> bool:
	if other_drag.parent == null:
		return false
	return other_drag.parent.get_parent() == my_container


func _is_above_me(other_drag: DragComponent, my_index: int) -> bool:
	return other_drag.parent.get_index() > my_index
