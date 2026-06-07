class_name ItemBase
extends Node2D

var item_in_hand : bool= false
var item_offset

func _ready():
	return
	for drag in get_children():
		if drag is DragComponent:
			drag.toggle_drag.connect(_on_toggle_drag)

func _process(_delta):
	if item_in_hand:
		global_position = get_global_mouse_position() + item_offset

func set_held(value: bool) -> void:
	item_in_hand = value

func _on_toggle_drag(signal_item_offset) -> void:
	item_offset = signal_item_offset
	set_held(!item_in_hand)
