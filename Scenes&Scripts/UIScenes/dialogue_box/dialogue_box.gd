extends CanvasLayer

@onready var name_label: Label = $Panel/NameLabel
@onready var text_label: Label = $Panel/TextLabel

var lines: PackedStringArray = []
var index := 0

func _ready() -> void:
	hide()

func start(speaker: String, new_lines: PackedStringArray) -> void:
	if new_lines.is_empty():
		return
	lines = new_lines
	index = 0
	name_label.text = speaker
	text_label.text = lines[0]
	show()

func _input(event: InputEvent) -> void:
	if not visible:
		return

	var advance := false
	if event.is_action_pressed("ui_accept"):
		advance = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance = true

	if not advance:
		return

	get_viewport().set_input_as_handled()
	index += 1
	if index >= lines.size():
		hide()
	else:
		text_label.text = lines[index]
