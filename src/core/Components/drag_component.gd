class_name DragComponent
extends Area2D

## ===============================================================
## DragComponent - Zieht BaseItems per Rechtsklick
## Nutzt total_height für Topmost- und Snap-Entscheidungen
## ===============================================================

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var drag_distance: float = 0.0

var myItem: BaseItem = null

## Sendet ein Signal, wenn ein Drag initiiert wurde[br][br]Achtung: Die DragComponent handelt unabhängig vom Item und verwaltet ihren is_dragging Status selbst - also zumindest den Start
signal drag_started(drag: DragComponent)

## Sendet ein Signal, wenn abgelegt werden soll[br][br]ACHTUNG: Das ist nur ein Vorschlag! Es muss bestätigt werden durch das BaseItem, da sonst nicht end_drag() aufgerufen und das Objekt weiter bewegt wird.
signal drag_stopped(drag: DragComponent)

## Sendet ein Signal bei jeder Bewegung des Objektes.[br][br]Die neue Position wird übergeben. [br][br](Aktuell noch keine Verwendung)
signal drag_moved(newPos: Vector2)

var item_root: Node2D = null


func _ready() -> void:
	# IDEE: Eventuell lassen wir die Verknüpfungen zu Parents von den Parents einrichten.
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


## Rechtsklick startet Drag
func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_try_start_drag()

func _input(event: InputEvent) -> void:
	if not is_dragging: return # Inputs nur überwachen, wenn Item gedraggt wird. 

	if event is InputEventMouseMotion:
		var target_pos: Vector2 = get_global_mouse_position() - drag_offset
		drag_distance += myItem.global_position.distance_to(target_pos)
		myItem.global_position = target_pos
		drag_moved.emit(target_pos)			# DragComponent meldet neue Position

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
		stop_drag()

## ===============================================================
## Drag starten
## ===============================================================
func _try_start_drag() -> void:
	if _is_topmost_under_mouse():
		call_deferred("_start_drag")	#----.
										#    |
func _start_drag() -> void:				# <--'
	if is_dragging: return
	is_dragging = true
	drag_distance = 0.0

	# Startposition des Items und Mausposition speichern um DragDistanz zu berechnen
	var mouse_pos: Vector2 = get_global_mouse_position()
	var old_global_pos: Vector2 = myItem.global_position
	
	drag_offset = mouse_pos - old_global_pos	# Korrekter Abstand zum Zentrum des Items berechnen
	_bring_to_front()							# Item wird in den ItemRoot an unterste (= vorderste) Stelle gesetzt

	myItem.global_position = old_global_pos		# Durch Repositionierung (_bring_to_front) ändert sich WeltPosition -> hier zurückgesetzt
	drag_offset = mouse_pos - myItem.global_position # Entsprechend muss auch der Offset neu berechnet werden

	drag_started.emit(self)


## ===============================================================
## Drag beenden + Snapping
## ===============================================================
func stop_drag() -> void:
	if not is_dragging:
		return

	var best_storage: StorageComponent = _find_best_storage_for_snapping()
	
	if best_storage and _can_drop_on_storage(best_storage):
		_snap_to_storage(best_storage)
		_reparent_to_storage(best_storage)
		drag_stopped.emit(self)

	elif best_storage:
		# Optional: kleines visuelles Feedback, dass Drop nicht möglich war
		return
	else:
		drag_stopped.emit(self)

func end_drag() -> void:
	is_dragging = false
	drag_distance = 0.0


func _find_best_storage_for_snapping() -> StorageComponent:
	
	var best_storage: StorageComponent = null
	var best_height: float = -INF
	var best_dist: float = INF
#	var target_height: float = -INF
#	var final_target_height_found: bool = false
	
	var mouse_pos: Vector2 = get_global_mouse_position()
	var closest_comp: ItemComponent = _get_closest_item_component_to(mouse_pos)
	
	print("--- DEBUG FIND BEST STORAGE --- Mouse: ", mouse_pos)
	var comp_name: String = "null" 
	var comp_path: String = "not found"
	if closest_comp != null: 
		comp_name = closest_comp.name
		comp_path = closest_comp.get_path()
	print(" Closest Comp: ", comp_name, " Path: ", comp_path)

	if not closest_comp:
		print("→ Abbruch: Keine closest_comp gefunden")
		return null
	
	for storage: StorageComponent in _get_nearby_storages(closest_comp):
		if _is_own_storage_or_descendant(storage):
			print("  Ignoriere eigene: ", storage.myItem.name)
			continue
		
		var storage_h: float = storage.myItem.total_height
		var dist: float = closest_comp.global_position.distance_to(storage.global_position)
		
		print("  Kandidat: ", storage.myItem.name, " | Höhe=", storage_h, " | Dist=", dist)
		
		if storage_h > best_height or (storage_h == best_height and dist < best_dist):
			best_height = storage_h
			best_dist = dist
			best_storage = storage
			print("    → Neuer Bester: ", storage.myItem.name, " (Höhe ", best_height, ")")
	
	if best_storage:
		print("→ FINAL BEST STORAGE: ", best_storage.myItem.name, " (Höhe ", best_height, ")")
	else:
		print("→ KEINE Storage gefunden!")
	
	return best_storage
	
## NEU: Prüft, ob das gesamte Item konsistent auf dieses Ziel abgelegt werden kann
func _can_drop_on_storage(storage: StorageComponent) -> bool:
	if not storage:
		return false
	
	var target_item: BaseItem = storage.myItem
	var target_height: float = target_item.total_height
	
	print("--- DEBUG CAN_DROP --- Ziel: ", target_item.name, " (Höhe ", target_height, ")")
	
	for comp: ItemComponent in _get_all_item_components():
		var has_valid_storage: bool = false
		var has_higher_foreign: bool = false
		
		print("  [Comp] ", comp.name)
		
		for s: StorageComponent in _get_nearby_storages(comp):
			if _is_own_storage_or_descendant(s):
				continue
			
			var found_h: float = s.myItem.total_height
			print("     → Storage: ", s.myItem.name, " | Höhe = ", found_h)
			
			if s.myItem == target_item and found_h == target_height:
				has_valid_storage = true
				print("        ✓ Passende Storage auf Zielhöhe gefunden")
			
			# NEU: Höheres fremdes Item erkannt?
			if found_h > target_height and s.myItem != target_item:
				has_higher_foreign = true
				print("        ❌ Höheres fremdes Item erkannt! (", found_h, ")")
		
		if has_higher_foreign:
			print("    ❌ Blockiert wegen höherem fremden Item")
			return false
		
		if not has_valid_storage:
			print("    ❌ Keine passende Storage auf Zielhöhe")
			return false
	
	print("→ CAN_DROP: true → Alles ok")
	return true
	
## ===============================================================
## Hilfsfunktionen
## ===============================================================
func _is_topmost_under_mouse() -> bool:
	var results := _get_areas_under_mouse()
	#if results.is_empty(): return true # <<< wird nie passieren, denn die DragComponent selbst ist eine Area2D

	var best_drag: DragComponent = null
	var best_height: float = -INF
	var best_index: int = -1

	for r in results:
		var drag: DragComponent = r.collider as DragComponent
		# Aussortieren von Nicht-DragComponents und fehlerhaften DragComponents (alle müssen ein BaseItem besitzen)
		if not drag or not drag.myItem: continue 
		
		# WICHTIG: Wenn bereits ein anderes Item gedraggt wird → nicht aufnehmen
		if drag.is_dragging and drag != self:
			return false
		
		var h: float = drag.myItem.total_height
		var idx: int = drag.myItem.get_index()

		if h > best_height or (h == best_height and idx > best_index):
			best_height = h
			best_index = idx
			best_drag = drag

	return best_drag == self
	
	
func _is_own_storage_or_descendant(storage: StorageComponent) -> bool:
	if not storage or not storage.myItem:
		return false
	return storage.myItem == myItem or myItem.is_ancestor_of(storage.myItem)


func _bring_to_front() -> void:
	if myItem.get_parent() == item_root:
		item_root.move_child(myItem, -1)
		return
	
	var old_parent: Node = myItem.get_parent()
	if old_parent:
		old_parent.remove_child(myItem)
	item_root.add_child(myItem)
	item_root.move_child(myItem, -1)


func _reparent_to_storage(storage: StorageComponent) -> void:
	if not storage or not storage.myItem:
		return
	
	var target_parent: BaseItem = storage.myItem
	if target_parent == myItem or myItem.is_ancestor_of(target_parent):
		return
	
	var global_pos: Vector2 = myItem.global_position
	var old_parent: Node = myItem.get_parent()
	if old_parent:
		old_parent.remove_child(myItem)
	
	target_parent.add_child(myItem)
	myItem.global_position = global_pos


func _snap_to_storage(storage: StorageComponent) -> void:
	var best_comp := _get_closest_item_component_to(storage.global_position)
	if best_comp:
		var offset := storage.global_position - best_comp.global_position
		myItem.global_position += offset + storage.snap_offset
	else:
		myItem.global_position = storage.global_position + storage.snap_offset


## ===============================================================
## Einfache Hilfsfunktionen
## ===============================================================
func _get_areas_under_mouse() -> Array[Dictionary]:
	var params := PhysicsPointQueryParameters2D.new()
	params.position = get_global_mouse_position()
	params.collide_with_areas = true
	params.collide_with_bodies = false
	return get_world_2d().direct_space_state.intersect_point(params)


func _get_all_item_components() -> Array[ItemComponent]:
	var list: Array[ItemComponent] = []
	for child in myItem.get_children():
		if child is ItemComponent:
			list.append(child)
	return list

## Gibt ein Array mit StorageComponents zurück, die mit item_comp überlappen
func _get_nearby_storages(item_comp: ItemComponent) -> Array[StorageComponent]:
	var list: Array[StorageComponent] = []
	for area in item_comp.get_overlapping_areas():
		if area is StorageComponent:
			list.append(area)
	return list


func _get_closest_item_component_to(target_pos: Vector2) -> ItemComponent:
	var closest: ItemComponent = null
	var min_dist: float = INF
	for comp in _get_all_item_components():
		var dist := comp.global_position.distance_to(target_pos)
		if dist < min_dist:
			min_dist = dist
			closest = comp
	return closest
