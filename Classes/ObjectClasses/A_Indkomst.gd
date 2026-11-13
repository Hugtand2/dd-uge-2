class_name A_Indkomst
extends TaxForm

const ICON_PATH := "res://Resources/Sprites/GameObjectSprites/TaxFormSprites/tax_paper_test.jpg"

# Værdier på blanketten (pr. periode: måned eller år)
var indkomst: float
var traekprocent: float
var fradrag: float

# 12 = månedlig blanket, 1 = årlig blanket.
# Beløbene trækkes som månedlige værdier og ganges op til perioden,
# og de progressive skattegrænser deles med det samme tal.
var periods: int

func _init(p_periods: int = [1,12].pick_random()) -> void:
	super("res://Resources/Sprites/GameObjectSprites/TaxFormSprites/tax_paper_test.jpg", 0.1, ICON_PATH, 0.025)
	periods = p_periods
	var months_per_period := 12.0 / periods

	# Tilfældige men realistiske værdier (månedlige, ganget op til perioden)
	indkomst = _random_indkomst() * months_per_period
	traekprocent = randi_range(36, 42) / 100.0                 # 36 - 42 %
	fradrag = randi_range(80, 92) * 50.0 * months_per_period   # 4.000 - 4.600 kr/md

	_build_ui()

func is_yearly() -> bool:
	return periods == 1

func get_form_title() -> String:
	return "A-Indkomst (årlig)" if is_yearly() else "A-Indkomst (månedlig)"

# Tilfældig månedlig indkomst. Hvert trin rammer præcis én skattegrænse
# (efter AM-bidrag): ingen ekstra skat, mellemskat, + topskat, + toptopskat.
func _random_indkomst() -> float:
	# Årlig: nogle gange så lav indkomst, at fradraget dækker hele eller
	# en del af A-skatten, så der kun (eller mest) betales AM-bidrag.
	if is_yearly() and randf() < 0.2:
		return randi_range(30, 50) * 100.0       # 3.000 - 5.000 kr/md (36.000 - 60.000 kr/år)

	var r := randf()
	# Tempoary
	if r < 0.5:
		return randi_range(200, 500) * 100.0     # 20.000 - 50.000 kr/md
	elif r < 0.75:
		return randi_range(590, 700) * 100.0     # 59.000 - 70.000 kr/md (mellemskat)
	elif r < 0.93:
		return randi_range(720, 2000) * 100.0    # 72.000 - 200.000 kr/md (+ topskat)
	else:
		return randi_range(2400, 4000) * 100.0   # 240.000 - 400.000 kr/md (+ toptopskat)

# Korrekt beløb at betale til SKAT: AM-bidrag + A-skat + progressive skatter.
# Fradraget gælder kun trækprocenten. Mellem-, top- og toptopskat beregnes
# af hele indkomsten efter AM-bidrag (uden fradrag).
# Er fradraget større end indkomsten efter AM-bidrag, betales ingen A-skat.
func get_correct_total() -> float:
	var am := indkomst * AM_RATE
	var efter_am := indkomst - am
	var skattepligtig := maxf(efter_am - fradrag, 0.0)
	var progressiv := _progressive_tax(efter_am, periods)
	return snappedf(am + skattepligtig * traekprocent + progressiv, 0.01)

func _add_fields(box: VBoxContainer) -> void:
	var per := "pr. år" if is_yearly() else "pr. md"
	box.add_child(_make_label("Samlet indkomst (%s): %s" % [per, _kr(indkomst)]))
	box.add_child(_make_label("Trækprocent (A-skat): %d %%" % roundi(traekprocent * 100)))
	box.add_child(_make_label("Fradrag (hovedkort, %s): %s" % [per, _kr(fradrag)]))
	box.add_child(_make_label("I alt at betale til SKAT:"))
