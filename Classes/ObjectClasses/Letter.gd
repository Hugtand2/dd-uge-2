class_name Letter
extends RulebookPage

# Et brev til spilleren. Samme papir og txt-format som en side i regelbogen
# ([TITLE], [LEFT] og [RIGHT]), men med en konvolut som ikon, uden "Tilbage"-knap
# og med teksten i én spalte i stedet for to. Papiret er drejet til højformat.
# På skrivebordet er brevet en konvolut. Trækkes det væk fra skrivebordet,
# bliver det til en side, man kan læse (det klarer Board selv).
#
# Brug:
#   desk.place_board(Letter.new("res://Resources/Letters/welcome_letter.txt"))

const LETTER_ICON_PATH := "res://Resources/Sprites/GameObjectSprites/letter_placeholder.png"
const LETTER_ICON_SCALE := 0.25

func _init(text_path: String) -> void:
	super(text_path, LETTER_ICON_PATH, LETTER_ICON_SCALE)

# Et brev ligger ikke i regelbogen, så der er ingen "Tilbage"-knap
# Method overriding! RAAAAAAAH POWER!!!!
func _add_exit_button() -> void:
	pass

# Drej papiret, før teksten bygges, så teksten passer til højformatet
func _build_ui() -> void:
	_rotate_paper()
	super()

# Drej kun papirets billede 90 grader (højformat). Teksten er børn af boardet,
# ikke af spriten, så den drejer ikke med.
func _rotate_paper() -> void:
	sprite.rotation_degrees = 90
	# Et drejet billede stikker ud til venstre for boardet, så skub det tilbage
	sprite.position = Vector2(full_size.y, 0)
	# Board bruger size til klik og træk, og full_size når ikonet bliver til en side igen
	full_size = Vector2(full_size.y, full_size.x)
	size = full_size

# Et brev har kun én spalte i hele papirets bredde.
# Skriv hele brevet under [LEFT] i txt-filen og lad [RIGHT] stå tom.
func _add_columns() -> void:
	_add_column(left_lines + right_lines, MARGIN, size.x - 2 * MARGIN)
