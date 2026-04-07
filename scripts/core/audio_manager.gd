extends Node
class_name AudioManager

const SFX := {
	"shoot": preload("res://audio/sfx/shoot.wav"),
	"hit": preload("res://audio/sfx/hit.wav"),
	"pickup": preload("res://audio/sfx/pickup.wav"),
	"level_up": preload("res://audio/sfx/level_up.wav"),
	"hurt": preload("res://audio/sfx/hurt.wav"),
	"enemy_die": preload("res://audio/sfx/enemy_die.wav"),
	"elite_spawn": preload("res://audio/sfx/elite_spawn.wav"),
	"boss_spawn": preload("res://audio/sfx/boss_spawn.wav"),
	"victory": preload("res://audio/sfx/victory.wav"),
	"defeat": preload("res://audio/sfx/defeat.wav")
}


func play_sfx(name: String, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	var stream: AudioStream = SFX.get(name) as AudioStream
	if stream == null:
		return

	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = stream
	player.pitch_scale = pitch_scale
	player.volume_db = volume_db
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
