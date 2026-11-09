class_name Dialogue
extends CanvasLayer

@onready var text_label: Label = %TextLabel   # every dialogue scene needs a Label named TextLabel
@export var close_on_any_input := false

signal closed

var speaker := ""
var lines: PackedStringArray = []
var index := 0

func _ready() -> void:
	_close()

func _close() -> void:
	hide()
	closed.emit()
	pass

func start(new_speaker: String, new_lines: PackedStringArray) -> void:
	if new_lines.is_empty():
		return
	speaker = new_speaker
	lines = new_lines
	index = 0
	_refresh()
	show()

# Children override this to update extra UI (name label, portrait, ...)
func _refresh() -> void:
	text_label.text = lines[index]

func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	if close_on_any_input:
		var is_press := event.is_pressed() and not event.is_echo() \
			and (event is InputEventKey or event is InputEventMouseButton)
		if is_press:
			_close()
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
		_close()
	else:
		_refresh()
