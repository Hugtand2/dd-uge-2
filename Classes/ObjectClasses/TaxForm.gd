@abstract class_name TaxForm
extends Board

# Navn af TaxForm
@abstract func get_form_title() -> String

# Return forskel mellem korrekt skat og angivet skat (Aka fejl)
@abstract func validate() -> float

func _ready() -> void:
	super()
	
