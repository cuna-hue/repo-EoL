class_name Item
extends Node2D

var uid: int = -1
@export var display_name: String = "nicht benannt"
@export var weight_in_mg: int = 1000

func _ready():
	ItemManager.register_item(self)


func _exit_tree():
	ItemManager.unregister_item(self)


func get_save_data() -> Dictionary:
	return {
		"scene_path": scene_file_path,
		"position": global_position
	}
func load_from_save(data : Dictionary) -> void:
	global_position = data["position"]
