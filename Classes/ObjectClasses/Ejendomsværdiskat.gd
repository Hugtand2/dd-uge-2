class_name Ejendomsværdiskat
extends TaxForm

const SPRITE_PATH := "res://Resources/Sprites/GameObjectSprites/TaxFormSprites/tax_paper_test.jpg"
const ICON_PATH := "res://Resources/Sprites/GameObjectSprites/TaxFormSprites/tax_paper_test.jpg"

# Ejendomsværdiskat 2026 (årlig).
# Grænsen gælder grundlaget efter fradraget (de 80 %), ikke selve vurderingen.
const FRADRAG_RATE := 0.20               # 20 % af vurderingen trækkes fra
const LOW_RATE := 0.0051                 # 0,51 % af grundlaget op til grænsen
const HIGH_RATE := 0.014                 # 1,4 % af den del, der ligger over grænsen
const PROGRESSION_LIMIT := 9200000.0

# Ejendomsvurderingen. Det er det eneste tal, der står på blanketten.
# Fradrag, satser og grænse skal spilleren slå op i regelbogen.
var vurdering: float

func _init() -> void:
	super(SPRITE_PATH, 0.1, ICON_PATH, 0.025)
	vurdering = _random_vurdering()
	_build_ui()

func get_form_title() -> String:
	return "Ejendomsværdiskat (årlig)"

# Tilfældig vurdering i hele 100.000 kr mellem 1 og 35 mio. kr.
# Grundlaget rammer grænsen på 9,2 mio. ved en vurdering på 11,5 mio.,
# så det første interval giver kun lav sats, og det andet giver også høj sats.
func _random_vurdering() -> float:
	if randf() < 0.6:
		return randi_range(10, 115) * 100000.0    # 1.000.000 - 11.500.000 kr
	return randi_range(116, 350) * 100000.0       # 11.600.000 - 35.000.000 kr

# Korrekt beløb at betale til SKAT.
# Først trækkes 20 % fra vurderingen. Af resten (grundlaget) betales 0,51 %
# op til grænsen og 1,4 % af den del, der ligger over.
func get_correct_total() -> float:
	var grundlag := vurdering * (1.0 - FRADRAG_RATE)
	var lav := minf(grundlag, PROGRESSION_LIMIT) * LOW_RATE
	var hoej := maxf(grundlag - PROGRESSION_LIMIT, 0.0) * HIGH_RATE
	return snappedf(lav + hoej, 0.01)

func _add_fields(box: VBoxContainer) -> void:
	box.add_child(_make_label("Ejendomsvurdering: %s" % _kr(vurdering)))
	box.add_child(_make_label("I alt at betale til SKAT:"))
