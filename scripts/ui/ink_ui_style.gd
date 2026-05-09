extends RefCounted
class_name InkUIStyle

const PANEL_BG := Color(0.055, 0.075, 0.074, 0.9)
const PANEL_BORDER := Color(0.18, 0.34, 0.32, 0.42)
const PANEL_INNER_BORDER := Color(0.78, 0.68, 0.46, 0.42)
const CARD_BG := Color(0.07, 0.085, 0.08, 0.86)
const CARD_HOVER_BG := Color(0.1, 0.12, 0.105, 0.94)
const INK_TEXT := Color(0.93, 0.91, 0.84, 1.0)
const MUTED_TEXT := Color(0.72, 0.75, 0.68, 1.0)
const INK_BRUSH_FONT := preload("res://art/fonts/MaShanZheng-Regular.ttf")
const BRANCH_PLAQUE_NORMAL := preload("res://art/ui/branch_plaque.png")
const BRANCH_PLAQUE_HOVER := preload("res://art/ui/branch_plaque_hover.png")
const BRANCH_PLAQUE_PRESSED := preload("res://art/ui/branch_plaque_pressed.png")


static func apply_panel(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", _make_box(PANEL_BG, PANEL_BORDER, 0, 4, 16))


static func apply_screen_panel(panel: PanelContainer) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	box.border_color = Color(0.0, 0.0, 0.0, 0.0)
	box.set_border_width_all(0)
	panel.add_theme_stylebox_override("panel", box)


static func apply_detail_panel(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", _make_box(Color(0.04, 0.06, 0.06, 0.88), PANEL_INNER_BORDER, 1, 4, 8))


static func apply_dial_center_panel(panel: PanelContainer) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	box.border_color = Color(0.0, 0.0, 0.0, 0.0)
	box.set_border_width_all(0)
	box.content_margin_left = 10.0
	box.content_margin_top = 8.0
	box.content_margin_right = 10.0
	box.content_margin_bottom = 8.0
	panel.add_theme_stylebox_override("panel", box)


static func apply_character_button(button: Button, accent: Color = Color(0.78, 0.68, 0.46, 1.0)) -> void:
	_apply_button_base(button, 17)
	button.add_theme_stylebox_override("normal", _make_box(CARD_BG, Color(accent.r, accent.g, accent.b, 0.55), 1, 4, 8))
	button.add_theme_stylebox_override("hover", _make_box(CARD_HOVER_BG, accent, 2, 4, 10))
	button.add_theme_stylebox_override("pressed", _make_box(Color(0.13, 0.1, 0.075, 0.96), accent, 2, 4, 6))


static func apply_orbit_button(button: Button, accent: Color = Color(0.78, 0.68, 0.46, 1.0)) -> void:
	_apply_button_base(button, 18)
	button.add_theme_font_override("font", INK_BRUSH_FONT)
	button.add_theme_stylebox_override("normal", _make_texture_box(BRANCH_PLAQUE_NORMAL))
	button.add_theme_stylebox_override("hover", _make_texture_box(BRANCH_PLAQUE_HOVER))
	button.add_theme_stylebox_override("pressed", _make_texture_box(BRANCH_PLAQUE_PRESSED))
	button.add_theme_color_override("font_color", Color(0.07, 0.14, 0.13, 1.0))
	button.add_theme_color_override("font_hover_color", Color(0.18, 0.08, 0.05, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.35, 0.08, 0.04, 1.0))
	button.add_theme_color_override("font_shadow_color", Color(0.92, 0.96, 0.87, 0.62))
	button.add_theme_constant_override("shadow_offset_x", 1)
	button.add_theme_constant_override("shadow_offset_y", 1)


static func apply_label_colors(title: Label, subtitle: Label = null) -> void:
	title.add_theme_color_override("font_color", INK_TEXT)
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.78))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	if subtitle != null:
		subtitle.add_theme_color_override("font_color", MUTED_TEXT)
		subtitle.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.55))
		subtitle.add_theme_constant_override("shadow_offset_x", 1)
		subtitle.add_theme_constant_override("shadow_offset_y", 1)


static func apply_ink_heading(label: Label, font_size: int, font_color: Color = INK_TEXT) -> void:
	label.add_theme_font_override("font", INK_BRUSH_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.82))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)


static func apply_ink_body_label(label: Label, font_size: int) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.12, 0.11, 0.08, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0.94, 0.96, 0.88, 0.78))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)


static func _apply_button_base(button: Button, font_size: int) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", INK_TEXT)
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.7, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.84, 0.58, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.48, 0.5, 0.45, 0.7))


static func _make_box(bg_color: Color, border_color: Color, border_width: int, radius: int, shadow_size: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg_color
	box.border_color = border_color
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.shadow_color = Color(0.0, 0.0, 0.0, 0.46)
	box.shadow_size = shadow_size
	box.content_margin_left = 14.0
	box.content_margin_top = 12.0
	box.content_margin_right = 14.0
	box.content_margin_bottom = 12.0
	return box


static func _make_texture_box(texture: Texture2D) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = texture
	box.content_margin_left = 18.0
	box.content_margin_top = 12.0
	box.content_margin_right = 18.0
	box.content_margin_bottom = 12.0
	return box
