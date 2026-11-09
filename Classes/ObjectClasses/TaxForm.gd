@abstract class_name TaxForm
extends Board


# Abstrakt klasse: lav aldrig TaxForm.new() direkte.
# Hver rigtig blanket (fx A_Indkomst) arver herfra, laver sin egen _init()
# og kalder super("<sti til blankettens billede>").

# Blankettens titel, fx "A-indkomst"
@abstract func get_form_title() -> String

# Return forskel mellem korrekt skat og angivet skat (Aka fejl)
@abstract func validate() -> float
