extends Control
class_name StartMenuPanel

const BASE_TEXT_COLOR := Color(0.18, 0.15, 0.1, 0.96)
const ACTIVE_TEXT_COLOR := Color(0.08, 0.19, 0.16, 1.0)
const PRESSED_TEXT_COLOR := Color(0.35, 0.13, 0.08, 1.0)
const BUTTON_PANEL_NORMAL := Color(0.96, 0.92, 0.8, 0.62)
const BUTTON_PANEL_HOVER := Color(1.0, 0.97, 0.86, 0.78)
const BUTTON_PANEL_PRESSED := Color(0.82, 0.76, 0.62, 0.82)
const BUTTON_BORDER_NORMAL := Color(0.18, 0.2, 0.17, 0.46)
const BUTTON_BORDER_HOVER := Color(0.18, 0.34, 0.3, 0.72)
const BUTTON_BORDER_PRESSED := Color(0.42, 0.15, 0.08, 0.88)
const BUTTON_WASH_HOVER := Color(0.5, 0.64, 0.58, 0.28)
const BUTTON_WASH_PRESSED := Color(0.2, 0.24, 0.22, 0.26)

signal start_requested
signal settings_requested
signal exit_requested

var _button_effects: Dictionary = {}
var _button_tweens: Dictionary = {}
var _menu_buttons: Array[Button] = []

@onready var frame: PanelContainer = $CenterContainer/Frame
@onready var root_box: VBoxContainer = $CenterContainer/Frame/MarginContainer/VBoxContainer
@onready var buttons_center: CenterContainer = $CenterContainer/Frame/MarginContainer/VBoxContainer/ButtonsCenter
@onready var button_box: VBoxContainer = $CenterContainer/Frame/MarginContainer/VBoxContainer/ButtonsCenter/ButtonBox
@onready var title_label: Label = $CenterContainer/Frame/MarginContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/Frame/MarginContainer/VBoxContainer/SubTitleLabel
@onready var start_button: Button = $CenterContainer/Frame/MarginContainer/VBoxContainer/ButtonsCenter/ButtonBox/StartButton
@onready var settings_button: Button = $CenterContainer/Frame/MarginContainer/VBoxContainer/ButtonsCenter/ButtonBox/SettingsButton
@onready var exit_button: Button = $CenterContainer/Frame/MarginContainer/VBoxContainer/ButtonsCenter/ButtonBox/ExitButton
@onready var hint_label: Label = $CenterContainer/Frame/MarginContainer/VBoxContainer/HintLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	hide()
	_menu_buttons = [start_button, settings_button, exit_button]
	_apply_styles()
	_configure_menu_button(start_button, func() -> void: start_requested.emit())
	_configure_menu_button(settings_button, func() -> void: settings_requested.emit())
	_configure_menu_button(exit_button, func() -> void: exit_requested.emit())


func present(game_title: String) -> void:
	title_label.text = game_title
	subtitle_label.text = "踏入青墟，问剑江湖"
	show()
	_play_intro()
	start_button.grab_focus()


func hide_panel() -> void:
	hide()


func _apply_styles() -> void:
	frame.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	root_box.alignment = BoxContainer.ALIGNMENT_CENTER
	root_box.add_theme_constant_override("separation", 10)
	buttons_center.custom_minimum_size = Vector2(520.0, 320.0)
	button_box.custom_minimum_size = Vector2(360.0, 0.0)
	button_box.add_theme_constant_override("separation", 30)

	title_label.visible = true
	title_label.custom_minimum_size = Vector2(0.0, 92.0)
	InkUIStyle.apply_ink_heading(title_label, 68, Color(0.17, 0.15, 0.12, 1.0))
	title_label.add_theme_color_override("font_shadow_color", Color(0.96, 0.92, 0.78, 0.86))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	subtitle_label.visible = true
	subtitle_label.custom_minimum_size = Vector2(0.0, 42.0)
	subtitle_label.add_theme_font_override("font", InkUIStyle.INK_BRUSH_FONT)
	subtitle_label.add_theme_font_size_override("font_size", 22)
	subtitle_label.add_theme_color_override("font_color", Color(0.22, 0.2, 0.16, 0.88))
	subtitle_label.add_theme_color_override("font_shadow_color", Color(0.96, 0.92, 0.82, 0.76))
	subtitle_label.add_theme_constant_override("shadow_offset_x", 1)
	subtitle_label.add_theme_constant_override("shadow_offset_y", 1)
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	hint_label.visible = false


func _configure_menu_button(button: Button, pressed_action: Callable) -> void:
	button.focus_mode = Control.FOCUS_ALL
	button.flat = false
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.custom_minimum_size = Vector2(0.0, 78.0)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", InkUIStyle.INK_BRUSH_FONT)
	button.add_theme_font_size_override("font_size", 40)
	_apply_font_palette(button)
	_apply_menu_button_style(button)
	_attach_button_effect(button)
	button.pressed.connect(pressed_action)
	button.mouse_entered.connect(_on_button_hovered.bind(button))
	button.focus_entered.connect(_on_button_hovered.bind(button))
	button.focus_exited.connect(_on_button_focus_exited.bind(button))
	button.button_down.connect(_on_button_down.bind(button))
	button.button_up.connect(_on_button_up.bind(button))
	button.resized.connect(_on_button_resized.bind(button))
	_on_button_resized(button)


func _attach_button_effect(button: Button) -> void:
	var effect := Panel.new()
	effect.name = "ButtonInkWash"
	effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect.show_behind_parent = true
	effect.anchor_right = 1.0
	effect.anchor_bottom = 1.0
	effect.offset_left = -14.0
	effect.offset_top = -8.0
	effect.offset_right = 14.0
	effect.offset_bottom = 8.0
	effect.add_theme_stylebox_override("panel", _make_ink_wash_box(BUTTON_WASH_HOVER, Color(0.16, 0.24, 0.22, 0.36), 1))
	effect.modulate = Color(1.0, 1.0, 1.0, 0.0)
	effect.scale = Vector2(0.98, 0.92)
	button.add_child(effect)
	_button_effects[button] = effect


func _apply_font_palette(button: Button) -> void:
	button.add_theme_color_override("font_color", BASE_TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", ACTIVE_TEXT_COLOR)
	button.add_theme_color_override("font_focus_color", ACTIVE_TEXT_COLOR)
	button.add_theme_color_override("font_pressed_color", PRESSED_TEXT_COLOR)
	button.add_theme_color_override("font_shadow_color", Color(0.96, 0.91, 0.76, 0.84))
	button.add_theme_constant_override("shadow_offset_x", 1)
	button.add_theme_constant_override("shadow_offset_y", 1)


func _apply_menu_button_style(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _make_menu_button_box(BUTTON_PANEL_NORMAL, BUTTON_BORDER_NORMAL, 1, 8))
	button.add_theme_stylebox_override("hover", _make_menu_button_box(BUTTON_PANEL_HOVER, BUTTON_BORDER_HOVER, 2, 12))
	button.add_theme_stylebox_override("pressed", _make_menu_button_box(BUTTON_PANEL_PRESSED, BUTTON_BORDER_PRESSED, 2, 6))
	button.add_theme_stylebox_override("focus", _make_menu_button_box(BUTTON_PANEL_HOVER, BUTTON_BORDER_HOVER, 2, 10))
	button.add_theme_stylebox_override("disabled", _make_menu_button_box(Color(0.72, 0.7, 0.63, 0.42), Color(0.18, 0.18, 0.16, 0.26), 1, 0))


func _make_menu_button_box(bg_color: Color, border_color: Color, border_width: int, shadow_size: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg_color
	box.border_color = border_color
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(6)
	box.shadow_color = Color(0.12, 0.1, 0.07, 0.32)
	box.shadow_size = shadow_size
	box.content_margin_left = 24.0
	box.content_margin_top = 12.0
	box.content_margin_right = 24.0
	box.content_margin_bottom = 12.0
	return box


func _make_ink_wash_box(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg_color
	box.border_color = border_color
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(8)
	box.content_margin_left = 8.0
	box.content_margin_top = 6.0
	box.content_margin_right = 8.0
	box.content_margin_bottom = 6.0
	return box


func _on_button_resized(button: Button) -> void:
	button.pivot_offset = button.size * 0.5


func _on_button_hovered(button: Button) -> void:
	if visible and not button.has_focus():
		button.grab_focus()
	_set_button_state(button, "hover")


func _on_button_focus_exited(button: Button) -> void:
	_set_button_state(button, "normal")


func _on_button_down(button: Button) -> void:
	_set_button_state(button, "pressed")


func _on_button_up(button: Button) -> void:
	if button.has_focus() or _is_mouse_over_button(button):
		_set_button_state(button, "hover")
	else:
		_set_button_state(button, "normal")


func _set_button_state(button: Button, state: String) -> void:
	if not _button_effects.has(button):
		return

	for other_button in _menu_buttons:
		if other_button != button and state != "pressed":
			_reset_button_visual(other_button)

	var effect: Panel = _button_effects[button] as Panel
	var tween: Tween = _button_tweens.get(button) as Tween
	if tween != null and tween.is_running():
		tween.kill()
	tween = create_tween().set_parallel(true)
	_button_tweens[button] = tween

	match state:
		"pressed":
			effect.add_theme_stylebox_override("panel", _make_ink_wash_box(BUTTON_WASH_PRESSED, Color(0.18, 0.16, 0.12, 0.42), 1))
			tween.tween_property(button, "scale", Vector2(0.98, 0.98), 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.tween_property(effect, "modulate:a", 0.7, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.tween_property(effect, "scale", Vector2(1.0, 0.94), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		"hover":
			effect.add_theme_stylebox_override("panel", _make_ink_wash_box(BUTTON_WASH_HOVER, Color(0.16, 0.24, 0.22, 0.36), 1))
			tween.tween_property(button, "scale", Vector2(1.024, 1.024), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(effect, "modulate:a", 0.58, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.tween_property(effect, "scale", Vector2(1.0, 0.96), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_:
			_reset_button_visual(button)


func _reset_button_visual(button: Button) -> void:
	var effect: Panel = _button_effects.get(button) as Panel
	if effect == null:
		return
	var tween: Tween = _button_tweens.get(button) as Tween
	if tween != null and tween.is_running():
		tween.kill()
	tween = create_tween().set_parallel(true)
	_button_tweens[button] = tween
	tween.tween_property(button, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(effect, "modulate:a", 0.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(effect, "scale", Vector2(0.98, 0.92), 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _is_mouse_over_button(button: Button) -> bool:
	return button.get_global_rect().has_point(button.get_global_mouse_position())


func _play_intro() -> void:
	title_label.modulate.a = 0.0
	title_label.scale = Vector2(0.96, 0.96)
	subtitle_label.modulate.a = 0.0
	subtitle_label.scale = Vector2(0.98, 0.98)

	for index in range(_menu_buttons.size()):
		var button := _menu_buttons[index]
		button.modulate.a = 0.0
		button.scale = Vector2(0.94, 0.94)
		var effect: Panel = _button_effects.get(button) as Panel
		if effect != null:
			effect.modulate.a = 0.0
			effect.scale = Vector2(0.98, 0.92)

	var intro := create_tween()
	intro.tween_property(title_label, "modulate:a", 1.0, 0.34).set_delay(0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	intro.parallel().tween_property(title_label, "scale", Vector2.ONE, 0.4).set_delay(0.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	intro.parallel().tween_property(subtitle_label, "modulate:a", 1.0, 0.28).set_delay(0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	intro.parallel().tween_property(subtitle_label, "scale", Vector2.ONE, 0.3).set_delay(0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	for index in range(_menu_buttons.size()):
		var button := _menu_buttons[index]
		var delay := 0.18 + index * 0.08
		intro.parallel().tween_property(button, "modulate:a", 1.0, 0.24).set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		intro.parallel().tween_property(button, "scale", Vector2.ONE, 0.28).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
