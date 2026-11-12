extends Node2D

# Default pay, that can be deviated from
const MAXPAYMENT = 20

@onready var desk := $Desk
@onready var money_label := $MoneyLabel

var current_customer: Customer
var is_serving := false
var money := 0.00
var payment_guess: float
var paper_types := Weighted_Array.new()
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
	current_paper = paper_types.pick_weighted_random().new()
	desk.place_board(current_paper)

func _on_customer_board_received(_board: Board = null) -> void:
	print("Paper given")
	get_money()
	customer_leave()

func remove_customer() -> void:
	if current_customer == null:
		return
	current_customer.queue_free()
	current_customer = null
	is_serving = false

func get_money() -> void:
	if not current_paper: return
	# Test variable.value:
	payment_guess = 100000
	var actual_payment = current_paper.get_correct_total()
	var dPayment = abs(actual_payment - payment_guess)
	
	# This distributes the pay according to dPayment via. a Gauss curve
	# If dPayment == 0, it returns MAXPAY * 1
	# If dPayment == actual_payment * 0.1, it returns 0
	# If dPayment >= actual_payment * 0.1, it asymptonically returns MAXPAY * (-1)
	money += (2 * pow(1.0/2, pow(dPayment/(actual_payment * 0.1), 2)) - 1) * MAXPAYMENT
	
	AudioPlayer.play_sound_effect("res://Resources/Audio/SoundEffects/AnimationSoundEffects/money.mp3")
	money_label.text = TaxForm._kr(money)

# Test function:
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Test"): _on_customer_board_received()
