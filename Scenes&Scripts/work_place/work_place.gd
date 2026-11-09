extends Node2D

@onready var desk := $Desk

var current_customer: Customer
var is_serving := false
var cash: float

func _ready() -> void:
	pass

func customer_arrive() -> void:
	if current_customer:
		return
	is_serving = true
	var customer = Customer.new(Customer.get_random_customer_name())
	add_child(customer)
	############################################################################
	# Insert animation
	customer.position = Vector2i(get_viewport_rect().size/2)
	############################################################################
	# On anim.finished():
	customer.finished_speaking.connect(_on_customer_finished_speaking)
	customer.want_to_speak()
	return

func _on_customer_finished_speaking() -> void:
	desk.spawn_board("res://Resources/Sprites/GameObjectSprites/tax_paper_test.jpg", Vector2.ZERO, 0.1)
