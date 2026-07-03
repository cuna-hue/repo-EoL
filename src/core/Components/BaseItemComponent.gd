class_name BaseItemComponent
extends Node2D

# Referenz zum übergeordneten Item (BaseItem)
var myItem: BaseItem = null

## sucht rekursiv nach einem BaseItem.[br][br]Bricht ab beim ItemRoot oder wenn es keine Node gibt
func _find_parent(current_Parent: Node2D) -> BaseItem:
	if not current_Parent:
		push_warning("BaseItemComponent außerhalb von BaseItem und ItemRoot: %s" % get_path())
		return null
	current_Parent = current_Parent.get_parent()
	if current_Parent is BaseItem:
		return current_Parent
	if current_Parent is ItemRoot:
		push_warning("BaseItemComponent außerhalb von BaseItem (aber innerhalb ItemRoot): %s" % get_path())
		return null
	return _find_parent(current_Parent)

func _get_Area2D() -> Area2D:
	for child in get_children():
		if child is Area2D: 
			return child
	push_warning("BaseItemComponent: keine Area2D gefunden: %s" % get_path())
	return null

## Prüft ob Area2D ein Storage oder ItemComponent ist und ob es zum selben Item gehört.
func _is_self_or_my_child(node: BaseItemComponent) -> bool:
	# Jede StorageComponent und jede ItemComponent gehört IMMER zu einem BaseItem, sodass myItem immer definiert ist!
	# Falls dennoch ein nicht-BaseItemComponent verwendet wird, = FALSE
	if node is BaseItemComponent:
		if myItem == node.myItem: 				return true
		if myItem.is_ancestor_of(node.myItem): 	return true
	return false

## BaseItem initialisiert alle BaseItemComponents
func initialize(item: BaseItem) -> void:
	myItem = item
	if myItem == null:
		push_error("myItem konnte nicht gesetzt werden: ", name)	
	_on_initialized()

## Nachdem BaseItem initialisiert hat, können BaseItemComponents eigene Funktionen ausführen.
func _on_initialized() -> void:
	pass
