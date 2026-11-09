extends Node2D

var current_customer: Customer
var is_serving := false
var cash: float

func _ready() -> void:
	pass

func customer_arrive() -> void:
	if current_customer:
		return
	is_serving = true
	var customer = Customer.new("George")
	add_child(customer)
	############################################################################
	# Insert animation
	customer.position = Vector2i(get_viewport_rect().size/2)
	############################################################################
	# On anim.finished():
	customer.want_to_speak()
	return
