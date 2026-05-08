extends Node2D

const ARENA_TILE_PATH := "res://art/backgrounds/ink_arena_tile.png"
const ARENA_OVERLAY_PATH := "res://art/backgrounds/arena_overlay.png"
const BUILDING_COLLISION_LAYER := 8
const ANCIENT_BUILDINGS := [
	{
		"position": Vector2(-740.0, -760.0),
		"size": Vector2(460.0, 220.0),
		"roof": Color(0.17, 0.28, 0.36, 0.72),
		"wall": Color(0.82, 0.86, 0.82, 0.78),
		"accent": Color(0.72, 0.16, 0.12, 0.84)
	},
	{
		"position": Vector2(850.0, -300.0),
		"size": Vector2(300.0, 340.0),
		"roof": Color(0.14, 0.25, 0.32, 0.7),
		"wall": Color(0.84, 0.88, 0.84, 0.76),
		"accent": Color(0.68, 0.14, 0.13, 0.82)
	},
	{
		"position": Vector2(-980.0, 390.0),
		"size": Vector2(340.0, 260.0),
		"roof": Color(0.16, 0.27, 0.34, 0.68),
		"wall": Color(0.83, 0.86, 0.8, 0.72),
		"accent": Color(0.76, 0.18, 0.12, 0.82)
	},
	{
		"position": Vector2(260.0, 860.0),
		"size": Vector2(540.0, 180.0),
		"roof": Color(0.13, 0.23, 0.31, 0.66),
		"wall": Color(0.86, 0.88, 0.82, 0.74),
		"accent": Color(0.74, 0.16, 0.11, 0.82)
	}
]

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
	_build_ancient_building_colliders()
	queue_redraw()


func _draw() -> void:
	var half_size: Vector2 = arena_size * 0.5
	var rect: Rect2 = Rect2(-half_size, arena_size)
	draw_rect(rect, background_color, true)
	if arena_tile != null:
		draw_texture_rect(arena_tile, rect, true)
	if arena_overlay != null:
		draw_texture_rect(arena_overlay, Rect2(rect.position + Vector2(96.0, 64.0), rect.size), true, overlay_modulate)
	_draw_ancient_buildings()

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


func _build_ancient_building_colliders() -> void:
	for building in ANCIENT_BUILDINGS:
		var body := StaticBody2D.new()
		body.name = "AncientBuilding"
		body.collision_layer = BUILDING_COLLISION_LAYER
		body.collision_mask = 0
		body.global_position = building["position"]
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		var building_size: Vector2 = building["size"]
		rectangle.size = building_size * Vector2(0.88, 0.76)
		shape.shape = rectangle
		body.add_child(shape)
		add_child(body)


func _draw_ancient_buildings() -> void:
	for building in ANCIENT_BUILDINGS:
		_draw_ancient_building(
			Vector2(building["position"]),
			Vector2(building["size"]),
			building["roof"],
			building["wall"],
			building["accent"]
		)


func _draw_ancient_building(center: Vector2, size: Vector2, roof_color: Color, wall_color: Color, accent_color: Color) -> void:
	var rect := Rect2(center - size * 0.5, size)
	var shadow := rect.grow(18.0)
	draw_rect(shadow, Color(0.04, 0.08, 0.09, 0.22), true)
	draw_rect(rect, wall_color, true)
	draw_rect(rect, Color(0.14, 0.22, 0.24, 0.36), false, 2.0)

	var roof_height := size.y * 0.34
	var roof_rect := Rect2(rect.position + Vector2(-18.0, -roof_height * 0.3), Vector2(size.x + 36.0, roof_height))
	draw_rect(roof_rect, roof_color, true)
	draw_rect(roof_rect, accent_color, false, 2.0)
	var top_eave := PackedVector2Array([
		roof_rect.position + Vector2(-28.0, roof_height * 0.48),
		roof_rect.position + Vector2(size.x * 0.5 + 18.0, -roof_height * 0.45),
		roof_rect.position + Vector2(size.x + 64.0, roof_height * 0.48),
		roof_rect.position + Vector2(size.x + 22.0, roof_height * 0.68),
		roof_rect.position + Vector2(size.x * 0.5 + 18.0, roof_height * 0.18),
		roof_rect.position + Vector2(-4.0, roof_height * 0.68)
	])
	draw_colored_polygon(top_eave, roof_color.lightened(0.08))
	draw_polyline(top_eave, accent_color, 2.0, true)

	var column_count := 5
	for index in range(column_count):
		var ratio := float(index + 1) / float(column_count + 1)
		var x := lerpf(rect.position.x + 28.0, rect.end.x - 28.0, ratio)
		draw_line(Vector2(x, rect.position.y + roof_height * 0.9), Vector2(x, rect.end.y - 18.0), Color(0.32, 0.36, 0.35, 0.46), 3.0)
		draw_circle(Vector2(x, rect.end.y - 14.0), 4.0, accent_color)

	var stair_width := size.x * 0.32
	var stair_top := rect.end + Vector2(-stair_width * 0.5, 0.0)
	for step in range(4):
		var step_rect := Rect2(
			stair_top + Vector2(-float(step) * 12.0, float(step) * 11.0),
			Vector2(stair_width + float(step) * 24.0, 8.0)
		)
		draw_rect(step_rect, Color(0.78, 0.82, 0.78, 0.45), true)
		draw_rect(step_rect, Color(0.18, 0.24, 0.25, 0.22), false, 1.0)


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
