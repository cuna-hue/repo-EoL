class_name DragComponent
extends BaseItemComponent

## ===============================================================
## DragComponent - Zieht BaseItems per Rechtsklick
## Nutzt total_height für Topmost- und Snap-Entscheidungen
## ===============================================================

var drag_offset: Vector2 = Vector2.ZERO

var DragArea: Area2D = null

## Sendet ein Signal, wenn ein Drag initiiert wurde[br][br]Achtung: Die DragComponent handelt unabhängig vom Item und verwaltet ihren is_dragging Status selbst - also zumindest den Start
signal drag_started(drag: DragComponent)
## Sendet ein Signal, wenn abgelegt werden soll[br][br]ACHTUNG: Das ist nur ein Vorschlag! Es muss bestätigt werden durch das BaseItem, da sonst nicht end_drag() aufgerufen und das Objekt weiter bewegt wird.
signal drag_stopped(drag: DragComponent)
## Sendet ein Signal bei jeder Bewegung des Objektes.[br][br]Die neue Position wird übergeben. [br][br](Aktuell noch keine Verwendung)
signal drag_moved(newPos: Vector2)

func _on_initialized() -> void:
	super._on_initialized()
	
	DragArea = myItem.ItemArea
	DragArea.input_event.connect(_on_area_input_event)
	DragArea.set_meta("drag", self)
	
## Rechtsklick startet Drag
func _on_area_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_try_start_drag()

func _input(event: InputEvent) -> void:
	#print("DragComponent _input:", event)
	if not myItem: return
	if not myItem.is_dragging: return # Inputs nur überwachen, wenn Item gedraggt wird. 

	if event is InputEventMouseMotion:
		var mouse_pos: Vector2 = get_global_mouse_position()
		drag_moved.emit(mouse_pos)			# DragComponent meldet neue Position

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
	if myItem.is_dragging: return
	myItem.is_dragging = true

	# Startposition des Items und Mausposition speichern um DragDistanz zu berechnen
	var mouse_pos: Vector2 = get_global_mouse_position()
	drag_started.emit(mouse_pos)

## ===============================================================
## [br]Drag beenden + Snapping
## [br] 
## [br]Fragt das BasisItem, ob Drag beendet werden darf
## [br] 
## [br]===============================================================
func stop_drag() -> void:
	if not myItem.is_dragging: return
	drag_stopped.emit(self)
	
## Beendet den Drag (Rückmeldung vom BasisItem)
func end_drag() -> void:
	myItem.is_dragging = false
	
## ===============================================================
## Hilfsfunktionen
## ===============================================================
func _is_topmost_under_mouse() -> bool:
	var results := _get_areas_under_mouse()
	#if results.is_empty(): return true # <<< wird nie passieren, denn die DragComponent selbst ist eine Area2D

	var best_baseItem: BaseItem = null
	var best_height: float = -INF
	var best_index: int = -1

	for r in results:
		if not r.collider is BaseItemArea: continue
		var area_baseItem: BaseItem = r.collider.myItem as BaseItem
		if not area_baseItem: continue 
		
		# WICHTIG: Wenn bereits ein anderes Item gedraggt wird → nicht aufnehmen
		if area_baseItem.is_dragging and area_baseItem != self.myItem:
			return false
		
		var h: float = area_baseItem.total_height
		var idx: int = area_baseItem.get_index()

		if h > best_height or (h == best_height and idx > best_index):
			best_height = h
			best_index = idx
			best_baseItem = area_baseItem

	return best_baseItem == self.myItem
	
	
func _is_own_storage_or_descendant(storage: StorageComponent) -> bool:
	if not storage or not storage.myItem:
		return false
	return storage.myItem == myItem or myItem.is_ancestor_of(storage.myItem)


## ===============================================================
## Einfache Hilfsfunktionen
## ===============================================================
func _get_areas_under_mouse() -> Array[Dictionary]:
	var params := PhysicsPointQueryParameters2D.new()
	params.position = get_global_mouse_position()
	params.collide_with_areas = true
	params.collide_with_bodies = false
	return get_world_2d().direct_space_state.intersect_point(params)
