extends Node2D

# Default pay, that can be deviated from
const MAXPAYMENT = 20

@onready var desk := $Desk
@onready var money_label := $MoneyLabel

var current_customer: Customer
var is_serving := false
var money := 0.00
var payment_guess: float
var paper_types := Weighed_Array.new()
var current_paper: Board


func _ready() -> void:
	# Decide paper_types and probability distrubution of them
	paper_types.add(A_Indkomst, 1.0)
	
	money_label.text = TaxForm._kr(money)

func customer_arrive() -> void:
	if current_customer:
		return
	is_serving = true
	current_customer = Customer.new(Customer.get_random_customer_name())
	add_child(current_customer)
	############################################################################
	# Insert animation
	current_customer.position = Vector2i(get_viewport_rect().size/2)
	############################################################################
	# On anim.finished():
	current_customer.finished_speaking.connect(_on_customer_finished_speaking)
	current_customer.board_received.connect(_on_customer_board_received)
	current_customer.want_to_speak()
	return

func customer_leave() -> void:
	if not current_customer:
		return
	is_serving = false
	############################################################################
	# Insert animation
	############################################################################
	remove_customer()
	pass

func _on_customer_finished_speaking() -> void:
	current_paper = paper_types.pick_weighed_random().new()
	desk.place_board(current_paper)

func _on_customer_board_received(_board: Board = null) -> void:
	print("Paper given")
	get_payout()
	customer_leave()

func remove_customer() -> void:
	if current_customer == null:
		return
	current_customer.queue_free()
	current_customer = null
	is_serving = false

func get_payout() -> void:
	var payout: float
	payment_guess = 100000
	payout = MAXPAYMENT * (1 - abs(current_paper.get_correct_total() - payment_guess)/current_paper.get_correct_total())
	money += payout
	money_label.text = TaxForm._kr(money)
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Test"): _on_customer_board_received()
