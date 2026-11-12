extends Node2D

const BOARD_PATH := "res://Resources/UIAssets/Alien.png"

@onready var desk: Area2D = $Desk
@onready var spawn_button: Button = $CanvasLayer/SpawnButton

var spawn_count := 0

func _ready() -> void:
	desk.board_placed.connect(_on_board_placed)
	spawn_button.pressed.connect(_on_spawn_pressed)

func _on_board_placed(_board: Board) -> void:
	print("board dropped")

func _on_spawn_pressed() -> void:
	# Spawns below the desk so you can drag it up onto it
	spawn_count += 1
	var offset := Vector2(spawn_count * 40, 300)
	desk.spawn_board(BOARD_PATH, offset, 1.0)
