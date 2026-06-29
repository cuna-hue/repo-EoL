class_name ItemPartsComponent
extends Node2D

var item_components: Array[ItemComponent] = []

signal placement_updated(placement_status: ItemComponent.PlacementState)

func _ready() -> void:
	item_components = _collect_item_components()

## Erzeugt ein Array (item_components) mit ItemComponents, die in ihm drin sind.[br][br]Nur 1. Ebene keine Enkel
func _collect_item_components() -> Array[ItemComponent]:
	item_components.clear()
	for child in get_children():
		if child is ItemComponent:
			item_components.append(child)
	return item_components

# Wird vom BaseItem während des Draggens aufgerufen
func update_drag_feedback() -> void:
	var baseItem_placement_status: ItemComponent.PlacementState = ItemComponent.PlacementState.CAN_SNAP
	
	for current_IC in item_components:
		# Jede ItemComponent wird nach ihrem Status gefragt. Ihr Status sorgt für Einfärbung / Effekt auf ItemComponent
		var local_state:ItemComponent.PlacementState = current_IC.update_placement_status()
		
		# Wenn 1 Component gefunden wurde, die nicht platzierbar ist, interessieren die Status der anderen ICs nicht mehr
		if local_state == ItemComponent.PlacementState.CANNOT_PLACE:
			baseItem_placement_status = local_state
		if baseItem_placement_status == ItemComponent.PlacementState.CANNOT_PLACE: continue
		
		# Wenn 1 Component gefunden wurde, die nicht gesnappt werden kann, dann interessieren die anderen Snap-able nicht mehr (hier zwar unnötig, weil ohnehin ein Neusetzen des Snaps nicht vorgesehen, doch präventiv)
		if local_state == ItemComponent.PlacementState.CAN_PLACE_FREE:
			baseItem_placement_status = local_state
		if baseItem_placement_status == ItemComponent.PlacementState.CAN_PLACE_FREE: continue
		
	
	placement_updated.emit(baseItem_placement_status)
