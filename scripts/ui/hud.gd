extends Control
class_name HUD

@onready var vignette: TextureRect = $Vignette
@onready var health_bar: ProgressBar = $MarginContainer/Content/TopRow/StatsColumn/HealthBar
@onready var experience_bar: ProgressBar = $MarginContainer/Content/TopRow/StatsColumn/ExperienceBar
@onready var health_label: Label = $MarginContainer/Content/TopRow/StatsColumn/HealthLabel
@onready var level_label: Label = $MarginContainer/Content/TopRow/LevelPanel/LevelLabel
@onready var timer_label: Label = $MarginContainer/Content/TopRow/LevelPanel/TimerLabel
@onready var kill_label: Label = $MarginContainer/Content/TopRow/LevelPanel/KillLabel
@onready var build_label: Label = $MarginContainer/Content/BottomRow/BuildPanel/BuildLabel
@onready var event_label: Label = $EventLabel
@onready var boss_panel: Control = $BossPanel
@onready var boss_name_label: Label = $BossPanel/MarginContainer/VBoxContainer/BossName
@onready var boss_bar: ProgressBar = $BossPanel/MarginContainer/VBoxContainer/BossHealth
@onready var pause_label: Label = $PauseLabel

var _event_time_left := 0.0


func _ready() -> void:
	if vignette.texture == null:
		vignette.texture = load("res://art/backgrounds/vignette.png") as Texture2D
	vignette.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	boss_panel.visible = false
	event_label.visible = false


func _process(delta: float) -> void:
	if _event_time_left <= 0.0:
		return
	_event_time_left = maxf(_event_time_left - delta, 0.0)
	if _event_time_left <= 0.0:
		event_label.visible = false


func set_health(current_value: float, max_value: float) -> void:
	health_bar.max_value = max_value
	health_bar.value = current_value
	health_label.text = "生命 %.0f / %.0f" % [current_value, max_value]


func set_experience(current_value: float, max_value: float, level: int) -> void:
	experience_bar.max_value = max_value
	experience_bar.value = current_value
	level_label.text = "等级 %d" % level


func set_elapsed_time(seconds: float) -> void:
	var total_seconds: int = int(seconds)
	var minutes: int = total_seconds / 60
	var remainder: int = total_seconds % 60
	timer_label.text = "时间 %02d:%02d / 10:00" % [minutes, remainder]


func set_kills(total_kills: int) -> void:
	kill_label.text = "击败 %d" % total_kills


func set_build_text(summary: String) -> void:
	build_label.text = "构筑: %s" % summary


func set_pause_state(is_paused: bool) -> void:
	pause_label.visible = is_paused


func show_event(text: String, duration: float = 2.0) -> void:
	event_label.text = text
	event_label.visible = true
	_event_time_left = duration


func show_boss(name_text: String, current_value: float, max_value: float) -> void:
	boss_panel.visible = true
	boss_name_label.text = name_text
	boss_bar.max_value = max_value
	boss_bar.value = current_value


func hide_boss() -> void:
	boss_panel.visible = false
