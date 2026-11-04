extends Node
# Autoload

@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var sfx_player: AudioStreamPlayer = $SoundEffectPlayer

func play_sound_effect(file_path: String) -> void:
	var sound := load(file_path) as AudioStream
	if sound == null:
		push_error("Could not load sound: " + file_path)
		return
	sfx_player.stream = sound
	sfx_player.play()

# Forward the music functions so everything goes through one name
func play_custom_track(file_path: String) -> void:
	music_player.play_custom_track(file_path)

func stop_music() -> void:
	music_player.stop_music()
