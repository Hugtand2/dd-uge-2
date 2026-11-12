extends Node2D

@onready var desk := $Desk
@onready var money_label := $MoneyLabel

var current_customer: Customer
var is_serving := false
var money := 0.00
var paper_types := Weighed_Array.new()


func _ready() -> void:
	# Decide paper_types and probability distrubution of them
	paper_types.add(A_Indkomst, 1.0)
	
	money_label.text = TaxForm._kr(money)

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
	desk.place_board(paper_types.pick_weighed_random().new())

func _on_paper_given() -> void:
	print("Paper placed")
	return

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Test"): _on_paper_given()
