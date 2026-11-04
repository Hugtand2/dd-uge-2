extends TextureButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _pressed() -> void:
	AudioPlayer.play_sound_effect("res://Resources/Audio/SoundEffects/GameObjectSoundEffects/bell_ring.mp3")
	if get_parent().is_serving:
		return
	get_parent().customer_arrive()
