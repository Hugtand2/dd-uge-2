extends Node2D

@onready var desk := $Desk
@onready var money_label := $MoneyLabel

var current_customer: Customer
var is_serving := false
var money := 0.00
var paper_types := [
	A_Indkomst.new(1),
	A_Indkomst.new(12)
	]

func _ready() -> void:
	money_label.text = TaxForm._kr(money)
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
	desk.place_board(paper_types.pick_random())
