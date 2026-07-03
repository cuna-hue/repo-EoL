# ItemRoot.gd
class_name ItemRoot
extends Node2D

## Höhe in cm [br][br]
## Da dies die unterste Ebene ist, reicht hier eine Höhe von 0.0cm (= Boden)
@export var height: float = 1.0

func _ready() -> void:
	GameManager.item_root = self
	for child in get_children():
		if child is BaseItem:
			child.total_height = self.height
