extends Control
class_name SettingsPanel

signal back_requested

@onready var panel: PanelContainer = $CenterContainer/Panel
@onready var title_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/SubTitleLabel
@onready var master_slider: HSlider = $CenterContainer/Panel/MarginContainer/VBoxContainer/SettingsList/MasterRow/VolumeSlider
@onready var master_value_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/SettingsList/MasterRow/ValueLabel
@onready var sfx_slider: HSlider = $CenterContainer/Panel/MarginContainer/VBoxContainer/SettingsList/SfxRow/VolumeSlider
@onready var sfx_value_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/SettingsList/SfxRow/ValueLabel
@onready var music_slider: HSlider = $CenterContainer/Panel/MarginContainer/VBoxContainer/SettingsList/MusicRow/VolumeSlider
@onready var music_value_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/SettingsList/MusicRow/ValueLabel
@onready var back_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ButtonRow/BackButton

var _audio_settings: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	hide()
	_apply_styles()
	_configure_slider(master_slider)
	_configure_slider(sfx_slider)
	_configure_slider(music_slider)
	master_slider.value_changed.connect(_on_master_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	music_slider.value_changed.connect(_on_music_slider_changed)
	back_button.pressed.connect(func() -> void: back_requested.emit())


func present() -> void:
	_audio_settings = AudioManager.load_audio_settings()
	_sync_sliders_from_settings()
	show()
	master_slider.grab_focus()


func hide_panel() -> void:
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause_game"):
		get_viewport().set_input_as_handled()
		back_requested.emit()


func _apply_styles() -> void:
	InkUIStyle.apply_detail_panel(panel)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	InkUIStyle.apply_ink_heading(title_label, 36, Color(0.95, 0.87, 0.56, 1.0))
	InkUIStyle.apply_label_colors(subtitle_label)
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 15)
	back_button.custom_minimum_size = Vector2(180.0, 52.0)
	InkUIStyle.apply_character_button(back_button, Color(0.82, 0.69, 0.36, 1.0))

	for label in [
		$CenterContainer/Panel/MarginContainer/VBoxContainer/SettingsList/MasterRow/NameLabel,
		$CenterContainer/Panel/MarginContainer/VBoxContainer/SettingsList/SfxRow/NameLabel,
		$CenterContainer/Panel/MarginContainer/VBoxContainer/SettingsList/MusicRow/NameLabel,
		master_value_label,
		sfx_value_label,
		music_value_label
	]:
		label.add_theme_color_override("font_color", Color(0.94, 0.92, 0.86, 1.0))
		label.add_theme_font_size_override("font_size", 16)


func _configure_slider(slider: HSlider) -> void:
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _sync_sliders_from_settings() -> void:
	var master_value := float(_audio_settings.get("master_volume", 1.0))
	var sfx_value := float(_audio_settings.get("sfx_volume", 1.0))
	var music_value := float(_audio_settings.get("music_volume", 1.0))
	master_slider.set_value_no_signal(master_value)
	sfx_slider.set_value_no_signal(sfx_value)
	music_slider.set_value_no_signal(music_value)
	_refresh_value_labels()


func _on_master_slider_changed(value: float) -> void:
	_update_audio_setting("master_volume", value)


func _on_sfx_slider_changed(value: float) -> void:
	_update_audio_setting("sfx_volume", value)


func _on_music_slider_changed(value: float) -> void:
	_update_audio_setting("music_volume", value)


func _update_audio_setting(setting_key: String, value: float) -> void:
	var clamped_value := snappedf(clampf(value, 0.0, 1.0), 0.01)
	_audio_settings = AudioManager.save_audio_setting(setting_key, clamped_value)
	_refresh_value_labels()


func _refresh_value_labels() -> void:
	master_value_label.text = "%d%%" % int(round(float(_audio_settings.get("master_volume", 1.0)) * 100.0))
	sfx_value_label.text = "%d%%" % int(round(float(_audio_settings.get("sfx_volume", 1.0)) * 100.0))
	music_value_label.text = "%d%%" % int(round(float(_audio_settings.get("music_volume", 1.0)) * 100.0))
