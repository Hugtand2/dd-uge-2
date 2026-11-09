class_name PersonIncomeTax
extends TaxForm

# Navn af TaxForm
func get_form_title() -> String:
	return "Test"

# Return forskel mellem korrekt skat og angivet skat (Aka fejl)
func validate() -> float:
	return 0.0
	
func _ready() -> void:
	print("Abstract power!")
