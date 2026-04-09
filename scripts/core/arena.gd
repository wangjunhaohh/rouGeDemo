extends Node2D

const ARENA_TILE_PATH := "res://art/backgrounds/arena_tile.png"
const ARENA_OVERLAY_PATH := "res://art/backgrounds/arena_overlay.png"

@export var arena_size: Vector2 = Vector2(3200.0, 3200.0)
@export var cell_size: float = 64.0
@export var background_color: Color = Color(0.04, 0.045, 0.06, 1.0)
@export var seam_color: Color = Color(0.22, 0.08, 0.1, 0.16)
@export var overlay_modulate: Color = Color(1.0, 1.0, 1.0, 0.52)
@export var border_shadow_color: Color = Color(0.09, 0.03, 0.05, 0.92)
@export var border_accent_color: Color = Color(0.36, 0.15, 0.17, 0.48)

var arena_tile: Texture2D
var arena_overlay: Texture2D
var boss_mode_active := false
var boss_phase := 1


func _ready() -> void:
	arena_tile = _load_texture(ARENA_TILE_PATH)
	arena_overlay = _load_texture(ARENA_OVERLAY_PATH)
	queue_redraw()


func _draw() -> void:
	var half_size: Vector2 = arena_size * 0.5
	var rect: Rect2 = Rect2(-half_size, arena_size)
	draw_rect(rect, background_color, true)
	if arena_tile != null:
		draw_texture_rect(arena_tile, rect, true)
	if arena_overlay != null:
		draw_texture_rect(arena_overlay, Rect2(rect.position + Vector2(96.0, 64.0), rect.size), true, overlay_modulate)

	var major_step: int = int(cell_size * 4.0)
	var start_x: int = int(-half_size.x)
	var end_x: int = int(half_size.x)
	var start_y: int = int(-half_size.y)
	var end_y: int = int(half_size.y)

	var x: int = start_x
	while x <= end_x:
		draw_line(Vector2(x, start_y), Vector2(x, end_y), seam_color, 2.0)
		x += major_step

	var y: int = start_y
	while y <= end_y:
		draw_line(Vector2(start_x, y), Vector2(end_x, y), seam_color, 2.0)
		y += major_step

	draw_rect(rect, border_shadow_color, false, 6.0)
	draw_rect(rect.grow(-32.0), border_accent_color, false, 2.0)
	if boss_mode_active:
		_draw_boss_overlay(rect)


func _load_texture(path: String) -> Texture2D:
	var texture: Texture2D = load(path) as Texture2D
	if texture == null:
		push_error("Failed to load arena texture: %s" % path)
		return null
	return texture


func set_boss_mode(active: bool, phase: int = 1) -> void:
	boss_mode_active = active
	boss_phase = phase
	queue_redraw()


func _draw_boss_overlay(rect: Rect2) -> void:
	var overlay_alpha: float = 0.08 if boss_phase == 1 else 0.13
	var overlay_color: Color = Color(0.26, 0.03, 0.05, overlay_alpha)
	draw_rect(rect, overlay_color, true)

	var center: Vector2 = Vector2.ZERO
	var ring_color: Color = Color(0.72, 0.16, 0.14, 0.22 if boss_phase == 1 else 0.32)
	draw_arc(center, 220.0, 0.0, TAU, 72, ring_color, 3.0)
	draw_arc(center, 380.0, 0.0, TAU, 96, ring_color.darkened(0.18), 2.0)
	if boss_phase >= 2:
		draw_arc(center, 540.0, 0.0, TAU, 120, Color(0.95, 0.28, 0.2, 0.18), 2.0)

	for index in range(6):
		var angle: float = TAU * float(index) / 6.0 + PI * 0.5
		var inner: Vector2 = center + Vector2.RIGHT.rotated(angle) * 180.0
		var outer: Vector2 = center + Vector2.RIGHT.rotated(angle) * (460.0 if boss_phase == 1 else 580.0)
		draw_line(inner, outer, Color(0.68, 0.14, 0.12, 0.18), 2.0)
