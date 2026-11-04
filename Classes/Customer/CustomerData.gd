class_name CustomerData
extends Customer

var string_data: PackedStringArray
var view_index: int = 0

func _init(new_data: PackedStringArray) -> void:
	string_data = new_data

#func 

func findKeywordIndex(key_word: String) -> int:
	var found_index
	for l in string_data.size() - 1:
		string_data[l].strip_edges() # Removes \n
		if string_data[l] == "[DIALOGUE]": found_index = view_index
		view_index += 1
	return found_index
