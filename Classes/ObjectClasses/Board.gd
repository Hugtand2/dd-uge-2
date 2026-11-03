class_name Board
extends Node2D

@export var size := Vector2.ZERO

var clipped: Array[Board] = []
var dragging := false
var last_mouse := Vector2.ZERO
var sprite: Sprite2D

# Constructor
func _init(sprite_path: String) -> void:
	if sprite_path != "":
		sprite = Sprite2D.new()
		sprite.texture = load(sprite_path)
		sprite.centered = false
		add_child(sprite)
		size = sprite.texture.get_size()

func _ready() -> void:
	add_to_group("boards")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var mouse := get_global_mouse_position()
			if _contains_point(mouse):
				dragging = true
				last_mouse = mouse
				unclip_below()
				bring_to_front()
				get_viewport().set_input_as_handled()
			else:
				dragging = false
	elif event is InputEventMouseMotion and dragging:
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			dragging = false
			if get_board_under():
				clip(get_board_under())
			return
		var mouse := get_global_mouse_position()
		var delta := mouse - last_mouse
		last_mouse = mouse
		for b in get_group():
			b.global_position += delta

func bring_to_front() -> void:
	var members := get_group()
	members.sort_custom(func(a: Board, b: Board): return a.get_index() < b.get_index())
	for b in members:
		b.get_parent().move_child(b, -1)

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

func unclip_below() -> void:
	for other in clipped.duplicate():          # copy, since unclip() edits the array
		if other.get_index() < get_index():
			unclip(other)

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

func get_global_rect() -> Rect2:
	return Rect2(global_position, size)

func get_board_under() -> Board:
	var my_rect := get_global_rect()
	var my_center := my_rect.get_center()
	var best: Board = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group("boards"):
		var other := node as Board
		if other == null or other == self or other in get_group():
			continue
		var other_rect := other.get_global_rect()
		if my_rect.intersects(other_rect):
			var d := my_center.distance_squared_to(other_rect.get_center())
			if d < best_dist:
				best_dist = d
				best = other
	return best
