class_name Board
extends Node2D

# Skriftstørrelser til tekst på papirer (blanketter, regelbogens sider osv.)
const FONT_SIZE := 12
const TITLE_FONT_SIZE := 16

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
			if not _contains_point(mouse) or _is_covered_at(mouse):
				# Klikket er ved siden af, eller det tilhører et board oven på os
				dragging = false
				return
			if _is_over_control(mouse):
				# Lad klikket gå videre til Control'en (fx LineEdit eller Button)
				dragging = false
				bring_to_front()
				return
			get_viewport().gui_release_focus()
			dragging = true
			last_mouse = mouse
			lift()
			bring_to_front()
			get_viewport().set_input_as_handled()
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

# Ligger der et andet board oven på dette punkt? Så er klikket ikke til os.
# Det øverste board markerer ikke klikket som håndteret, når det rammer en
# Control (ellers får Control'en det aldrig), så boards nedenunder skal selv
# lade være med at reagere.
func _is_covered_at(global_point: Vector2) -> bool:
	for node in get_tree().get_nodes_in_group("boards"):
		var other := node as Board
		if other != null and other != self and other.is_visible_in_tree() 				and other.is_greater_than(self) and other._contains_point(global_point):
			return true
	return false

# Lav en tekst-label til et papir. Den ignorerer musen, så man stadig kan
# trække papiret ved at tage fat i teksten.
func _make_label(text: String, font_size: int = FONT_SIZE) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", Color.BLACK)
	label.add_theme_font_size_override("font_size", font_size)
	return label

# Slå et board helt til eller fra. Et slukket board er usynligt, kan ikke
# klikkes eller trækkes og clipper ikke til andre boards.
# Kald den først, når boardet er i scenetræet (_ready slår det til igen).
func set_enabled(enabled: bool) -> void:
	visible = enabled
	set_process_input(enabled)
	if enabled:
		add_to_group("boards")
	else:
		dragging = false
		for other in clipped.duplicate():
			unclip(other)
		remove_from_group("boards")

# Byt dette board ud med et andet (samme parent): det andet overtager plads,
# lag og clips, og dette board slås fra.
# Bruges fx når regelbogen bladrer til en side og tilbage igen.
func replace_with(other: Board) -> void:
	var neighbours := clipped.duplicate()
	other.global_position = global_position
	set_enabled(false)
	other.set_enabled(true)
	if other.get_parent() == get_parent():
		# Læg det andet board lige oven på dette i tegne-rækkefølgen
		var target := get_index() if other.get_index() < get_index() else get_index() + 1
		get_parent().move_child(other, target)
	for neighbour in neighbours:
		other.clip(neighbour)

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
