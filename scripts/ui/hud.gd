extends Control
class_name HUD

signal mobile_move_changed(direction: Vector2)
signal mobile_skill_pressed
signal pause_resume_requested
signal pause_settings_requested
signal pause_main_menu_requested

const MOBILE_JOYSTICK_SIZE := 148.0
const MOBILE_JOYSTICK_RADIUS := 56.0
const MOBILE_JOYSTICK_KNOB_SIZE := 54.0
const MOBILE_JOYSTICK_DEAD_ZONE := 0.16
const MOBILE_SKILL_SIZE := 96.0
const MOBILE_EDGE_MARGIN := 34.0

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
@onready var hud_content: VBoxContainer = $MarginContainer/Content
@onready var bottom_row: HBoxContainer = $MarginContainer/Content/BottomRow
@onready var build_label: Label = $MarginContainer/Content/BottomRow/BuildPanel/BuildLabel
@onready var event_label: Label = $EventLabel
@onready var boss_panel: Control = $BossPanel
@onready var boss_name_label: Label = $BossPanel/MarginContainer/VBoxContainer/BossName
@onready var boss_bar: ProgressBar = $BossPanel/MarginContainer/VBoxContainer/BossHealth
@onready var pause_dim: ColorRect = $PauseDim
@onready var pause_label: Label = $PauseLabel
@onready var pause_panel: PanelContainer = $PausePanel
@onready var pause_title_label: Label = $PausePanel/MarginContainer/VBoxContainer/TitleLabel
@onready var pause_stats_label: Label = $PausePanel/MarginContainer/VBoxContainer/StatsLabel
@onready var pause_build_label: Label = $PausePanel/MarginContainer/VBoxContainer/BuildLabel
@onready var pause_resume_button: Button = $PausePanel/MarginContainer/VBoxContainer/ButtonBox/ResumeButton
@onready var pause_settings_button: Button = $PausePanel/MarginContainer/VBoxContainer/ButtonBox/SettingsButton
@onready var pause_main_menu_button: Button = $PausePanel/MarginContainer/VBoxContainer/ButtonBox/MainMenuButton

var _event_time_left := 0.0
var _boss_spawn_time := 390.0
var _boss_objective_active := false
var _timer_target_enabled := true
var _mobile_controls_supported := false
var _mobile_controls_active := false
var _mobile_touch_index := -1
var _mobile_mouse_dragging := false
var _mobile_move_direction := Vector2.ZERO
var _mobile_layer: Control
var _mobile_joystick: Control
var _mobile_joystick_knob: Panel
var _mobile_skill_button: Button


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
	pause_dim.visible = false
	pause_panel.visible = false
	boss_panel.visible = false
	event_label.visible = false
	_configure_pause_button(pause_resume_button)
	_configure_pause_button(pause_settings_button)
	_configure_pause_button(pause_main_menu_button)
	pause_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	pause_label.visible = false
	pause_title_label.visible = false
	pause_stats_label.visible = false
	pause_build_label.visible = false
	pause_resume_button.pressed.connect(func() -> void: pause_resume_requested.emit())
	pause_settings_button.pressed.connect(func() -> void: pause_settings_requested.emit())
	pause_main_menu_button.pressed.connect(func() -> void: pause_main_menu_requested.emit())
	objective_label.text = "目标：撑到首领降临"
	_mobile_controls_supported = _should_show_mobile_controls()
	_build_mobile_controls()
	_update_mobile_controls_visibility()


func _process(delta: float) -> void:
	if _event_time_left <= 0.0:
		return
	_event_time_left = maxf(_event_time_left - delta, 0.0)
	if _event_time_left <= 0.0:
		event_label.visible = false


func _input(event: InputEvent) -> void:
	if not _mobile_controls_active or _mobile_layer == null or not _mobile_layer.visible:
		return
	if event is InputEventScreenTouch:
		_handle_mobile_screen_touch(event)
	elif event is InputEventScreenDrag:
		_handle_mobile_screen_drag(event)
	elif event is InputEventMouseButton:
		_handle_mobile_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mobile_mouse_motion(event)


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
	if not _timer_target_enabled:
		timer_label.text = "%02d:%02d" % [minutes, remainder]
		return
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
	_timer_target_enabled = true
	objective_label.text = "目标 等待首领"


func set_timer_target_enabled(enabled: bool) -> void:
	_timer_target_enabled = enabled
	if not enabled:
		_boss_objective_active = false


func set_boss_objective_active(active: bool, objective_text: String = "目标：击败余烬监工") -> void:
	_boss_objective_active = active
	objective_label.text = objective_text


func set_pause_state(is_paused: bool, title_text: String = "", detail_lines: Array[String] = [], build_summary: String = "") -> void:
	vignette.visible = not is_paused
	hud_content.visible = not is_paused
	pause_dim.visible = is_paused
	pause_label.visible = false
	pause_panel.visible = is_paused
	if not is_paused:
		return
	pause_title_label.text = title_text if not title_text.is_empty() else "当前角色"
	pause_stats_label.text = "\n".join(detail_lines)
	if build_summary.is_empty():
		pause_build_label.text = ""
	else:
		pause_build_label.text = "构筑: %s" % build_summary
	pause_resume_button.grab_focus()


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


func set_mobile_controls_active(active: bool) -> void:
	_mobile_controls_active = active
	_update_mobile_controls_visibility()
	if not active:
		_reset_mobile_joystick()


func _configure_pause_button(button: Button) -> void:
	button.custom_minimum_size = Vector2(240.0, 46.0)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	InkUIStyle.apply_character_button(button, Color(0.82, 0.69, 0.36, 1.0))
	button.focus_mode = Control.FOCUS_ALL


func _should_show_mobile_controls() -> bool:
	return OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()


func _build_mobile_controls() -> void:
	_mobile_layer = Control.new()
	_mobile_layer.name = "MobileControls"
	_mobile_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_mobile_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mobile_layer.z_index = 80
	add_child(_mobile_layer)

	_mobile_joystick = Control.new()
	_mobile_joystick.name = "MoveJoystick"
	_mobile_joystick.anchor_left = 0.0
	_mobile_joystick.anchor_top = 1.0
	_mobile_joystick.anchor_right = 0.0
	_mobile_joystick.anchor_bottom = 1.0
	_mobile_joystick.offset_left = MOBILE_EDGE_MARGIN
	_mobile_joystick.offset_top = -MOBILE_EDGE_MARGIN - MOBILE_JOYSTICK_SIZE
	_mobile_joystick.offset_right = MOBILE_EDGE_MARGIN + MOBILE_JOYSTICK_SIZE
	_mobile_joystick.offset_bottom = -MOBILE_EDGE_MARGIN
	_mobile_joystick.mouse_filter = Control.MOUSE_FILTER_STOP
	_mobile_layer.add_child(_mobile_joystick)

	var joystick_base := Panel.new()
	joystick_base.name = "Base"
	joystick_base.set_anchors_preset(Control.PRESET_FULL_RECT)
	joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick_base.add_theme_stylebox_override("panel", _make_circle_style(Color(0.04, 0.08, 0.06, 0.42), 2, Color(0.82, 0.94, 0.82, 0.34), int(MOBILE_JOYSTICK_SIZE * 0.5)))
	_mobile_joystick.add_child(joystick_base)

	_mobile_joystick_knob = Panel.new()
	_mobile_joystick_knob.name = "Knob"
	_mobile_joystick_knob.custom_minimum_size = Vector2(MOBILE_JOYSTICK_KNOB_SIZE, MOBILE_JOYSTICK_KNOB_SIZE)
	_mobile_joystick_knob.size = Vector2(MOBILE_JOYSTICK_KNOB_SIZE, MOBILE_JOYSTICK_KNOB_SIZE)
	_mobile_joystick_knob.position = _joystick_knob_rest_position()
	_mobile_joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mobile_joystick_knob.add_theme_stylebox_override("panel", _make_circle_style(Color(0.62, 0.84, 0.68, 0.66), 2, Color(0.93, 1.0, 0.9, 0.58), int(MOBILE_JOYSTICK_KNOB_SIZE * 0.5)))
	_mobile_joystick.add_child(_mobile_joystick_knob)

	_mobile_skill_button = Button.new()
	_mobile_skill_button.name = "MobileSkillButton"
	_mobile_skill_button.text = "技能"
	_mobile_skill_button.anchor_left = 1.0
	_mobile_skill_button.anchor_top = 1.0
	_mobile_skill_button.anchor_right = 1.0
	_mobile_skill_button.anchor_bottom = 1.0
	_mobile_skill_button.offset_left = -MOBILE_EDGE_MARGIN - MOBILE_SKILL_SIZE
	_mobile_skill_button.offset_top = -MOBILE_EDGE_MARGIN - MOBILE_SKILL_SIZE
	_mobile_skill_button.offset_right = -MOBILE_EDGE_MARGIN
	_mobile_skill_button.offset_bottom = -MOBILE_EDGE_MARGIN
	_mobile_skill_button.focus_mode = Control.FOCUS_NONE
	_mobile_skill_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_mobile_skill_button.add_theme_font_size_override("font_size", 22)
	_mobile_skill_button.add_theme_color_override("font_color", Color(0.94, 1.0, 0.92, 1.0))
	_mobile_skill_button.add_theme_color_override("font_pressed_color", Color(1.0, 0.96, 0.72, 1.0))
	_mobile_skill_button.add_theme_stylebox_override("normal", _make_circle_style(Color(0.13, 0.18, 0.12, 0.64), 2, Color(0.86, 0.96, 0.76, 0.52), int(MOBILE_SKILL_SIZE * 0.5)))
	_mobile_skill_button.add_theme_stylebox_override("hover", _make_circle_style(Color(0.16, 0.22, 0.14, 0.74), 2, Color(0.94, 1.0, 0.82, 0.64), int(MOBILE_SKILL_SIZE * 0.5)))
	_mobile_skill_button.add_theme_stylebox_override("pressed", _make_circle_style(Color(0.24, 0.28, 0.16, 0.82), 2, Color(1.0, 0.9, 0.5, 0.78), int(MOBILE_SKILL_SIZE * 0.5)))
	_mobile_skill_button.pressed.connect(_on_mobile_skill_button_pressed)
	_mobile_layer.add_child(_mobile_skill_button)


func _update_mobile_controls_visibility() -> void:
	if _mobile_layer == null:
		return
	var should_show := _mobile_controls_supported and _mobile_controls_active
	_mobile_layer.visible = should_show
	if _mobile_skill_button != null:
		_mobile_skill_button.disabled = not should_show


func _make_circle_style(fill_color: Color, border_width: int, border_color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	return style


func _handle_mobile_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _mobile_touch_index == -1 and _mobile_joystick.get_global_rect().has_point(event.position):
			_mobile_touch_index = event.index
			_update_mobile_joystick(event.position)
			get_viewport().set_input_as_handled()
	elif event.index == _mobile_touch_index:
		_mobile_touch_index = -1
		_reset_mobile_joystick()
		get_viewport().set_input_as_handled()


func _handle_mobile_screen_drag(event: InputEventScreenDrag) -> void:
	if event.index != _mobile_touch_index:
		return
	_update_mobile_joystick(event.position)
	get_viewport().set_input_as_handled()


func _handle_mobile_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed and _mobile_joystick.get_global_rect().has_point(event.position):
		_mobile_mouse_dragging = true
		_update_mobile_joystick(event.position)
		get_viewport().set_input_as_handled()
	elif not event.pressed and _mobile_mouse_dragging:
		_mobile_mouse_dragging = false
		_reset_mobile_joystick()
		get_viewport().set_input_as_handled()


func _handle_mobile_mouse_motion(event: InputEventMouseMotion) -> void:
	if not _mobile_mouse_dragging:
		return
	_update_mobile_joystick(event.position)
	get_viewport().set_input_as_handled()


func _update_mobile_joystick(screen_position: Vector2) -> void:
	var center := _mobile_joystick.get_global_rect().get_center()
	var offset := (screen_position - center).limit_length(MOBILE_JOYSTICK_RADIUS)
	_mobile_joystick_knob.position = _joystick_knob_rest_position() + offset
	var direction := offset / MOBILE_JOYSTICK_RADIUS
	if direction.length() < MOBILE_JOYSTICK_DEAD_ZONE:
		direction = Vector2.ZERO
	_set_mobile_move_direction(direction)


func _reset_mobile_joystick() -> void:
	_mobile_touch_index = -1
	_mobile_mouse_dragging = false
	if _mobile_joystick_knob != null:
		_mobile_joystick_knob.position = _joystick_knob_rest_position()
	_set_mobile_move_direction(Vector2.ZERO, true)


func _set_mobile_move_direction(direction: Vector2, force_emit: bool = false) -> void:
	var resolved_direction := direction
	if resolved_direction.length() > 1.0:
		resolved_direction = resolved_direction.normalized()
	if not force_emit and _mobile_move_direction.distance_to(resolved_direction) < 0.01:
		return
	_mobile_move_direction = resolved_direction
	mobile_move_changed.emit(_mobile_move_direction)


func _joystick_knob_rest_position() -> Vector2:
	return Vector2.ONE * ((MOBILE_JOYSTICK_SIZE - MOBILE_JOYSTICK_KNOB_SIZE) * 0.5)


func _on_mobile_skill_button_pressed() -> void:
	if not _mobile_controls_active:
		return
	mobile_skill_pressed.emit()
