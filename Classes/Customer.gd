class_name Customer
extends Node2D

var sprite: Sprite2D
var data: PackedStringArray
var lines: PackedStringArray = []

func _init(new_name: String, sprite_path: String = "") -> void:
	name = new_name
	var file: FileAccess = FileAccess.open(
		"res://Resources/Customers/"+new_name+"/"+new_name.to_lower()+"_data.txt",
		FileAccess.READ
		)
	data = file.get_as_text().split("\n")
	sprite = Sprite2D.new()
	if sprite_path != "":
		sprite.texture = load(sprite_path)
	else:
		sprite.texture = load("res://Resources/Customers/"+new_name+"/"+new_name.to_lower()+".jpg")
	add_child(sprite) # Draw sprite


func speak() -> void:
	DialogueBox.show_lines(name, lines)
