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
# _progressive_tax() regner mellem-, top- og toptopskat ud for blanketterne.
	
# FONT_SIZE, TITLE_FONT_SIZE og _make_label() arves fra Board.
const AM_RATE := 0.08 # AM-bidrag er 8 % ved lov

# Progressive skatter 2026: årlig grænse (efter AM-bidrag) og ekstra sats.
# Den ekstra sats gælder kun for den del af indkomsten, der ligger over grænsen.
# Det står i TaxForm, fordi den kan være relevant for flere forskellige typer skat.
const PROGRESSIVE_BRACKETS := [
	{"name": "Mellemskat", "limit": 641200.0,  "rate": 0.075},
	{"name": "Topskat",    "limit": 777900.0,  "rate": 0.075},
	{"name": "Toptopskat", "limit": 2592700.0, "rate": 0.05},
]

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
	answer_field.placeholder_text = "0000,00kr"
	answer_field.add_theme_font_size_override("font_size", FONT_SIZE)
	box.add_child(answer_field)

# Ekstra skat oven i trækprocenten (mellem-, top- og toptopskat).
# grundlag = indkomst efter AM-bidrag, men FØR fradrag. Hovedkort-fradraget
# gælder kun trækprocenten, ikke mellem-, top- og toptopskat!
# periods = 12 for månedlige blanketter (grænserne deles med 12), 1 for årlige.
# Det her står ikke i A-SKAT alene, da den også bruges til B-SKAT.
static func _progressive_tax(grundlag: float, periods: int = 12) -> float:
	var total := 0.0
	for bracket in PROGRESSIVE_BRACKETS:
		var limit := roundf(float(bracket["limit"]) / periods)
		total += maxf(grundlag - limit, 0.0) * float(bracket["rate"])
	return total

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
