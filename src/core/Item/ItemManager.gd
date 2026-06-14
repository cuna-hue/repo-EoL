# Autoload:
# Project Settings -> Autoload -> ItemManager.gd
extends Node

var all_items : Dictionary = {}
var next_uid : int = 1

func register_item(item: Item) -> int:
	if item.uid > 0: return item.uid
		
	var uid: int = next_uid
	next_uid += 1
	if next_uid == TYPE_MAX:
		push_error("ItemManager: UID overflow")
	
	item.uid = uid
	all_items[uid] = item
	
	return uid


func unregister_item(item: Item) -> void:
	if all_items.has(item.uid):
		all_items.erase(item.uid)


func get_item(uid : int) -> Item:
	return all_items.get(uid, null)
