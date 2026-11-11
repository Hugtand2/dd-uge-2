extends Board

# Regelbogen: et Board med en knap for hver skatteregel.
# Et tryk på en knap skjuler bogen og viser den tilhørende RulebookPage samme sted.
# "Tilbage" på siden skjuler siden og viser bogen igen, der hvor siden blev lagt.
#
# Lav den fra scenen (ikke med .new()):
#   var rulebook := preload("res://Scenes&Scripts/InteractiveScenes/rulebook.tscn").instantiate()
#   add_child(rulebook)

const SPRITE_PATH := "res://Resources/Sprites/GameObjectSprites/rulebook_placeholder.png"
# Skal være den samme skala som RulebookPage.SPRITE_SCALE
const SPRITE_SCALE := 1.0

# Siderne i bogen, i den rækkefølge knapperne skal stå.
# Tilføj en linje her, når der kommer en ny skat med sin egen txt-fil.
const PAGES: Array[String] = [
	"res://Resources/Rulebook/Pages/a_skat.txt",
]

const BUTTONS_POSITION := Vector2(24, 44)   # under "SKAT" på venstre side
const BUTTONS_MARGIN := 24.0                # afstand til kanten og til bogens ryg

var pages: Array[RulebookPage] = []

# En scene kalder _init() uden argumenter, så sprite og skala sættes her
func _init() -> void:
	super(SPRITE_PATH, SPRITE_SCALE)
	_build_ui()

func _build_ui() -> void:
	var box := VBoxContainer.new()
	box.position = BUTTONS_POSITION
	box.size = Vector2(size.x / 2 - 2 * BUTTONS_MARGIN, 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)

	for path in PAGES:
		var page := RulebookPage.new(path)
		page.closed.connect(_close_page.bind(page))
		pages.append(page)

		var button := Button.new()
		button.text = page.title
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", FONT_SIZE)
		button.pressed.connect(_open_page.bind(page))
		box.add_child(button)

# Skjul bogen og vis siden samme sted
func _open_page(page: RulebookPage) -> void:
	# Siden skal ligge ved siden af bogen i træet (ikke som barn),
	# ellers ville den blive skjult sammen med bogen.
	if page.get_parent() == null:
		get_parent().add_child(page)
	replace_with(page)

# Skjul siden og vis bogen der, hvor siden ligger nu
func _close_page(page: RulebookPage) -> void:
	page.replace_with(self)

# Siderne er ikke børn af bogen, så de skal slettes sammen med den
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for page in pages:
			if not is_instance_valid(page):
				continue
			if page.is_inside_tree():
				page.queue_free()
			else:
				page.free()
