extends Control
class_name StartMenuPanel

const BUTTON_NORMAL_TEXTURE := preload("res://art/ui/start_menu_button_ink_normal.png")
const BUTTON_HOVER_WASH_TEXTURE := preload("res://art/ui/start_menu_button_ink_hover.png")

const BASE_TEXT_COLOR := Color(0.18, 0.15, 0.1, 0.96)
const ACTIVE_TEXT_COLOR := Color(0.08, 0.19, 0.16, 1.0)
const PRESSED_TEXT_COLOR := Color(0.28, 0.18, 0.12, 1.0)

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
	buttons_center.custom_minimum_size = Vector2(560.0, 330.0)
	button_box.custom_minimum_size = Vector2(390.0, 0.0)
	button_box.add_theme_constant_override("separation", 28)

	title_label.visible = true
	title_label.custom_minimum_size = Vector2(0.0, 104.0)
	InkUIStyle.apply_ink_heading(title_label, 76, Color(0.17, 0.15, 0.12, 1.0))
	title_label.add_theme_color_override("font_shadow_color", Color(0.96, 0.92, 0.78, 0.86))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	subtitle_label.visible = true
	subtitle_label.custom_minimum_size = Vector2(0.0, 48.0)
	subtitle_label.add_theme_font_override("font", InkUIStyle.INK_BRUSH_FONT)
	subtitle_label.add_theme_font_size_override("font_size", 26)
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
	button.custom_minimum_size = Vector2(0.0, 86.0)
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
	var effect := TextureRect.new()
	effect.name = "ButtonInkWash"
	effect.texture = BUTTON_HOVER_WASH_TEXTURE
	effect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	effect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	effect.stretch_mode = TextureRect.STRETCH_SCALE
	effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect.show_behind_parent = true
	effect.anchor_right = 1.0
	effect.anchor_bottom = 1.0
	effect.offset_left = -36.0
	effect.offset_top = -20.0
	effect.offset_right = 36.0
	effect.offset_bottom = 20.0
	effect.modulate = Color(1.0, 1.0, 1.0, 0.0)
	effect.scale = Vector2(0.96, 0.9)
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
	var normal_box := _make_texture_button_box(1.0)
	button.add_theme_stylebox_override("normal", normal_box)
	button.add_theme_stylebox_override("hover", _make_texture_button_box(1.0))
	button.add_theme_stylebox_override("pressed", _make_texture_button_box(0.96))
	button.add_theme_stylebox_override("focus", _make_texture_button_box(1.0))
	button.add_theme_stylebox_override("disabled", _make_texture_button_box(0.58))


func _make_texture_button_box(alpha: float) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = BUTTON_NORMAL_TEXTURE
	box.modulate_color = Color(1.0, 1.0, 1.0, alpha)
	box.content_margin_left = 24.0
	box.content_margin_top = 12.0
	box.content_margin_right = 24.0
	box.content_margin_bottom = 12.0
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

	var effect: TextureRect = _button_effects[button] as TextureRect
	var tween: Tween = _button_tweens.get(button) as Tween
	if tween != null and tween.is_running():
		tween.kill()
	tween = create_tween().set_parallel(true)
	_button_tweens[button] = tween

	match state:
		"pressed":
			tween.tween_property(button, "scale", Vector2(0.98, 0.98), 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.tween_property(effect, "modulate:a", 0.62, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.tween_property(effect, "scale", Vector2(0.98, 0.92), 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		"hover":
			tween.tween_property(button, "scale", Vector2(1.018, 1.018), 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.tween_property(effect, "modulate:a", 0.82, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.tween_property(effect, "scale", Vector2(1.0, 0.98), 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_:
			_reset_button_visual(button)


func _reset_button_visual(button: Button) -> void:
	var effect: TextureRect = _button_effects.get(button) as TextureRect
	if effect == null:
		return
	var tween: Tween = _button_tweens.get(button) as Tween
	if tween != null and tween.is_running():
		tween.kill()
	tween = create_tween().set_parallel(true)
	_button_tweens[button] = tween
	tween.tween_property(button, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(effect, "modulate:a", 0.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(effect, "scale", Vector2(0.96, 0.9), 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


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
		var effect: TextureRect = _button_effects.get(button) as TextureRect
		if effect != null:
			effect.modulate.a = 0.0
			effect.scale = Vector2(0.96, 0.9)

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
