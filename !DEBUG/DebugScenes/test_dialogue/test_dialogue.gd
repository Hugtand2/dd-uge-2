extends Node2D

var george_sprite: Sprite2D

func _ready() -> void:
	var customer = Customer.new("George")
	add_child(customer)
	customer.lines.append_array(customer.data.string_data)
	customer.speak()
