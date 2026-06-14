class_name StorageComponent
extends Area2D

@export var snap_offset: Vector2 = Vector2.ZERO
var myItem: BaseItem

func _ready() -> void:
	myItem = get_parent() as BaseItem						#StorageComponent liegt direkt im BaseItem
	if myItem:
		push_warning(self.name, " < StorageComponent außerhalb von InventoryComponent. Item kann nicht aufgenommen werden.")
	else:											#StorageComponent liegt im InventoryContainer im BaseItem
		myItem = self.get_parent().get_parent() as BaseItem
