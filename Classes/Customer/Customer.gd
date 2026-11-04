class_name Customer
extends Node2D

var sprite: Sprite2D
var data: PackedStringArray
var lines: PackedStringArray = []
var customer_data: CustomerData


func _init(new_name: String, sprite_path: String = "") -> void:
	name = new_name
	var path := "res://Resources/Customers/" + new_name + "/" + new_name.to_lower() + "_data.txt"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open " + path)
		return
	data = file.get_as_text().split("\n")
	customer_data = CustomerData.new(data)
	sprite = Sprite2D.new()
	if sprite_path != "":
		sprite.texture = load(sprite_path)
	else:
		sprite.texture = load("res://Resources/Customers/" + new_name + "/" + new_name.to_lower() + ".jpg")
	add_child(sprite)

func want_to_speak() -> void:
	# Add sprite to scenetree
	var text_bubble_dots_resource := load("res://Resources/Customers/!CustomerResources/speech-bubble-dots.webp")
	var text_bubble_dots := Sprite2D.new()
	text_bubble_dots.texture = text_bubble_dots_resource
	text_bubble_dots.scale = Vector2(0.1,0.1)
	text_bubble_dots.position = Vector2(50,-150)
	add_child(text_bubble_dots)
	return

func speak() -> void:
	DialogueBox.start(name, customer_data.read_section("[DIALOGUE]"))

func greet() -> void:
	var greetings := customer_data.read_section("[GREETINGS]")
	if greetings.is_empty():
		return
	DialogueBox.start(name, PackedStringArray([greetings[randi() % greetings.size()]]))
