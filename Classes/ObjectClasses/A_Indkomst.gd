class_name A_Indkomst
extends TaxForm

func _init() -> void:
	super("res://Resources/Sprites/GameObjectSprites/tax_paper_test.jpg", 0.1)

func get_form_title() -> String:
	return "A-indkomst"

func validate() -> float:
	return 0.0 # TODO: udregn korrekt skat
