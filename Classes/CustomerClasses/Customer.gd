class_name Customer
extends Node2D

signal finished_speaking

const CUSTOMERS_DIR := "res://Resources/Customers/"

@onready var text_bubble_dots_resource: Resource
@onready var text_bubble_dots: Sprite2D

var sprite: Sprite2D
var data: PackedStringArray
var lines: PackedStringArray = []
var customer_data: CustomerData
var has_spoken := false

func _ready() -> void:
	text_bubble_dots_resource = load("res://Resources/Customers/!CustomerResources/speech-bubble-dots.webp")
	text_bubble_dots = Sprite2D.new()
	text_bubble_dots.hide()

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
	text_bubble_dots.texture = text_bubble_dots_resource
	text_bubble_dots.scale = Vector2(0.1,0.1)
	text_bubble_dots.position = Vector2(50,-150)
	add_child(text_bubble_dots)
	text_bubble_dots.show()
	
	greet()
	return

func speak() -> void:
	if has_spoken: return
	text_bubble_dots.hide()
	var section := customer_data.read_section("[DIALOGUE]")
	if section.is_empty():
		return
	DialogueBox.start(name, section)
	DialogueBox.closed.connect(_on_dialogue_closed, CONNECT_ONE_SHOT)
	has_spoken = true
func _on_dialogue_closed() -> void:
	finished_speaking.emit()

func greet() -> void:
	var greetings := customer_data.read_section("[GREETINGS]")
	if greetings.is_empty():
		return
	DialogueText.start(name, PackedStringArray([greetings[randi() % greetings.size()]]))

func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
		and _contains_mouse()):
			get_viewport().set_input_as_handled()
			speak()

func _contains_mouse() -> bool:
	if sprite == null or sprite.texture == null:
		return false
	return sprite.get_rect().has_point(sprite.to_local(get_global_mouse_position()))

static func get_customer_names() -> PackedStringArray:
	var names := PackedStringArray()
	for dir_name in DirAccess.get_directories_at(CUSTOMERS_DIR):
		if dir_name.begins_with("!"):
			continue
		names.append(dir_name)
	return names

static func get_random_customer_name() -> String:
	var names := get_customer_names()
	if names.is_empty():
		push_error("No customers found in " + CUSTOMERS_DIR)
		return ""
	return names[randi() % names.size()]
