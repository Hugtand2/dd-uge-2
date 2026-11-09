extends Area2D

signal board_placed(board: Board)   # emitted when a board is dropped on the desk

@onready var shape_node: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("desks")

# Desk rectangle in global space (assumes no rotation)
func get_global_rect() -> Rect2:
	var rect_shape := shape_node.shape as RectangleShape2D
	var s := rect_shape.size * shape_node.global_scale
	return Rect2(shape_node.global_position - s / 2.0, s)

# Called by Board._drop()
func board_dropped(board: Board) -> void:
	var over := get_global_rect().has_point(board.get_global_rect().get_center())
	if over:
		board_placed.emit(board)
	board.on_desk = over

# offset is measured from the desk's center to the new board's center
func spawn_board(board_texture_path: String, offset: Vector2, board_scale := 1.0) -> Board:
	var new_board := Board.new(board_texture_path, board_scale)
	get_parent().add_child(new_board)     # same parent as other boards, so stacking works
	var center := get_global_rect().get_center() + offset
	new_board.global_position = center - new_board.size / 2.0
	# Only counts as "on the desk" if it actually landed on it
	new_board.on_desk = get_global_rect().has_point(center)
	return new_board
