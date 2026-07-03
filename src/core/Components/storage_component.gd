class_name StorageComponent
extends BaseItemComponent

@export var snap_offset: Vector2 = Vector2.ZERO

## Wird später erweitert (z.B. Kapazität, Item-Typ, etc.)
func is_accepting_itemComponent(item_comp: ItemComponent) -> bool:
	if not item_comp or not item_comp.myItem:
		return false
	
	if _has_already_Item():
		return false
	
	if _is_own_item(item_comp):
		return false
	
	# Vorläufig immer akzeptieren (außer eigene Items)
	return true

## Prüft ob ein ItemContainer darüber liegt
func _has_already_Item() -> bool:
	#var all_itemComponents: Array = get_parent().get_children()
	return false

## Funktion gibt wieder ob es sich um [color=green]self[/color] oder eines seiner [color=green]children[/color] handelt.
func _is_own_item(item_comp: ItemComponent) -> bool:
	return item_comp.myItem == myItem or myItem.is_ancestor_of(item_comp.myItem)
