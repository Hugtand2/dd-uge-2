class_name Customer
extends Node2D

var sprite: Sprite2D
var lines: Array[String] = []

func _init(new_name: String, sprite_path: String) -> void:
	name = new_name
	if sprite_path != "":
		sprite = Sprite2D.new()
		sprite.texture = load(sprite_path)
		add_child(sprite) # Draw sprite

func speak() -> void:
	DialogueBox.show_lines(name, lines)
