class_name Board
extends Node2D

@export var size := Vector2.ZERO

var clipped: Array[Board] = []
var dragging := false
var last_mouse := Vector2.ZERO
var sprite: Sprite2D

# Constructor
func _init(sprite_path: String, sprite_scale: float) -> void:
	if sprite_path != "":
		sprite = Sprite2D.new()
		sprite.texture = load(sprite_path)
		sprite.centered = false
		add_child(sprite)
		# Ændr sprite.scale og size for at ændre på størrelsen af boards
		# Sæt til 1.0 hvis du ikke vil ændre den
		size = sprite.texture.get_size()*sprite_scale
		sprite.scale *= sprite_scale
	else:
		print("Sprite path not found")

func _ready() -> void:
	add_to_group("boards")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var mouse := _event_position(event)
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
	elif event is InputEventMouseMotion and dragging:
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			dragging = false
			if get_board_under():
				clip(get_board_under())
			return
		var mouse := _event_position(event)
		var delta := mouse - last_mouse
		last_mouse = mouse
		for b in get_group():
			b.global_position += delta

# Musens position i verdens-koordinater, læst fra selve eventet.
# get_global_mouse_position() læser den rigtige cursor, så falske events
# (fx fra TestBot i !DEBUG) ville ellers ikke kunne trække boards.
func _event_position(event: InputEventMouse) -> Vector2:
	return get_canvas_transform().affine_inverse() * event.position

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
