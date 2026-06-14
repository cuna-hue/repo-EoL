class_name ItemComponent
extends Area2D

# Referenz zum übergeordneten Item (BaseItem)
var parent: BaseItem

# Wird später gesetzt, wenn das Item in einem Storage liegt
var current_storage: StorageComponent = null

func _ready() -> void:
	parent = get_parent() as BaseItem
	if not parent:
		push_warning("ItemComponent muss Child eines BaseItem sein")
