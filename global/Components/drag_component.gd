extends Area2D

@export var target: Node2D

var dragging := false
var grab_offset := Vector2.ZERO

func _ready():
	input_pickable = true
	if not target:
		target = get_parent()
	
func _process(_delta):
	if dragging:
		target.global_position = get_global_mouse_position() + grab_offset
	
func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			dragging = true
			grab_offset = target.global_position - get_global_mouse_position()
		else:
			dragging = false
			call_deferred("_try_snap")
			
func can_be_stored():
	return true
	
func _try_snap():
	for a in get_overlapping_areas():
		print("new area", a.name)
		if a.has_method("snap_if_possible"):
			print("new area has snap_if_possible", a.name)
			if a.snap_if_possible():
				return
