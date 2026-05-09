extends Control
class_name BranchSelectPanel

signal branch_selected(index: int)

const ORBIT_SLOT_COUNT := 8
const ORBIT_BUTTON_SIZE := Vector2(192.0, 72.0)
const DEFAULT_GAME_TITLE := "青墟问道"
const PRIMARY_BRANCH_SLOTS := [1, 3, 6]

var _buttons: Array[Button] = []
var _branches: Array[Dictionary] = []
var _display_branches: Array[Dictionary] = []
var _detail_tween: Tween
var _active_detail_key := ""

@onready var title_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/SubTitleLabel
@onready var panel: PanelContainer = $CenterContainer/Panel
@onready var backdrop: ColorRect = $Backdrop
@onready var dial_area: Control = $CenterContainer/Panel/MarginContainer/VBoxContainer/DialArea
@onready var detail_panel: PanelContainer = $CenterContainer/Panel/MarginContainer/VBoxContainer/DialArea/CenterInfoPanel
@onready var detail_title_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/DialArea/CenterInfoPanel/MarginContainer/VBoxContainer/DetailTitleLabel
@onready var detail_summary_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/DialArea/CenterInfoPanel/MarginContainer/VBoxContainer/DetailSummaryLabel
@onready var detail_description_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/DialArea/CenterInfoPanel/MarginContainer/VBoxContainer/DetailDescriptionLabel
@onready var detail_hint_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/DialArea/CenterInfoPanel/MarginContainer/VBoxContainer/DetailHintLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	hide()
	InkUIStyle.apply_screen_panel(panel)
	InkUIStyle.apply_dial_center_panel(detail_panel)
	subtitle_label.visible = false
	InkUIStyle.apply_label_colors(title_label)
	InkUIStyle.apply_label_colors(detail_title_label, detail_summary_label)
	InkUIStyle.apply_label_colors(detail_description_label, detail_hint_label)
	backdrop.color = Color(0.01, 0.015, 0.014, 0.48)
	detail_panel.scale = Vector2.ONE
	_configure_center_text_bounds()
	_buttons = [
		$CenterContainer/Panel/MarginContainer/VBoxContainer/DialArea/OptionA,
		$CenterContainer/Panel/MarginContainer/VBoxContainer/DialArea/OptionB,
		$CenterContainer/Panel/MarginContainer/VBoxContainer/DialArea/OptionC
	]
	for index in range(_buttons.size()):
		_bind_button(_buttons[index], index)


func present(branches: Array[Dictionary]) -> void:
	_branches = branches.duplicate(true)
	_display_branches = _build_display_branches(_branches)
	title_label.text = "选择本局主分支"
	subtitle_label.text = ""
	show()
	_active_detail_key = ""
	_ensure_button_count(_display_branches.size())
	for index in range(_buttons.size()):
		var button: Button = _buttons[index]
		if index >= _display_branches.size():
			button.visible = false
			button.disabled = true
			continue
		var branch: Dictionary = _display_branches[index]
		button.visible = true
		button.disabled = false
		button.custom_minimum_size = ORBIT_BUTTON_SIZE
		button.size = ORBIT_BUTTON_SIZE
		button.text = String(branch.get("name", ""))
		button.tooltip_text = ""
		button.set_meta("branch_index", int(branch.get("source_index", -1)))
		InkUIStyle.apply_orbit_button(button, Color(branch.get("accent_color", Color(0.78, 0.68, 0.46, 1.0))))
	_show_default_details(false)
	call_deferred("_layout_branch_buttons")


func hide_panel() -> void:
	hide()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_layout_branch_buttons()
		detail_panel.pivot_offset = detail_panel.size * 0.5


func _ensure_button_count(required_count: int) -> void:
	while _buttons.size() < required_count:
		var button := Button.new()
		button.name = "Option%s" % str(_buttons.size() + 1)
		dial_area.add_child(button)
		_bind_button(button, _buttons.size())
		_buttons.append(button)


func _bind_button(button: Button, index: int) -> void:
	button.custom_minimum_size = ORBIT_BUTTON_SIZE
	button.size = ORBIT_BUTTON_SIZE
	button.tooltip_text = ""
	button.mouse_entered.connect(_show_branch_details.bind(index))
	button.mouse_exited.connect(_restore_default_details_deferred)
	button.focus_entered.connect(_show_branch_details.bind(index))
	button.focus_exited.connect(_restore_default_details_deferred)
	button.pressed.connect(_on_button_pressed.bind(index))


func _layout_branch_buttons() -> void:
	if dial_area == null or _display_branches.is_empty():
		return
	var visible_count: int = min(_display_branches.size(), _buttons.size())
	var center := dial_area.size * 0.5
	var radius := minf(dial_area.size.x, dial_area.size.y) * 0.49
	for index in range(visible_count):
		var angle := -PI / 2.0 + TAU * float(index) / float(visible_count)
		var button: Button = _buttons[index]
		button.size = ORBIT_BUTTON_SIZE
		button.pivot_offset = ORBIT_BUTTON_SIZE * 0.5
		button.position = center + Vector2(cos(angle), sin(angle)) * radius - ORBIT_BUTTON_SIZE * 0.5
		button.rotation = _orbit_button_rotation(angle)


func _show_branch_details(index: int) -> void:
	if index < 0 or index >= _display_branches.size():
		return
	var branch: Dictionary = _display_branches[index]
	_set_center_content(
		"branch_%d" % index,
		String(branch.get("name", "")),
		String(branch.get("summary", "")),
		String(branch.get("description", "")),
		"点击外圈牌签确定本局方向"
	)


func _restore_default_details_deferred() -> void:
	call_deferred("_restore_default_details_if_idle")


func _restore_default_details_if_idle() -> void:
	var mouse_position := get_viewport().get_mouse_position()
	for button in _buttons:
		if button.visible and button.get_global_rect().has_point(mouse_position):
			return
	_show_default_details()


func _show_default_details(animated: bool = true) -> void:
	var game_title := String(ProjectSettings.get_setting("application/config/name", DEFAULT_GAME_TITLE))
	if game_title.is_empty():
		game_title = DEFAULT_GAME_TITLE
	_set_center_content(
		"default",
		game_title,
		"",
		"",
		"",
		animated
	)


func _set_center_content(key: String, title: String, summary: String, description: String, hint: String, animated: bool = true) -> void:
	if _active_detail_key == key:
		return
	_active_detail_key = key
	if _detail_tween != null:
		_detail_tween.kill()
		_detail_tween = null
	if not animated:
		_apply_center_text(title, summary, description, hint)
		detail_panel.modulate.a = 1.0
		detail_panel.scale = Vector2.ONE
		return
	_detail_tween = create_tween()
	_detail_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_detail_tween.set_trans(Tween.TRANS_SINE)
	_detail_tween.set_ease(Tween.EASE_OUT)
	_detail_tween.tween_property(detail_panel, "modulate:a", 0.0, 0.08)
	_detail_tween.parallel().tween_property(detail_panel, "scale", Vector2(0.98, 0.98), 0.08)
	_detail_tween.tween_callback(Callable(self, "_apply_center_text").bind(title, summary, description, hint))
	_detail_tween.tween_property(detail_panel, "modulate:a", 1.0, 0.16)
	_detail_tween.parallel().tween_property(detail_panel, "scale", Vector2.ONE, 0.16)


func _apply_center_text(title: String, summary: String, description: String, hint: String) -> void:
	detail_title_label.text = title
	detail_summary_label.text = ""
	var body_text := description
	if not summary.is_empty() and not description.is_empty():
		body_text = "%s\n%s" % [summary, description]
	elif not summary.is_empty():
		body_text = summary
	detail_description_label.text = body_text
	detail_description_label.visible = not body_text.is_empty()
	detail_hint_label.text = ""


func _configure_center_text_bounds() -> void:
	detail_summary_label.visible = false
	detail_hint_label.visible = false
	for label in [detail_description_label]:
		label.clip_text = true
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	detail_title_label.clip_text = true
	detail_title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	detail_description_label.max_lines_visible = 4


func _orbit_button_rotation(angle: float) -> float:
	return angle + PI * 0.5


func _build_display_branches(source_branches: Array[Dictionary]) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	for slot in range(ORBIT_SLOT_COUNT):
		items.append(_make_locked_branch(slot))

	var source_index := 0
	for slot in PRIMARY_BRANCH_SLOTS:
		if source_index >= source_branches.size():
			break
		items[slot] = _make_source_branch(source_branches[source_index], source_index)
		source_index += 1

	for slot in range(ORBIT_SLOT_COUNT):
		if source_index >= source_branches.size():
			break
		if int(Dictionary(items[slot]).get("source_index", -1)) >= 0:
			continue
		items[slot] = _make_source_branch(source_branches[source_index], source_index)
		source_index += 1
	return items


func _make_source_branch(branch_data: Dictionary, source_index: int) -> Dictionary:
	var branch := branch_data.duplicate(true)
	branch["source_index"] = source_index
	return branch


func _make_locked_branch(slot: int) -> Dictionary:
	return {
			"id": "locked_%d" % slot,
			"name": "流派待开发",
			"summary": "此方向尚未开放",
			"description": "后续可以在这里接入新的流派玩法、专属升级池和开局被动。",
			"accent_color": Color(0.56, 0.74, 0.7, 1.0),
			"source_index": -1
		}


func _on_button_pressed(index: int) -> void:
	if index < 0 or index >= _display_branches.size():
		return
	var source_index := int(_display_branches[index].get("source_index", -1))
	if source_index < 0:
		_show_branch_details(index)
		return
	branch_selected.emit(source_index)
