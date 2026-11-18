extends Control

@onready var play_button: TextureButton = $MainMenuPlayButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	play_button.pressed.connect(button_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes&Scripts/main/main.tscn")
	
