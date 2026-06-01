extends Node

func _ready() -> void:
	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.filters = ["*.png"]
	add_child(dialog)
	dialog.popup_centered(Vector2i(800, 600))
	dialog.file_selected.connect(_on_file_selected)
	dialog.canceled.connect(get_tree().quit)

func _on_file_selected(path: String) -> void:
	var image := Image.load_from_file(path)
	image.resize(image.get_width() * 2, image.get_height() * 2)
	image.save_png(path.get_basename() + "_2x.png")
	get_tree().quit()
