extends Node2D

# Default pay, that can be deviated from
const MAXPAYMENT = 20
const CALCULATOR_SCENE := preload("res://Addons/Calculator/Resources/scenes/calculator.tscn")
const RULEBOOK := preload("res://Scenes&Scripts/InteractiveScenes/rulebook.tscn")
const WELCOME_LETTER := "res://Resources/Letters/welcome_letter.txt"

@onready var desk := $Desk
@onready var money_label := $MoneyLabel
@onready var quota_label := $QuotaLabel
@onready var game_over_screen := $GameOverScreen
@onready var game_over_label := $GameOverScreen/GameOverLabel
@onready var game_over_sub_label := $GameOverScreen/GameOverLabel/GameOverSubLabel
@onready var red_tint := $GameOverScreen/RedTint
@onready var retry_button := $GameOverScreen/RetryButton

# For layout setup:
@onready var left_wall := $Frame/LeftWall
@onready var right_wall := $Frame/RightWall

var current_customer: Customer
var is_serving := false
var money := 0.00
var payment_guess: float
var paper_types := Weighted_Array.new()
var current_paper: Board

var sprint_quota := 50.00
var served_during_sprint := 0
var sprint_size := 3
var sprint_money := 0.00


func _ready() -> void:
	setup_paper_types()
	setup_layout()
	setup_desk()
	money_label.text = TaxForm._kr(money)
	Global.game_over = false

func setup_paper_types() -> void:
	paper_types.add(A_Indkomst, 2.0)
	paper_types.add(Aktieindkomst, 1.0)
	paper_types.add(Ejendomsværdiskat, 1.0)
	spawn_calculator()

func setup_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var wall_size := Vector2(viewport_size.x * 3 / 10.0, viewport_size.y)

	for wall in [left_wall, right_wall]:
		wall.centered = false      # så position er øverste venstre hjørne
		set_sprite_size(wall, wall_size)

	left_wall.position = Vector2.ZERO
	right_wall.position = Vector2(viewport_size.x - wall_size.x, 0)

func setup_desk() -> void:
	# spawn rulebook
	var rulebook := RULEBOOK.instantiate()
	desk.place_board(rulebook, Vector2(200, 30))

	# spawn velkomstbrevet: en konvolut på skrivebordet, en side når det trækkes væk
	desk.place_board(Letter.new(WELCOME_LETTER), Vector2(0, 30))

func customer_arrive() -> void:
	if current_customer:
		return
	is_serving = true
	current_customer = Customer.new(Customer.get_random_customer_name())
	add_child(current_customer)
	# Loads current_customer just in front of background at index 0
	move_child(current_customer, 1)
	
	# Tweens the customer in
	current_customer.position = Vector2(get_viewport_rect().size/2) - Vector2(400,0)
	var tween = get_tree().create_tween()
	tween.tween_property(current_customer, "position", Vector2(get_viewport_rect().size/2), 1).set_trans(Tween.TRANS_SINE)
	
	await tween.finished
	current_customer.finished_speaking.connect(_on_customer_finished_speaking)
	current_customer.board_received.connect(_on_customer_board_received)
	current_customer.want_to_speak()
	current_customer.can_interact = true
	return

func customer_leave() -> void:
	if not current_customer:
		return
	is_serving = false
	served_during_sprint += 1
	
	#Tween the customer out
	var tween = get_tree().create_tween()
	tween.tween_property(current_customer, "position", Vector2(get_viewport_rect().size/2 + Vector2(400,0)), 1).set_trans(Tween.TRANS_SINE)
	
	await tween.finished
	remove_customer()
	if served_during_sprint >= sprint_size: finish_sprint()

func finish_sprint() -> void:
	# If quota reached
	if sprint_money >= sprint_quota:
		complete_quota()
	# If quota not reached
	else:
		game_over()

func complete_quota() -> void:
	quota_label.text = "Quota reached!"
	quota_label.show()
	await Tweens.wobble(quota_label)
	quota_label.hide()

func game_over() -> void:
	Global.game_over = true
	quota_label.text = "Quota not reached!?"
	quota_label.show()
	
	move_child(game_over_screen, -1)
	game_over_label.text = "You're fired"
	game_over_sub_label.text = "The firing squad is coming for you"
	red_tint.size = get_viewport_rect().size
	
	game_over_screen.position = Vector2(0, -get_viewport_rect().size.y)   # start off-screen, avoids a one-frame flash
	retry_button.disabled = true
	game_over_screen.show()
	await get_tree().process_frame
	
	var center := get_viewport_rect().size / 2
	game_over_label.position = center - game_over_label.size / 2
	retry_button.position = Vector2(center.x - retry_button.size.x / 2, center.y + 125)
	
	
	var fade := get_tree().create_tween()
	fade.tween_property(AudioPlayer.music_player, "volume_db", -80.0, 1)
	
	await fade.finished
	var bounce := get_tree().create_tween()
	bounce.tween_property(game_over_screen, "position", Vector2.ZERO, 1) \
		.from(Vector2(0,-648)) \
		.set_trans(Tween.TRANS_BOUNCE) \
		.set_ease(Tween.EASE_OUT)
	
	# Plays sound effect on first impact
	get_tree().create_timer(0.364).timeout.connect(
		func(): AudioPlayer.play_sound_effect("res://Resources/Audio/SoundEffects/AnimationSoundEffects/GameOverScreenFallHit.mp3"))
	
	await bounce.finished
	retry_button.disabled = false
	

func remove_customer() -> void:
	if current_customer == null:
		return
	current_customer.queue_free()
	current_customer = null
	is_serving = false

# Fjern blanketten, når kunden har fået den tilbage
func remove_paper() -> void:
	if current_paper == null:
		return
	current_paper.set_enabled(false) # skjul, fjern clips og tag den ud af "boards"
	current_paper.queue_free()
	current_paper = null

func _on_customer_finished_speaking() -> void:
	current_paper = paper_types.pick_weighted_random().new()
	desk.place_board(current_paper)

func _on_customer_board_received(_board: Board = null) -> void:
	print("Paper given")
	payment_guess = TaxForm._parse_kr(current_paper.answer_field.text)
	get_payout()
	remove_paper()
	customer_leave()

func get_payout() -> void:
	if not current_paper: return
	var actual_payment = current_paper.get_correct_total()
	var d_payment = abs(actual_payment - payment_guess)
	
	# This distributes the pay according to d_payment via. a Gauss curve
	# If d_payment == 0, it returns MAXPAY * 1
	# If d_payment == actual_payment * 0.1, it returns 0
	# If d_payment >= actual_payment * 0.1, it asymptotically returns MAXPAY * (-1)
	var payout = (2 * pow(1.0/2, pow(d_payment/(actual_payment * 0.1), 2)) - 1) * MAXPAYMENT
	if d_payment == 0: payout *= 1.25
	money += payout
	sprint_money += payout
	
	AudioPlayer.play_sound_effect("res://Resources/Audio/SoundEffects/AnimationSoundEffects/money.mp3")
	money_label.text = TaxForm._kr(money)
	Tweens.wobble(money_label)

func spawn_calculator() -> void:
	var calc = CALCULATOR_SCENE.instantiate() as Board
	desk.place_board(calc, Vector2(-200, -50))

# For setup
func set_sprite_size(sprite: Sprite2D, target_size: Vector2) -> void:
	if not sprite.texture:
		return
		
	var texture_size: Vector2 = sprite.texture.get_size()
	
	# Calculate the ratio needed to reach the target pixel dimensions
	sprite.scale = target_size / texture_size

# Test function
func _input(event: InputEvent) -> void:
	if not current_paper: return
	if event.is_action_pressed("Test"):
		complete_quota()
		get_viewport().set_input_as_handled() # Skriv ikke "å" i svarfeltet
		print("%s: korrekt %s, svar \"%s\", forskel %s" % [
			current_paper.get_form_title(),
			TaxForm._kr(current_paper.get_correct_total()),
			current_paper.answer_field.text,
			TaxForm._kr(current_paper.validate()),
		])
