class_name DragComponent
extends Area2D

## ===============================================================
## DragComponent
## Zieht BaseItems per Rechtsklick, handhabt Reparenting sauber
## und verhindert Mehrfach-Drags oder verschwundene Items.
## ===============================================================

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var drag_distance: float = 0.0

var myItem: BaseItem = null

signal drag_started(item: BaseItem)
signal drag_stopped(item: BaseItem)

var item_root: Node2D = null


func _ready() -> void:
	await get_tree().process_frame
	
	myItem = get_parent() as BaseItem
	if not myItem:
		push_error("DragComponent muss ein direktes Child von BaseItem sein!")
		queue_free()
		return
	
	item_root = GameManager.item_root
	if not item_root:
		push_error("GameManager.item_root nicht gefunden!")
		return


## Rechtsklick auf das Item startet Drag
func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_try_start_drag()


func _input(event: InputEvent) -> void:
	if not is_dragging:
		return

	if event is InputEventMouseMotion:
		var target_pos: Vector2 = get_global_mouse_position() - drag_offset
		drag_distance += myItem.global_position.distance_to(target_pos)
		myItem.global_position = target_pos

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
		stop_drag()


## ===============================================================
## Drag starten
## ===============================================================
func _try_start_drag() -> void:
	if _is_topmost_under_mouse():
		call_deferred("_start_drag")	
	return
	
func _start_drag() -> void:
	if is_dragging:
		return
	
	is_dragging = true
	drag_distance = 0.0

	var mouse_pos: Vector2 = get_global_mouse_position()
	var old_global_pos: Vector2 = myItem.global_position
	
	drag_offset = mouse_pos - old_global_pos

	_bring_to_front()

	myItem.global_position = old_global_pos
	drag_offset = mouse_pos - myItem.global_position

	drag_started.emit(myItem)


## ===============================================================
## Drag beenden + Snapping
## ===============================================================
func stop_drag() -> void:
	if not is_dragging:
		return

	var best_storage: StorageComponent = _find_best_storage_for_snapping()

	if best_storage:
		_snap_to_storage(best_storage)
		_reparent_to_storage(best_storage)

	is_dragging = false
	drag_distance = 0.0
	drag_stopped.emit(myItem)


## ===============================================================
## Reparenting mit Positions-Erhaltung
## ===============================================================
func _bring_to_front() -> void:
	if myItem.get_parent() == item_root:
		item_root.move_child(myItem, -1)
		return

	var old_parent: Node2D = myItem.get_parent()
	if old_parent:
		old_parent.remove_child(myItem)

	item_root.add_child(myItem)
	item_root.move_child(myItem, -1)


func _reparent_to_storage(storage: StorageComponent) -> void:
	if not storage or not storage.myItem:
		return
	
	var target_parent: BaseItem = storage.myItem
	if not target_parent:
		return
	
	# === ZYKLUS-SCHUTZ ===
	if target_parent == myItem or myItem.is_ancestor_of(target_parent):
		push_warning("Zyklus verhindert: Kann " + myItem.name + " nicht unter " + target_parent.name + " hängen")
		return
	
	# Schon am richtigen Ort?
	if myItem.get_parent() == target_parent:
		return
	
	# Sicheres Reparenting
	var global_pos: Vector2 = myItem.global_position
	
	var old_parent: Node2D = myItem.get_parent()
	if old_parent:
		old_parent.remove_child(myItem)
	
	target_parent.add_child(myItem)
	myItem.global_position = global_pos


## ===============================================================
## Snapping
## ===============================================================
func _find_best_storage_for_snapping() -> StorageComponent:
	var best: StorageComponent = null
	var best_priority: int = -1
	var best_dist: float = INF

	for comp: ItemComponent in _get_all_item_components():
		for storage: StorageComponent in _get_nearby_storages(comp):
			
			# === WICHTIG: Eigene Storages (auch verschachtelte) komplett ignorieren ===
			if _is_own_storage_or_child(storage):
				continue

			var priority := _get_storage_priority(storage)
			var dist := comp.global_position.distance_to(storage.global_position)

			if priority > best_priority or (priority == best_priority and dist < best_dist):
				best_priority = priority
				best_dist = dist
				best = storage

	return best

## Prüft, ob die Storage zum eigenen Item oder einem seiner Nachfahren gehört
func _is_own_storage_or_child(storage: StorageComponent) -> bool:
	if not storage or not storage.myItem:
		return false
	
	# Direkte eigene Storage
	if storage.myItem == myItem:
		return true
	
	# Storage gehört zu einem Child-Item von mir
	return myItem.is_ancestor_of(storage.myItem)
	
func _snap_to_storage(storage: StorageComponent) -> void:
	var best_comp: ItemComponent = _get_closest_item_component_to(storage.global_position)
	
	if best_comp:
		var offset: Vector2 = storage.global_position - best_comp.global_position
		myItem.global_position += offset + storage.snap_offset
	else:
		myItem.global_position = storage.global_position + storage.snap_offset


## ===============================================================
## Topmost-Erkennung (robust gegen Überlappungen)
## ===============================================================
func _is_topmost_under_mouse() -> bool:
	var results: Array[Dictionary] = _get_areas_under_mouse()
	if results.is_empty():
		return true

	var best_drag: DragComponent = null
	var best_score: float = -INF

	for result: Dictionary in results:
		var drag: DragComponent = result.collider as DragComponent
		if not drag or not drag.myItem:
			continue
		
		var score: float = _calculate_topmost_score(drag)
		if score > best_score:
			best_score = score
			best_drag = drag

	return best_drag == self


func _calculate_topmost_score(drag: DragComponent) -> float:
	if not drag or not drag.myItem:
		return -INF

	var score := 0.0
	
	# 1. Rendering-Reihenfolge (stärkster Faktor)
	score += drag.myItem.get_index() * 10000.0
	
	# 2. Tiefe im Szenenbaum (verschachtelte Items sollen greifbar sein)
	score += _get_tree_depth(drag.myItem) * 1000.0
	
	# 3. Y-Position als sanfter Fallback
	score += drag.myItem.global_position.y * 0.5
	
	return score


func _get_tree_depth(node: Node) -> int:
	var depth := 0
	var current := node
	while current and current != item_root and current.get_parent():
		depth += 1
		current = current.get_parent()
	return depth


## ===============================================================
## Hilfsfunktionen
## ===============================================================
func _get_areas_under_mouse() -> Array[Dictionary]:
	var params := PhysicsPointQueryParameters2D.new()
	params.position = get_global_mouse_position()
	params.collide_with_areas = true
	params.collide_with_bodies = false
	return get_world_2d().direct_space_state.intersect_point(params)


func _get_all_item_components() -> Array[ItemComponent]:
	var list: Array[ItemComponent] = []
	for child: Node in myItem.get_children():
		if child is ItemComponent:
			list.append(child)
	return list


func _get_nearby_storages(item_comp: ItemComponent) -> Array[StorageComponent]:
	var list: Array[StorageComponent] = []
	for area: Area2D in item_comp.get_overlapping_areas():
		if area is StorageComponent:
			list.append(area)
	return list


func _get_storage_priority(storage: StorageComponent) -> int:
	return storage.myItem.get_index() if storage.myItem else 0


func _get_closest_item_component_to(target_pos: Vector2) -> ItemComponent:
	var closest: ItemComponent = null
	var min_dist: float = INF
	
	for comp: ItemComponent in _get_all_item_components():
		var dist: float = comp.global_position.distance_to(target_pos)
		if dist < min_dist:
			min_dist = dist
			closest = comp
	return closest
