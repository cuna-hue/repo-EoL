extends Node2D

var dragging := false
var grab_offset := Vector2.ZERO

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			# prüfen ob Maus auf Objekt ist
			if $Sprite2D.get_rect().has_point($Sprite2D.to_local(get_global_mouse_position())):
				dragging = true
				grab_offset = global_position - get_global_mouse_position()
		else:
			dragging = false

	elif event is InputEventMouseMotion and dragging:
		global_position = get_global_mouse_position() + grab_offset
