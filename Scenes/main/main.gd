extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	MusicPlayer.play_custom_track("res://Resources/Audio/Music/Theme For Ernie (Remastered 2026) (320kbps).mp3")
	pass




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
