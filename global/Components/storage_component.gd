class_name StorageComponent
extends Node2D   # oder Area2D, je nach Bedarf

@export var snap_grid_size: Vector2 = Vector2(32, 32)
@export var allow_rotation: bool = false

var stored_items: Array[ItemBase] = []

signal item_stored(item: ItemBase)
signal item_removed(item: ItemBase)


func _ready() -> void:
	# Optional: Area2D für Drop-Erkennung verbinden
	pass


# Wird von DragComponent aufgerufen, wenn ein Item losgelassen wird
func try_store_item(item: ItemBase, global_drop_pos: Vector2) -> bool:
	if not can_accept_item(item):
		return false
	
	# Ausrichten (Snapping)
	var local_pos = to_local(global_drop_pos)
	var snapped_pos = _snap_position(local_pos)
	
	item.global_position = to_global(snapped_pos)
	if allow_rotation:
		item.rotation = _snap_rotation(item.rotation)
	
	# Item in diesen Container übernehmen
	_add_item(item)
	return true


func _add_item(item: ItemBase) -> void:
	if item.get_parent():
		item.get_parent().remove_child(item)
	
	add_child(item)					# oder ein spezielles Items-Container-Node
	stored_items.append(item)
	
	# Optional: Item eine Referenz auf diesen Storage geben
	item.current_storage = self
	
	item_stored.emit(item)


func remove_item(item: ItemBase) -> void:
	stored_items.erase(item)
	item.current_storage = null
	item_removed.emit(item)


func can_accept_item(item: ItemBase) -> bool:
	# Hier später Gewicht, Typ-Filter, Platzprüfung etc.
	return true


# ==================== SNAPPING ====================
func _snap_position(local_pos: Vector2) -> Vector2:
	if snap_grid_size == Vector2.ZERO:
		return local_pos
	return Vector2(
		round(local_pos.x / snap_grid_size.x) * snap_grid_size.x,
		round(local_pos.y / snap_grid_size.y) * snap_grid_size.y
	)


func _snap_rotation(rot: float) -> float:
	# z.B. 90° Schritte
	return round(rot / (PI/2)) * (PI/2)
