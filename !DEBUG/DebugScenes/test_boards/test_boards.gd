extends Node2D

var amount = 3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	MusicPlayer.play_custom_track("res://Resources/Audio/Music/Theme For Ernie (Remastered 2026) (320kbps).mp3")
	
	for b in amount:
		add_child(Board.new("res://Resources/UIAssets/Alien.png"))
