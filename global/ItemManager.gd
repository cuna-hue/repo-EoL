# Autoload:
# Project Settings -> Autoload -> ItemManager.gd
extends Node

var all_items : Dictionary = {}
var next_uid : int = 1

func register_item(item: Item) -> int:
	if item.uid > 0: return item.uid
		
	var uid = next_uid
	next_uid += 1
	if next_uid == TYPE_MAX:
		push_error("ItemManager: UID overflow")
	
	item.uid = uid
	all_items[uid] = item
	
	return uid


func unregister_item(item) -> void:
	if all_items.has(item.uid):
		all_items.erase(item.uid)


func get_item(uid : int):
	return all_items.get(uid, null)
