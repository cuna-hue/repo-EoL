extends Area2D

var occupied := false
var current_item = null

func _on_area_entered(area):
	print("new area", area.name)
	if area.has_method("can_be_stored"):
		current_item = area

func _on_area_exited(area):
	if area == current_item:
		current_item = null
		
func snap_if_possible():
	print("trying to snapp")
	if current_item == null:
		return false

	if occupied:
		return false

	current_item.global_position = global_position
	occupied = true
	return true
