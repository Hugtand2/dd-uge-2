extends CanvasLayer

@onready var name_label: Label = $Panel/NameLabel
@onready var text_label: Label = $Panel/TextLabel

var lines: Array[String] = []
var index := 0

func _ready() -> void:
	hide()

func show_lines(speaker: String, new_lines: Array[String]) -> void:
	if new_lines.is_empty():
		return
	name_label.text = speaker
	lines = new_lines
	index = 0
	text_label.text = lines[0]
	show()

func _input(event: InputEvent) -> void:
	if not visible: return
	if event.is_action_pressed("Confirm"):
		get_viewport().set_input_as_handled()
		index += 1
		if index >= lines.size():
			hide()
		else:
			text_label.text = lines[index]
