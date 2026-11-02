extends AudioStreamPlayer
# Autoload

@onready var music_player: AudioStreamPlayer = self

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	return

var current_track = ""

func stop_music() -> void:
	current_track = ""
	stop()

func play_custom_track(file_path: String) -> void:
	# Checks if track is already playing
	if current_track == file_path and playing:
		return
	current_track = file_path
	
	# Changes track
	stream = load(file_path)
	if stream:
		stream.loop = true
		self.stream = stream
		play()
