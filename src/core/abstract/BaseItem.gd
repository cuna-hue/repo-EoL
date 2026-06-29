class_name BaseItem
extends Node2D

## Höhe in cm
@export var height: float = 1.0

## Gewicht in g
@export var weight: float = 1000.0

var total_height: float = 0:
	get: return total_height
	set(value): 
		total_height = value + height
		set_children_on_own_height()
		print("%s-height: %.2f cm" % [name, total_height])

## Gibt an, ob das BaseItem sich bewegt.[br][br]Idee: Nicht nur durch Drag können Objekte Bewegt werden. Vielleicht auch andere Events. Das könnte aber zu ähnlichen Effekten wie beim Drag führen.
var is_moving: bool = false		

func _ready() -> void:
	# Signal vom DragComponent verbinden
	var drag_comp: DragComponent = get_node_or_null("DragComponent")  
	if drag_comp:
		drag_comp.drag_stopped.connect(_on_drag_stopped)
		drag_comp.drag_started.connect(_on_drag_started)
	var itemParts_comp: ItemPartsComponent = get_node_or_null("ItemPartsComponent") 
	if itemParts_comp:
		itemParts_comp.placement_updated.connect(_on_placement_update)


func welcome_child(new_BaseItem: BaseItem) -> void:
	new_BaseItem.total_height = self.total_height + new_BaseItem.height

## Hilfsfunktion - Wird verwendet in total_height zum automatischen Setzen der Höhe aller Children und diese wiederum aller ihrer Children
func set_children_on_own_height() -> void:
	for child in get_children():
		if child is not BaseItem: continue	
		child.total_height = self.total_height

func _on_drag_started() -> void:
	total_height = 0.0
	is_moving = true
	

## Wird aufgerufen, wenn dieses Item (oder ein Child) abgelegt wurde
func _on_drag_stopped() -> void:
	# 1. prüfen ob abgelegt werden kann --> Feedback an DragComponent
	
	#Hier sind wir gerade: DragComponent muss neu geschrieben werden. 
	#Bewegung muss getrackt werden (jedes mal ein Signal senden)
	#Ablegen muss angefragt werden
	#Funktion zum Platzieren des Items
	
	# 2. ablegen und neue Höhe berechnen
	total_height = _recalculate_height()
	is_moving = false
	
func _on_placement_update() -> void:
	# Bei Bewegung updaten ob abgelegt werden kann
	pass

## Gibt die totale Höhe des Items wieder.[br][br]Hierbei wird die Höhe des Parent genommen und die eigene Höhe (automatisch) hinzu addiert.
func _recalculate_height() -> float:
	var myParent_ItemOrRoot: Node2D =_get_parent_BaseItem_or_ItemRoot(self)
	if myParent_ItemOrRoot is BaseItem:
		return myParent_ItemOrRoot.total_height
	if myParent_ItemOrRoot is ItemRoot:
		return myParent_ItemOrRoot.height
	return 0.0

## Gibt Parent oder [color=#dc6375]null[/color] zurück. [br][br]Parent kann BaseItem oder ItemRoot sein.
func _get_parent_BaseItem_or_ItemRoot(item: BaseItem) -> Node2D:
	var parentNode: Node2D = null
	var current: Node = item.get_parent()
	while current:
		if current is BaseItem: return current
		if current is ItemRoot: return current
		current = current.get_parent()
	return parentNode
