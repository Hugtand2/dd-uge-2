class_name RulebookPage
extends Board

# En side i regelbogen. Den er et Board, så den kan trækkes rundt som alt andet papir.
# Teksten læses fra en txt-fil i res://Resources/Rulebook/Pages/ med sektionerne:
#   [TITLE]  -> første linje er sidens titel (bruges også på knappen i regelbogen)
#   [LEFT]   -> venstre spalte
#   [RIGHT]  -> højre spalte
# Hver linje i [LEFT] og [RIGHT] bliver til sin egen label (et afsnit).
#
# Siden kender ikke regelbogen. Den sender bare signalet `closed`, når spilleren
# trykker på "Tilbage", og så er det regelbogen, der bytter tilbage.

signal closed

const SPRITE_PATH := "res://Resources/Sprites/GameObjectSprites/rulebook_page_placeholder.png"
# Skal være den samme skala som regelbogen, så de dækker hinanden præcist
const SPRITE_SCALE := 1.0

const MARGIN := 20.0        # afstand fra papirets kant til teksten
const COLUMN_GAP := 20.0    # afstand mellem venstre og højre spalte
const COLUMN_TOP := 44.0    # hvor spalterne starter (under titlen)

var title := ""
var left_lines := PackedStringArray()
var right_lines := PackedStringArray()
var exit_button: Button

func _init(text_path: String) -> void:
	super(SPRITE_PATH, SPRITE_SCALE)
	_load_text(text_path)
	_build_ui()

func _load_text(text_path: String) -> void:
	var file := FileAccess.open(text_path, FileAccess.READ)
	if file == null:
		push_error("Could not open " + text_path)
		return
	# Samme [SEKTION]-format som kundernes data, så vi genbruger CustomerData
	var page_data := CustomerData.new(file.get_as_text().split("\n"))
	title = page_data.read_line("[TITLE]", 0)
	left_lines = page_data.read_section("[LEFT]")
	right_lines = page_data.read_section("[RIGHT]")

func _build_ui() -> void:
	var title_label := _make_label(title, TITLE_FONT_SIZE)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.position = Vector2(0, 10)
	title_label.size = Vector2(size.x, 0)
	add_child(title_label)

	var column_width := (size.x - 2 * MARGIN - COLUMN_GAP) / 2
	_add_column(left_lines, MARGIN, column_width)
	_add_column(right_lines, MARGIN + column_width + COLUMN_GAP, column_width)

	# Knappen er den eneste Control på siden, der tager imod klik
	exit_button = Button.new()
	exit_button.text = "Tilbage"
	exit_button.focus_mode = Control.FOCUS_NONE
	exit_button.add_theme_font_size_override("font_size", FONT_SIZE)
	exit_button.size = Vector2(70, 26)
	exit_button.position = Vector2(size.x - exit_button.size.x - 12, 8)
	exit_button.pressed.connect(func() -> void: closed.emit())
	add_child(exit_button)

func _add_column(lines: PackedStringArray, x: float, width: float) -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(x, COLUMN_TOP)
	box.size = Vector2(width, 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	for line in lines:
		box.add_child(_make_label(line))
