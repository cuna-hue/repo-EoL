class_name ItemPartsComponent
extends Node2D

var item_components: Array[ItemComponent] = []

var item_PlacementStatus: ItemComponent.PlacementState = ItemComponent.PlacementState.PLACED

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
func can_be_placed() -> bool:
	var all_itemComponents_placeable: bool = true
	var highest_item_height: float		= -INF
	var highest_storage_height: float	= -INF
	var highest_StorageComponent: StorageComponent = null
#	var highest_ItemComponent: ItemComponent = null
	var direction_vector: Vector2 = Vector2.ZERO
	var distance_to_closestStorage: float = INF
	
	#1 suche höchste StorageComponent
	for current_IC:ItemComponent in item_components:
		# ItemComponents mitführen um später abzugleichen ob wirklich auf der höchsten Ebene
		var currentIC_placeableStorage: StorageComponent = current_IC.find_placeable_storage()	# sucht nicht nur die placeable_storage, sondern setzt auch hovering_item und / _storage
		if current_IC.hovering_item:
			if current_IC.hovering_item.myItem.total_height > highest_item_height:
				highest_item_height = current_IC.hovering_item.myItem.total_height
#				highest_ItemComponent = current_IC.hovering_item
		# höchste StorageComponent suchen
		if not currentIC_placeableStorage: continue
		var currentIC_pS_totalHeight: float = currentIC_placeableStorage.myItem.total_height
		if currentIC_pS_totalHeight > highest_storage_height:
			highest_storage_height = currentIC_pS_totalHeight
			highest_StorageComponent = currentIC_placeableStorage
			direction_vector = currentIC_placeableStorage.global_position - current_IC.global_position
			distance_to_closestStorage = current_IC.global_position.distance_to(currentIC_placeableStorage.global_position)
		elif currentIC_pS_totalHeight == highest_storage_height:
			var tmp_distance: float = current_IC.global_position.distance_to(currentIC_placeableStorage.global_position)
			if tmp_distance < distance_to_closestStorage:
				highest_StorageComponent = currentIC_placeableStorage
				direction_vector = currentIC_placeableStorage.global_position - current_IC.global_position
				distance_to_closestStorage = tmp_distance


	item_PlacementStatus = ItemComponent.PlacementState.UNKNOWN
	if highest_item_height > highest_storage_height:
		# Eine ItemComponent hat ein höheres Item gefunden, als eine StorageComponent
		all_itemComponents_placeable = false
	
	for current_IC:ItemComponent in item_components:
		# erneut durchlaufen und alle ItemComponents prüfen ob sie 1. eine placeable_storage haben, 2. es dieselbe ist und 3. kein Item höher liegt
		if not highest_StorageComponent:
			# Item ist frei platzierbar
			current_IC.status = ItemComponent.PlacementState.CAN_PLACE_FREE
			continue

		# prüft ob Storage vorhanden (= kein Item dazwischen)
		if not current_IC.placeable_storage:
			current_IC.status = ItemComponent.PlacementState.CANNOT_PLACE
			all_itemComponents_placeable = false
			continue

		# prüft ob Storage zum besten Storage gehört
		if current_IC.placeable_storage.myItem != highest_StorageComponent.myItem:
			current_IC.status = ItemComponent.PlacementState.CANNOT_PLACE
			all_itemComponents_placeable = false
			continue

		# prüft ob Storage in die richtige Richtung snappt
		if (current_IC.placeable_storage.global_position - current_IC.global_position) != direction_vector:
			current_IC.status = ItemComponent.PlacementState.CANNOT_PLACE
			all_itemComponents_placeable = false
			continue
			
		current_IC.status = ItemComponent.PlacementState.CAN_SNAP
		
	return all_itemComponents_placeable
