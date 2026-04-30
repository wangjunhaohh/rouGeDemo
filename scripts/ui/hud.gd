extends Control
class_name HUD

@onready var vignette: TextureRect = $Vignette
@onready var top_frame: TextureRect = $TopFrame
@onready var bottom_frame: TextureRect = $BottomFrame
@onready var stage_label: Label = $MarginContainer/Content/TopRow/StatsColumn/StageLabel
@onready var health_bar: ProgressBar = $MarginContainer/Content/TopRow/StatsColumn/HealthBar
@onready var experience_bar: ProgressBar = $MarginContainer/Content/TopRow/StatsColumn/ExperienceRow/ExperienceBar
@onready var health_label: Label = $MarginContainer/Content/TopRow/StatsColumn/HealthLabel
@onready var level_label: Label = $MarginContainer/Content/TopRow/LevelPanel/LevelLabel
@onready var timer_label: Label = $MarginContainer/Content/TopRow/LevelPanel/TimerLabel
@onready var kill_label: Label = $MarginContainer/Content/TopRow/LevelPanel/KillLabel
@onready var skill_label: Label = $MarginContainer/Content/TopRow/LevelPanel/SkillLabel
@onready var objective_label: Label = $MarginContainer/Content/TopRow/LevelPanel/ObjectiveLabel
@onready var bottom_row: HBoxContainer = $MarginContainer/Content/BottomRow
@onready var build_label: Label = $MarginContainer/Content/BottomRow/BuildPanel/BuildLabel
@onready var event_label: Label = $EventLabel
@onready var boss_panel: Control = $BossPanel
@onready var boss_name_label: Label = $BossPanel/MarginContainer/VBoxContainer/BossName
@onready var boss_bar: ProgressBar = $BossPanel/MarginContainer/VBoxContainer/BossHealth
@onready var pause_label: Label = $PauseLabel
@onready var pause_panel: PanelContainer = $PausePanel
@onready var pause_title_label: Label = $PausePanel/MarginContainer/VBoxContainer/TitleLabel
@onready var pause_stats_label: Label = $PausePanel/MarginContainer/VBoxContainer/StatsLabel
@onready var pause_build_label: Label = $PausePanel/MarginContainer/VBoxContainer/BuildLabel

var _event_time_left := 0.0
var _boss_spawn_time := 390.0
var _boss_objective_active := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if vignette.texture == null:
		vignette.texture = load("res://art/backgrounds/vignette.png") as Texture2D
	vignette.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	top_frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bottom_frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	top_frame.visible = false
	bottom_frame.visible = false
	health_label.visible = false
	health_bar.visible = false
	bottom_row.visible = false
	pause_panel.visible = false
	boss_panel.visible = false
	event_label.visible = false
	objective_label.text = "目标：撑到首领降临"


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
	level_label.text = "Lv %d" % level


func set_elapsed_time(seconds: float) -> void:
	var total_seconds: int = int(seconds)
	var minutes: int = total_seconds / 60
	var remainder: int = total_seconds % 60
	if _boss_objective_active:
		timer_label.text = "%02d:%02d / 首领战" % [minutes, remainder]
		return
	var target_seconds: int = int(_boss_spawn_time)
	var target_minutes: int = target_seconds / 60
	var target_remainder: int = target_seconds % 60
	timer_label.text = "%02d:%02d / %02d:%02d" % [minutes, remainder, target_minutes, target_remainder]


func set_kills(total_kills: int) -> void:
	kill_label.text = "击败 %d" % total_kills


func set_skill_status(skill_name: String, cooldown_left: float, cooldown_total: float) -> void:
	if skill_name.is_empty():
		skill_label.text = "技能 未选择"
		return
	if cooldown_left <= 0.0:
		skill_label.text = "技能 就绪"
		return
	var remaining_seconds := int(ceilf(cooldown_left))
	var total_seconds := int(ceilf(cooldown_total))
	skill_label.text = "技能 %ds / %ds" % [remaining_seconds, total_seconds]


func set_build_text(summary: String) -> void:
	build_label.text = "构筑: %s" % summary


func set_stage_text(stage_index: int, stage_name: String) -> void:
	stage_label.text = "阶段 %d %s" % [stage_index, stage_name]


func set_objective_text(text: String) -> void:
	objective_label.text = text


func configure_boss_goal(spawn_time: float) -> void:
	_boss_spawn_time = spawn_time
	_boss_objective_active = false
	objective_label.text = "目标 等待首领"


func set_boss_objective_active(active: bool, objective_text: String = "目标：击败余烬监工") -> void:
	_boss_objective_active = active
	objective_label.text = objective_text


func set_pause_state(is_paused: bool, title_text: String = "", detail_lines: Array[String] = [], build_summary: String = "") -> void:
	pause_label.visible = is_paused
	pause_panel.visible = is_paused
	if not is_paused:
		return
	pause_title_label.text = title_text if not title_text.is_empty() else "当前角色"
	pause_stats_label.text = "\n".join(detail_lines)
	if build_summary.is_empty():
		pause_build_label.text = ""
	else:
		pause_build_label.text = "构筑: %s" % build_summary


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
