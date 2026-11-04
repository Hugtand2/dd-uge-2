extends Node2D

var george_sprite: Sprite2D

func _ready() -> void:
	var c := Customer.new("George")
	add_child(c)
	c.speak()
