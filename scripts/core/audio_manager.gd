extends Node
class_name AudioManager

const MASTER_BUS_NAME := "Master"
const SFX_BUS_NAME := "SFX"
const MUSIC_BUS_NAME := "Music"
const MIN_LINEAR_VOLUME := 0.0001

const SFX := {
	"shoot": preload("res://audio/sfx/shoot.wav"),
	"swordsman_attack": preload("res://audio/sfx/swordsman_attack.wav"),
	"mage_attack": preload("res://audio/sfx/mage_attack.wav"),
	"swordsman_skill": preload("res://audio/sfx/swordsman_skill.wav"),
	"mage_skill": preload("res://audio/sfx/mage_skill.wav"),
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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ensure_audio_buses()
	apply_saved_settings()


func play_sfx(name: String, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	var stream: AudioStream = SFX.get(name) as AudioStream
	if stream == null:
		return

	ensure_audio_buses()
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = stream
	player.bus = SFX_BUS_NAME
	player.pitch_scale = pitch_scale
	player.volume_db = volume_db
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


static func load_audio_settings() -> Dictionary:
	return Dictionary(SaveManager.load_settings().get("audio", {})).duplicate(true)


static func save_audio_setting(setting_name: String, linear_value: float) -> Dictionary:
	var settings := SaveManager.load_settings()
	var audio_settings: Dictionary = Dictionary(settings.get("audio", {}))
	audio_settings[setting_name] = clampf(linear_value, 0.0, 1.0)
	settings["audio"] = audio_settings
	SaveManager.save_settings(settings)
	apply_audio_settings(audio_settings)
	return audio_settings.duplicate(true)


static func apply_saved_settings() -> void:
	apply_audio_settings(load_audio_settings())


static func apply_audio_settings(audio_settings: Dictionary) -> void:
	ensure_audio_buses()
	set_bus_volume_linear(MASTER_BUS_NAME, float(audio_settings.get("master_volume", 1.0)))
	set_bus_volume_linear(SFX_BUS_NAME, float(audio_settings.get("sfx_volume", 1.0)))
	set_bus_volume_linear(MUSIC_BUS_NAME, float(audio_settings.get("music_volume", 1.0)))


static func set_bus_volume_linear(bus_name: String, linear_value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return
	var clamped_value := clampf(linear_value, 0.0, 1.0)
	AudioServer.set_bus_mute(bus_index, clamped_value <= 0.001)
	if clamped_value <= 0.001:
		AudioServer.set_bus_volume_db(bus_index, -80.0)
		return
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(clamped_value, MIN_LINEAR_VOLUME)))


static func ensure_audio_buses() -> void:
	_ensure_bus_exists(SFX_BUS_NAME, MASTER_BUS_NAME)
	_ensure_bus_exists(MUSIC_BUS_NAME, MASTER_BUS_NAME)


static func _ensure_bus_exists(bus_name: String, send_bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	var new_index := AudioServer.get_bus_count()
	AudioServer.add_bus(new_index)
	AudioServer.set_bus_name(new_index, bus_name)
	AudioServer.set_bus_send(new_index, send_bus_name)
