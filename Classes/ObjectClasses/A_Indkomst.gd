class_name A_Indkomst
extends TaxForm

# Værdier på blanketten (pr. måned)
var indkomst: float
var traekprocent: float
var fradrag: float

func _init() -> void:
	super("res://Resources/Sprites/GameObjectSprites/tax_paper_test.jpg", 0.1)

	# TODO: tilføj årlig fradrags variant.
	# TODO: med årlig fradrags variant har du bare op til et beløb -
	# TODO: hvor du ikke betaler A-Skat, men kun AM-bidrag.
	# TODO: Hvis du har mere fradrag tilbage end bruttoindkomst-AM, så betaler -
	# TODO: du ikke A-Skat. Hvis du delvist dækker A-Skat med din resterende -
	# TODO: fradrag, bruger du alt dit resterende fradrag og betaler mindre -
	# TODO: Skat. Hvis du ikke har noget resterende fradrag betaler -
	# TODO: du fuld A-Skat.
	# Tilfældige men realistiske månedlige værdier
	indkomst = randi_range(200, 500) * 100.0       # 20.000 - 50.000 kr/md
	traekprocent = randi_range(36, 42) / 100.0     # 36 - 42 %
	fradrag = randi_range(80, 92) * 50.0           # 4.000 - 4.600 kr/md

	_build_ui()

func get_form_title() -> String:
	return "A-Indkomst"

# Korrekt beløb at betale til SKAT: AM-bidrag + A-skat
func get_correct_total() -> float:
	var am := indkomst * AM_RATE
	var skattepligtig := maxf(indkomst - am - fradrag, 0.0)
	return snappedf(am + skattepligtig * traekprocent, 0.01)

func _add_fields(box: VBoxContainer) -> void:
	box.add_child(_make_label("Samlet indkomst: " + _kr(indkomst)))
	box.add_child(_make_label("AM-bidrag: %d %%" % roundi(AM_RATE * 100)))
	box.add_child(_make_label("Trækprocent (A-skat): %d %%" % roundi(traekprocent * 100)))
	box.add_child(_make_label("Fradrag (hovedkort): " + _kr(fradrag)))
	box.add_child(_make_label("I alt at betale til SKAT:"))
