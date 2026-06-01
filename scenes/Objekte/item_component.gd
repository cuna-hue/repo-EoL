extends Node2D

func _ready() -> void:
	# Alle Area2D-Kinder automatisch einrichten
	for area in get_children():
		if area is Area2D:
			area.area_entered.connect(_on_overlap.bind(area))

func _on_overlap(other: Area2D, self_area: Area2D) -> void:
	print("%s überlappt mit %s" % [self_area.name, other.name])
