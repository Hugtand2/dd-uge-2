extends Node2D

const RULEBOOK := preload("res://Scenes&Scripts/InteractiveScenes/rulebook.tscn")

var amount = 1
var forms: Array[TaxForm] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AudioPlayer.play_custom_track("res://Resources/Audio/Music/Theme For Ernie (Remastered 2026) (320kbps).mp3")
	for b in amount:
		add_child(Board.new("res://Resources/UIAssets/Alien.png", 1.0))
		var form := A_Indkomst.new()        # månedlig
		add_child(form)
		forms.append(form)

		var yearly := A_Indkomst.new(1)     # årlig
		yearly.position = Vector2(300, 0)
		add_child(yearly)
		forms.append(yearly)

		var stocks := Aktieindkomst.new()   # aktieskat (altid årlig)
		stocks.position = Vector2(600, 0)
		add_child(stocks)
		forms.append(stocks)

	# Regelbogen er en scene (ikke en klasse), så den laves med instantiate()
	var rulebook := RULEBOOK.instantiate()
	rulebook.position = Vector2(540, 240)
	add_child(rulebook)

# Tryk på "Test" (Å) for at validere de spawnede blanketter.
# _input kører før GUI, så det virker også, mens svarfeltet har fokus.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Test"):
		get_viewport().set_input_as_handled() # Skriv ikke "å" i svarfeltet
		for form in forms:
			print("%s: korrekt %s, svar \"%s\", forskel %s" % [
				form.get_form_title(),
				TaxForm._kr(form.get_correct_total()),
				form.answer_field.text,
				TaxForm._kr(form.validate()),
			])
