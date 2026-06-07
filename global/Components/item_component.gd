# ItemComponent.gd
class_name ItemComponent
extends Area2D

@export var sprite: Sprite2D      # oder TextureRect etc. für Färbung

var current_storage: StorageComponent = null

signal compatible_storage_detected(storage: StorageComponent)
signal no_compatible_storage_detected()

func _ready():
	monitoring = true

func _on_area_entered(other_area: Area2D):
	var storage = other_area.get_parent().get_node_or_null("StorageComponent")
	if storage and storage.can_accept_item(get_parent()):
		current_storage = storage
		_set_highlight(true)           # Grün
		compatible_storage_detected.emit(storage)

func _on_area_exited(other_area: Area2D):
	var storage = other_area.get_parent().get_node_or_null("StorageComponent")
	if storage == current_storage:
		current_storage = null
		_set_highlight(false)          # Rot oder Neutral
		no_compatible_storage_detected.emit()

func _set_highlight(compatible: bool):
	if sprite:
		sprite.modulate = Color.GREEN if compatible else Color.RED
	# Oder: Border anzeigen etc.
