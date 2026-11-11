class_name Board
extends Node2D

@export var size := Vector2.ZERO

var clipped: Array[Board] = []
var dragging := false
var last_mouse := Vector2.ZERO
var sprite: Sprite2D
var on_desk := false

# For icon handling (small sprite when on desk)
var icon_sprite: Sprite2D
var full_size := Vector2.ZERO
var icon_size := Vector2.ZERO
var is_icon := false

# Constructor
func _init(sprite_path: String, sprite_scale: float, icon_path := "", icon_scale := 0.25) -> void:
	if sprite_path != "":
		var tex := load(sprite_path) as Texture2D
		if tex == null:
			push_error("Board: could not load sprite: " + sprite_path)
			return
		sprite = Sprite2D.new()
		sprite.texture = tex
		sprite.centered = false
		add_child(sprite)
		full_size = tex.get_size() * sprite_scale
		sprite.scale *= sprite_scale
		size = full_size
	else:
		print("Sprite path not found")
	if icon_path != "":
		icon_sprite = Sprite2D.new()
		icon_sprite.texture = load(icon_path)
		icon_sprite.centered = false
		icon_sprite.scale *= icon_scale
		icon_size = icon_sprite.texture.get_size() * icon_scale
		icon_sprite.hide()
		add_child(icon_sprite)

func _ready() -> void:
	add_to_group("boards")
	# Hides VBox, index 2 is VBox
	get_child(2).hide()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var mouse := get_global_mouse_position()
			if _contains_point(mouse) and _is_over_control(mouse):
				# Lad klikket gå videre til input-feltet (fx LineEdit på en blanket)
				dragging = false
				bring_to_front()
				return
			if _contains_point(mouse):
				get_viewport().gui_release_focus()
				dragging = true
				last_mouse = mouse
				lift()
				bring_to_front()
				get_viewport().set_input_as_handled()
			else:
				dragging = false
		elif dragging:
			_drop()
	elif event is InputEventMouseMotion and dragging:
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_drop()
			return
		var mouse := get_global_mouse_position()
		var delta := mouse - last_mouse
		last_mouse = mouse
		for b in get_group():
			b.global_position += delta
		_update_icon_mode(mouse)

func _drop() -> void:
	dragging = false
	var target := get_board_under()
	if target and not is_icon:
		clip(target)
	for desk in get_tree().get_nodes_in_group("desks"):
		desk.board_dropped(self)

func bring_to_front() -> void:
	var members := get_group()
	members.sort_custom(func(a: Board, b: Board): return a.get_index() < b.get_index())
	for b in members:
		b.get_parent().move_child(b, -1)

func _contains_point(global_point: Vector2) -> bool:
	return Rect2(Vector2.ZERO, size).has_point(to_local(global_point))

# Er punktet over en Control (fx et input-felt), der selv skal have musen?
func _is_over_control(global_point: Vector2) -> bool:
	for node in find_children("*", "Control", true, false):
		var c := node as Control
		if c.is_visible_in_tree() and c.mouse_filter != Control.MOUSE_FILTER_IGNORE \
				and c.get_global_rect().has_point(global_point):
			return true
	return false

func clip(other: Board) -> void:
	if other == self or other in clipped:
		return
	clipped.append(other)
	other.clipped.append(self)

func unclip(other: Board) -> void:
	clipped.erase(other)
	other.clipped.erase(self)

func lift() -> void:
	var my_index := get_index()
	var group := get_group()

	# Boards above (or equal to) me, reachable from me through overlapping rects.
	var carried: Array[Board] = [self]
	var stack: Array[Board] = [self]
	while not stack.is_empty():
		var current: Board = stack.pop_back()
		for b in group:
			if b in carried or b.get_index() < my_index:
				continue
			if current.get_global_rect().intersects(b.get_global_rect()):
				carried.append(b)
				stack.append(b)

	# Cut every link between carried boards and everything else.
	for a in carried:
		for other in a.clipped.duplicate():
			if other not in carried:
				a.unclip(other)

	# Link carried boards that really touch each other.
	for a in carried:
		for b in carried:
			if a != b and a.get_global_rect().intersects(b.get_global_rect()):
				a.clip(b)

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

func set_icon_mode(on: bool) -> void:
	if on and icon_sprite == null:
		return
	var center := global_position + size / 2.0
	is_icon = on
	sprite.visible = not on
	if icon_sprite:
		icon_sprite.visible = on
	size = icon_size if on else full_size
	global_position = center - size / 2.0

func _update_icon_mode(mouse: Vector2) -> void:
	if icon_sprite == null:
		return
	var over_desk := _is_point_over_desk(mouse)
	if over_desk and not is_icon:
		set_icon_mode(true)
		get_child(2).hide()
		global_position = mouse - size / 2.0     # icon centered on the cursor
	elif not over_desk and is_icon:
		set_icon_mode(false)
		get_child(2).show()
		global_position = mouse - size / 2.0     # full board centered on the cursor
	else:
		return
	last_mouse = mouse

func _is_point_over_desk(point: Vector2) -> bool:
	for desk in get_tree().get_nodes_in_group("desks"):
		if desk.get_global_rect().has_point(point):
			return true
	return false
