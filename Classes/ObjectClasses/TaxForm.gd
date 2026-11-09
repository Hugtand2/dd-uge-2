@abstract class_name TaxForm
extends Board


# Abstrakt klasse: lav aldrig TaxForm.new() direkte.
# Hver rigtig blanket (fx A_Indkomst) arver herfra, laver sin egen _init()
# og kalder super("<sti til blankettens billede>", <skala>) og derefter _build_ui().
#
# En blanket skal selv implementere:
#   get_form_title()     -> titlen øverst på blanketten
#   get_correct_total()  -> det korrekte beløb
#   _add_fields(box)     -> blankettens egne linjer (labels)
# Resten (titel, svarfelt, validate, formatering) arves herfra.

const FONT_SIZE := 12
const TITLE_FONT_SIZE := 16
const AM_RATE := 0.08 # AM-bidrag er 8 % ved lov

var answer_field: LineEdit

# Blankettens titel, fx "A-indkomst"
@abstract func get_form_title() -> String

# Det korrekte beløb, spilleren skulle have skrevet
@abstract func get_correct_total() -> float

# Tilføj blankettens egne linjer mellem titlen og svarfeltet
@abstract func _add_fields(box: VBoxContainer) -> void

# Forskel mellem korrekt skat og spillerens svar (Aka fejl).
# Kan overskrives, hvis en blanket har flere svarfelter.
func validate() -> float:
	return get_correct_total() - _parse_kr(answer_field.text)

# Byg blankettens skelet: titel, egne linjer og svarfelt
func _build_ui() -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(16, 16)
	box.size = Vector2(size.x - 32, 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)

	box.add_child(_make_label(get_form_title(), TITLE_FONT_SIZE))
	_add_fields(box)

	answer_field = LineEdit.new()
	answer_field.placeholder_text = "0,00"
	answer_field.add_theme_font_size_override("font_size", FONT_SIZE)
	box.add_child(answer_field)

func _make_label(text: String, font_size: int = FONT_SIZE) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", Color.BLACK)
	label.add_theme_font_size_override("font_size", font_size)
	return label

# Formatér beløb på dansk, fx 30.000,00 kr
static func _kr(value: float) -> String:
	var parts := ("%.2f" % absf(value)).split(".")
	var whole := parts[0]
	var out := ""
	while whole.length() > 3:
		out = "." + whole.right(3) + out
		whole = whole.left(whole.length() - 3)
	out = whole + out
	return ("-" if value < 0 else "") + out + "," + parts[1] + " kr"

# Læs et beløb skrevet på dansk (fx "30.000,50") som tal. Ugyldigt input giver 0.
static func _parse_kr(text: String) -> float:
	text = text.strip_edges().replace(" ", "")
	if text.contains(","):
		text = text.replace(".", "").replace(",", ".")
	return text.to_float() if text.is_valid_float() else 0.0
