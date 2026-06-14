class_name InventoryComponent
extends Node2D

signal item_added(item: BaseItem)
signal item_removed(item: BaseItem)

var myItem: BaseItem

func _ready() -> void:
	myItem = self.get_parent() as BaseItem

func add_item(item: BaseItem) -> void:
	if not item:
		return
	
	# Item aus altem Parent entfernen
	if item.get_parent():
		item.get_parent().remove_child(item)
	
	# Item direkt als Child der InventoryComponent hinzufügen
	add_child(item)
	item_added.emit(item)


func remove_item(item: BaseItem) -> void:
	if item and item.get_parent() == self:
		remove_child(item)
		item_removed.emit(item)


# Gibt alle aktuell gespeicherten Items zurück
func get_all_items() -> Array[BaseItem]:
	var items: Array[BaseItem] = []
	for child in get_children():
		if child is BaseItem:
			items.append(child)
	return items
