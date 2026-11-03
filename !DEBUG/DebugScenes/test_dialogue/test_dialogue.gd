extends Node2D

var george_sprite: Sprite2D

func _ready() -> void:
	var customer = Customer.new("George", "res://Resources/UIAssets/Alien.png")
	add_child(customer)
	customer.lines.append_array(["This is a test", "Next line"])
	customer.speak()
