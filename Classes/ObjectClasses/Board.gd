class_name Board
extends Node2D

@export var size := Vector2.ZERO

var clipped: Array[Board] = []
var dragging := false
var last_mouse := Vector2.ZERO

# Constructor
func _init(sprite_path: String) -> void:
	if sprite_path != "":
		var sprite := Sprite2D.new()
		sprite.texture = load(sprite_path)
		sprite.centered = false
		add_child(sprite)
		size = sprite.texture.get_size()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var mouse := get_global_mouse_position()
			if _contains_point(mouse):
				dragging = true
				last_mouse = mouse
				get_viewport().set_input_as_handled()
			else:
				dragging = false
	elif event is InputEventMouseMotion and dragging:
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			dragging = false
			return
		var mouse := get_global_mouse_position()
		var delta := mouse - last_mouse
		last_mouse = mouse
		for b in get_group():
			b.global_position += delta
	

func _contains_point(global_point: Vector2) -> bool:
	return Rect2(Vector2.ZERO, size).has_point(to_local(global_point))

func clip(other: Board) -> void:
	if other == self or other in clipped:
		return
	clipped.append(other)
	other.clipped.append(self)

func unclip(other: Board) -> void:
	clipped.erase(other)
	other.clipped.erase(self)

func get_group() -> Array[Board]:
	var seen: Array[Board] = [self]
	var stack: Array[Board] = [self]
	while not stack.is_empty():
		var current: Board = stack.pop_back()
		for neighbor in current.clipped:
			if neighbor not in seen:
				seen.append(neighbor)
				stack.append(neighbor)
	return seen
