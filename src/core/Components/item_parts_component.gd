class_name ItemPartsComponent
extends Node2D

var item_components: Array[ItemComponent] = []

var item_PlacementStatus: ItemComponent.PlacementState = ItemComponent.PlacementState.PLACED

var best_target: PlacementTarget = PlacementTarget.new()

class PlacementTarget:
	var storage: StorageComponent 		= null
	var direction: Vector2 				= Vector2.ZERO
	var highest_storage_height: float 	= -INF
	var highest_item_height: float 		= -INF
	var distance: float 				= INF

func _ready() -> void:
	item_components = _collect_item_components()

## Erzeugt ein Array (item_components) mit allen ItemComponents, die in ihm drin sind.[br][br]Nur 1. Ebene keine Enkel
func _collect_item_components() -> Array[ItemComponent]:
	item_components.clear()
	for child in get_children():
		if child is ItemComponent:
			item_components.append(child)
	return item_components

# Wird vom BaseItem während des Draggens aufgerufen
func can_be_placed() -> ItemComponent.PlacementState:
	best_target = find_best_storage()

	item_PlacementStatus = ItemComponent.PlacementState.CAN_SNAP

	for ic: ItemComponent in item_components:
		var ic_placeable: bool = update_item_component_status(ic, best_target)
		if not ic_placeable: item_PlacementStatus = ItemComponent.PlacementState.CANNOT_PLACE
		if item_PlacementStatus == ItemComponent.PlacementState.CANNOT_PLACE: continue
		if ic.status == item_PlacementStatus: continue
		if ic.status == ItemComponent.PlacementState.CAN_PLACE_FREE:
			item_PlacementStatus = ItemComponent.PlacementState.CAN_PLACE_FREE
		
	return item_PlacementStatus
		
func find_best_storage() -> PlacementTarget:
	var target: PlacementTarget = PlacementTarget.new()

	for ic: ItemComponent in item_components:
		var candidate := ic.get_placement_candidate()

		# globaler Vergleich: höchstes Item tracken
		target.highest_item_height = max(
			target.highest_item_height,
			candidate.highest_item_height
		)

		# nur gültige Storage-Kandidaten weiterverarbeiten
		if not candidate.placeable_storage:
			continue

		var height := candidate.highest_storage_height
		var distance := candidate.distance

		# bessere Höhe gewinnt
		if height > target.highest_storage_height:
			_apply_target(target, candidate)

		# gleiche Höhe → Distanz entscheidet
		elif height == target.highest_storage_height and distance < target.distance:
			_apply_target(target, candidate)

	return target
	
func _apply_target(target: PlacementTarget, candidate: ItemComponent.PlacementCandidate) -> void:
	target.storage = candidate.placeable_storage
	target.highest_storage_height = candidate.highest_storage_height
	target.distance = candidate.distance
	target.direction = candidate.direction
	

func update_item_component_status(ic: ItemComponent, target: PlacementTarget) -> bool:
	
	if not ic.candidate.placeable_storage and target.highest_item_height > 0:
		ic.status = ItemComponent.PlacementState.CANNOT_PLACE
		return false
	
	# freies Platzieren
	if not target.storage:
		ic.status = ItemComponent.PlacementState.CAN_PLACE_FREE
		return true

	# kein gültiger Storage für dieses ItemComponent
	if not ic.candidate.placeable_storage:
		ic.status = ItemComponent.PlacementState.CANNOT_PLACE
		return false

	# falscher Storage
	if ic.candidate.placeable_storage.myItem != target.storage.myItem:
		ic.status = ItemComponent.PlacementState.CANNOT_PLACE
		return false

	# Richtung prüfen (robust statt exakter Vector equality)
	if ic.candidate.direction.normalized().distance_to(target.direction.normalized()) > 0.01:
		ic.status = ItemComponent.PlacementState.CANNOT_PLACE
		return false

	ic.status = ItemComponent.PlacementState.CAN_SNAP
	return true
