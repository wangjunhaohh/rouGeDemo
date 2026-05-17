extends Node2D

const ARENA_TILE_PATH := "res://art/backgrounds/ink_arena_tile.png"
const ARENA_OVERLAY_PATH := "res://art/backgrounds/arena_overlay.png"
const QINGXU_LOBBY_MAP_PATH := "res://art/backgrounds/qingxu_lobby_map.png"
const QINGXU_LOBBY_LEFT_BANNER_PATH := "res://art/backgrounds/qingxu_lobby_left_banner.png"
const QINGXU_LOBBY_RIGHT_BANNER_PATH := "res://art/backgrounds/qingxu_lobby_right_banner.png"
const QINGXU_LOBBY_START_FONT := preload("res://art/fonts/MaShanZheng-Regular.ttf")
const SNOW_MOUNTAIN_MAP_PATH := "res://art/backgrounds/snow_mountain_map.png"
const SNOW_MOUNTAIN_WALK_MASK_PATH := "res://art/backgrounds/snow_mountain_walk_mask.png"
const BUILDING_COLLISION_LAYER := 8
const MAP_ID_DEFAULT := "default_arena"
const MAP_ID_QINGXU_LOBBY := "qingxu_lobby"
const MAP_ID_SNOW_MOUNTAIN := "snow_mountain"
const MAP_COLLIDER_GROUP := "arena_runtime_colliders"
const LOBBY_SOURCE_SIZE := Vector2(2560.0, 1440.0)
const LOBBY_MAP_SIZE := Vector2(3840.0, 2160.0)
const LOBBY_LEFT_BANNER_RECT_PX := Rect2(862.01, 280.04, 94.93, 143.85)
const LOBBY_RIGHT_BANNER_RECT_PX := Rect2(2406.89, 495.81, 113.31, 165.27)
const LOBBY_WENDAO_BEI_HIT_RECT_PX := Rect2(681.33, 290.76, 313.88, 374.92)
const LOBBY_XIANMINGLU_HIT_RECT_PX := Rect2(1998.08, 474.39, 505.27, 436.13)
const LOBBY_START_TEXT := "开始游戏"
const LOBBY_START_TEXT_RECT_PX := Rect2(1100.0, 1220.0, 360.0, 140.0)
const SNOW_SOURCE_SIZE := Vector2(1535.0, 1024.0)
const SNOW_MAP_SIZE := Vector2(3840.0, 2560.0)
const SNOW_PLAYER_START_PX := Vector2(300.0, 800.0)
const SNOW_CAMERA_ZOOM := Vector2(0.92, 0.92)
const SNOW_WALK_MASK_SAMPLE_OFFSETS := [
	Vector2.ZERO,
	Vector2(10.0, 0.0),
	Vector2(-10.0, 0.0),
	Vector2(0.0, 10.0),
	Vector2(0.0, -10.0),
	Vector2(18.0, 0.0),
	Vector2(-18.0, 0.0),
	Vector2(0.0, 18.0),
	Vector2(0.0, -18.0),
	Vector2(14.0, 14.0),
	Vector2(-14.0, 14.0),
	Vector2(14.0, -14.0),
	Vector2(-14.0, -14.0)
]
const SNOW_WALKABLE_POLYGONS_PX := [
	[
		Vector2(235.0, 787.0),
		Vector2(575.0, 792.0),
		Vector2(625.0, 762.0),
		Vector2(642.0, 628.0),
		Vector2(610.0, 585.0),
		Vector2(520.0, 610.0),
		Vector2(452.0, 654.0),
		Vector2(338.0, 700.0),
		Vector2(236.0, 720.0)
	],
	[
		Vector2(430.0, 390.0),
		Vector2(500.0, 315.0),
		Vector2(798.0, 282.0),
		Vector2(812.0, 392.0),
		Vector2(770.0, 438.0),
		Vector2(705.0, 438.0),
		Vector2(682.0, 510.0),
		Vector2(615.0, 566.0),
		Vector2(508.0, 610.0),
		Vector2(452.0, 575.0),
		Vector2(458.0, 505.0)
	],
	[
		Vector2(668.0, 432.0),
		Vector2(1005.0, 432.0),
		Vector2(1018.0, 560.0),
		Vector2(960.0, 583.0),
		Vector2(930.0, 758.0),
		Vector2(878.0, 792.0),
		Vector2(818.0, 766.0),
		Vector2(778.0, 668.0),
		Vector2(760.0, 500.0),
		Vector2(682.0, 492.0)
	],
	[
		Vector2(798.0, 210.0),
		Vector2(840.0, 430.0),
		Vector2(675.0, 430.0),
		Vector2(668.0, 305.0)
	],
	[
		Vector2(1000.0, 245.0),
		Vector2(1215.0, 222.0),
		Vector2(1265.0, 155.0),
		Vector2(1270.0, 450.0),
		Vector2(1212.0, 490.0),
		Vector2(1162.0, 468.0),
		Vector2(1160.0, 352.0),
		Vector2(1048.0, 348.0),
		Vector2(1048.0, 420.0),
		Vector2(1002.0, 435.0)
	],
	[
		Vector2(1000.0, 552.0),
		Vector2(1165.0, 552.0),
		Vector2(1188.0, 622.0),
		Vector2(1262.0, 684.0),
		Vector2(1218.0, 720.0),
		Vector2(1160.0, 666.0),
		Vector2(1112.0, 708.0),
		Vector2(1082.0, 790.0),
		Vector2(940.0, 790.0),
		Vector2(908.0, 738.0),
		Vector2(952.0, 642.0),
		Vector2(1000.0, 620.0)
	],
	[
		Vector2(990.0, 428.0),
		Vector2(1168.0, 428.0),
		Vector2(1172.0, 562.0),
		Vector2(998.0, 562.0)
	],
	[
		Vector2(590.0, 552.0),
		Vector2(790.0, 492.0),
		Vector2(790.0, 694.0),
		Vector2(642.0, 780.0),
		Vector2(622.0, 640.0)
	]
]
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
@export var map_id := MAP_ID_SNOW_MOUNTAIN
@export var background_color: Color = Color(0.04, 0.045, 0.06, 1.0)
@export var seam_color: Color = Color(0.22, 0.08, 0.1, 0.16)
@export var overlay_modulate: Color = Color(1.0, 1.0, 1.0, 0.52)
@export var border_shadow_color: Color = Color(0.09, 0.03, 0.05, 0.92)
@export var border_accent_color: Color = Color(0.36, 0.15, 0.17, 0.48)
@export var show_walkable_debug := false

var arena_tile: Texture2D
var arena_overlay: Texture2D
var qingxu_lobby_map: Texture2D
var qingxu_lobby_source_size := LOBBY_SOURCE_SIZE
var qingxu_lobby_left_banner: Texture2D
var qingxu_lobby_right_banner: Texture2D
var snow_mountain_map: Texture2D
var snow_map_image: Image
var snow_source_size := SNOW_SOURCE_SIZE
var snow_walk_mask: Texture2D
var snow_walk_mask_image: Image
var snow_walk_mask_size := SNOW_SOURCE_SIZE
var snow_walkable_polygons: Array[PackedVector2Array] = []
var boss_mode_active := false
var boss_phase := 1
var arena_textures_loaded := false
var qingxu_lobby_textures_loaded := false
var snow_mountain_textures_loaded := false


func _ready() -> void:
	_ensure_current_map_textures()
	_rebuild_map()
	queue_redraw()


func _draw() -> void:
	if map_id == MAP_ID_QINGXU_LOBBY:
		_draw_qingxu_lobby_map()
		return
	if map_id == MAP_ID_SNOW_MOUNTAIN:
		_draw_snow_mountain_map()
		return
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


func set_map_id(next_map_id: String) -> void:
	if map_id == next_map_id:
		_ensure_current_map_textures()
		return
	map_id = next_map_id
	_ensure_current_map_textures()
	_rebuild_map()
	queue_redraw()


func is_enemy_spawning_enabled() -> bool:
	return map_id != MAP_ID_QINGXU_LOBBY and map_id != MAP_ID_SNOW_MOUNTAIN


func get_player_start_position() -> Vector2:
	if map_id == MAP_ID_SNOW_MOUNTAIN:
		return _snow_px_to_world(SNOW_PLAYER_START_PX)
	return Vector2.ZERO


func get_lobby_interaction_at_world(world_position: Vector2) -> String:
	if map_id != MAP_ID_QINGXU_LOBBY:
		return ""
	var map_pixel := _map_world_to_px(world_position, qingxu_lobby_source_size, LOBBY_MAP_SIZE)
	if LOBBY_START_TEXT_RECT_PX.has_point(map_pixel):
		return "start_game"
	if LOBBY_WENDAO_BEI_HIT_RECT_PX.has_point(map_pixel) or LOBBY_LEFT_BANNER_RECT_PX.has_point(map_pixel):
		return "wendao_bei"
	if LOBBY_XIANMINGLU_HIT_RECT_PX.has_point(map_pixel) or LOBBY_RIGHT_BANNER_RECT_PX.has_point(map_pixel):
		return "xianminglu"
	return ""


func get_player_bounds_half_size() -> Vector2:
	if map_id == MAP_ID_SNOW_MOUNTAIN:
		return SNOW_MAP_SIZE * 0.5
	return arena_size * 0.5 - Vector2.ONE * 40.0


func get_player_camera_zoom() -> Vector2:
	if map_id == MAP_ID_SNOW_MOUNTAIN:
		return SNOW_CAMERA_ZOOM
	return Vector2(0.95, 0.95)


func uses_world_y_sort() -> bool:
	return false


func get_exploration_hud_config() -> Dictionary:
	if map_id == MAP_ID_QINGXU_LOBBY:
		return {
			"stage": "青墟大厅",
			"objective": "目标：探索青墟大厅"
		}
	return {
		"stage": "雪山古道",
		"objective": "目标：探索雪山古道"
	}


func is_position_walkable(world_position: Vector2) -> bool:
	if map_id == MAP_ID_SNOW_MOUNTAIN:
		if snow_walk_mask_image != null and not snow_walk_mask_image.is_empty():
			return _is_snow_mask_walkable(world_position)
		if _is_snow_image_walkable(world_position):
			return true
		if _is_point_in_snow_walkable_polygons(world_position):
			return true
		return false
	return true


func _is_point_in_snow_walkable_polygons(world_position: Vector2) -> bool:
	for polygon in snow_walkable_polygons:
		if Geometry2D.is_point_in_polygon(world_position, polygon):
			return true
	return false


func _ensure_current_map_textures() -> void:
	match map_id:
		MAP_ID_QINGXU_LOBBY:
			_ensure_qingxu_lobby_textures()
		MAP_ID_SNOW_MOUNTAIN:
			_ensure_snow_mountain_textures()
		_:
			_ensure_arena_textures()


func _ensure_arena_textures() -> void:
	if arena_textures_loaded:
		return
	arena_textures_loaded = true
	arena_tile = _load_texture(ARENA_TILE_PATH)
	arena_overlay = _load_texture(ARENA_OVERLAY_PATH)


func _ensure_qingxu_lobby_textures() -> void:
	if qingxu_lobby_textures_loaded:
		return
	qingxu_lobby_textures_loaded = true
	qingxu_lobby_map = _load_optional_texture(QINGXU_LOBBY_MAP_PATH)
	if qingxu_lobby_map != null:
		qingxu_lobby_source_size = Vector2(qingxu_lobby_map.get_width(), qingxu_lobby_map.get_height())
	qingxu_lobby_left_banner = _load_optional_texture(QINGXU_LOBBY_LEFT_BANNER_PATH)
	qingxu_lobby_right_banner = _load_optional_texture(QINGXU_LOBBY_RIGHT_BANNER_PATH)


func _ensure_snow_mountain_textures() -> void:
	if snow_mountain_textures_loaded:
		return
	snow_mountain_textures_loaded = true
	snow_mountain_map = _load_optional_texture(SNOW_MOUNTAIN_MAP_PATH)
	if snow_mountain_map != null:
		snow_map_image = snow_mountain_map.get_image()
		if snow_map_image != null and not snow_map_image.is_empty():
			snow_source_size = Vector2(snow_map_image.get_width(), snow_map_image.get_height())
	snow_walk_mask = _load_optional_texture(SNOW_MOUNTAIN_WALK_MASK_PATH)
	if snow_walk_mask != null:
		snow_walk_mask_image = snow_walk_mask.get_image()
		if snow_walk_mask_image != null and not snow_walk_mask_image.is_empty():
			snow_walk_mask_size = Vector2(snow_walk_mask_image.get_width(), snow_walk_mask_image.get_height())


func _load_texture(path: String) -> Texture2D:
	var texture: Texture2D = load(path) as Texture2D
	if texture == null:
		push_error("Failed to load arena texture: %s" % path)
		return null
	return texture


func _load_optional_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var texture: Texture2D = load(path) as Texture2D
		if texture != null:
			return texture

	var image := Image.new()
	var error := image.load(ProjectSettings.globalize_path(path))
	if error != OK:
		return null
	return ImageTexture.create_from_image(image)


func _rebuild_map() -> void:
	_clear_map_colliders()
	snow_walkable_polygons.clear()
	if map_id == MAP_ID_QINGXU_LOBBY:
		return
	if map_id == MAP_ID_SNOW_MOUNTAIN:
		_cache_snow_walkable_polygons()
		return
	_build_ancient_building_colliders()


func _clear_map_colliders() -> void:
	for child in get_children():
		if child.is_in_group(MAP_COLLIDER_GROUP):
			child.queue_free()


func _build_ancient_building_colliders() -> void:
	for building in ANCIENT_BUILDINGS:
		var body := StaticBody2D.new()
		body.name = "AncientBuilding"
		body.add_to_group(MAP_COLLIDER_GROUP)
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


func _cache_snow_walkable_polygons() -> void:
	for raw_polygon in SNOW_WALKABLE_POLYGONS_PX:
		snow_walkable_polygons.append(_snow_polygon_to_world(raw_polygon))


func _snow_polygon_to_world(raw_polygon: Array) -> PackedVector2Array:
	var points := PackedVector2Array()
	for raw_point in raw_polygon:
		points.append(_snow_px_to_world(raw_point))
	return points


func _snow_px_to_world(pixel_position: Vector2) -> Vector2:
	return _map_px_to_world(pixel_position, snow_source_size, SNOW_MAP_SIZE)


func _map_px_to_world(pixel_position: Vector2, source_size: Vector2, map_size: Vector2) -> Vector2:
	return Vector2(
		pixel_position.x / source_size.x * map_size.x - map_size.x * 0.5,
		pixel_position.y / source_size.y * map_size.y - map_size.y * 0.5
	)


func _map_rect_px_to_world(raw_rect: Rect2, source_size: Vector2, map_size: Vector2) -> Rect2:
	var top_left := _map_px_to_world(raw_rect.position, source_size, map_size)
	var bottom_right := _map_px_to_world(raw_rect.position + raw_rect.size, source_size, map_size)
	return Rect2(top_left, bottom_right - top_left)


func _snow_world_to_px(world_position: Vector2) -> Vector2:
	return _map_world_to_px(world_position, snow_source_size, SNOW_MAP_SIZE)


func _map_world_to_px(world_position: Vector2, source_size: Vector2, map_size: Vector2) -> Vector2:
	return Vector2(
		(world_position.x + map_size.x * 0.5) / map_size.x * source_size.x,
		(world_position.y + map_size.y * 0.5) / map_size.y * source_size.y
	)


func _snow_world_to_walk_mask_px(world_position: Vector2) -> Vector2:
	return _map_world_to_px(world_position, snow_walk_mask_size, SNOW_MAP_SIZE)


func _is_snow_mask_walkable(world_position: Vector2) -> bool:
	var pixel_position: Vector2 = _snow_world_to_walk_mask_px(world_position)
	return _is_walk_mask_pixel_near(pixel_position, snow_walk_mask_image, snow_walk_mask_size)


func _is_walk_mask_pixel_near(pixel_position: Vector2, image: Image, image_size: Vector2) -> bool:
	for raw_offset in SNOW_WALK_MASK_SAMPLE_OFFSETS:
		var offset: Vector2 = raw_offset
		var sample_position: Vector2 = pixel_position + offset
		if sample_position.x < 0.0 or sample_position.y < 0.0:
			continue
		if sample_position.x >= image_size.x or sample_position.y >= image_size.y:
			continue
		var color := image.get_pixelv(Vector2i(int(sample_position.x), int(sample_position.y)))
		if _is_walk_mask_pixel(color):
			return true
	return false


func _is_walk_mask_pixel(color: Color) -> bool:
	return color.r > 0.55 and color.r > color.g * 1.45 and color.r > color.b * 1.45


func _is_snow_image_walkable(world_position: Vector2) -> bool:
	if snow_map_image == null or snow_map_image.is_empty():
		return false

	var pixel_position: Vector2 = _snow_world_to_px(world_position)
	var walkable_samples := 0
	var valid_samples := 0
	for raw_offset in SNOW_WALK_MASK_SAMPLE_OFFSETS:
		var offset: Vector2 = raw_offset
		var sample_position: Vector2 = pixel_position + offset
		if sample_position.x < 0.0 or sample_position.y < 0.0:
			continue
		if sample_position.x >= snow_source_size.x or sample_position.y >= snow_source_size.y:
			continue
		valid_samples += 1
		var color := snow_map_image.get_pixelv(Vector2i(int(sample_position.x), int(sample_position.y)))
		if _is_snow_floor_pixel(color):
			walkable_samples += 1

	return valid_samples > 0 and walkable_samples >= 3


func _is_snow_floor_pixel(color: Color) -> bool:
	var red := color.r * 255.0
	var green := color.g * 255.0
	var blue := color.b * 255.0
	var brightness := (red + green + blue) / 3.0
	var channel_max: float = maxf(red, maxf(green, blue))
	var channel_min: float = minf(red, minf(green, blue))
	var channel_range := channel_max - channel_min
	if blue > red + 10.0:
		return false
	if brightness >= 132.0 and channel_range <= 52.0:
		return true
	if brightness >= 112.0 and channel_range <= 30.0:
		return true
	return false


func _draw_snow_mountain_map() -> void:
	var rect := Rect2(-SNOW_MAP_SIZE * 0.5, SNOW_MAP_SIZE)
	draw_rect(rect, Color(0.58, 0.55, 0.49, 1.0), true)
	if snow_mountain_map != null:
		draw_texture_rect(snow_mountain_map, rect, false)
	if show_walkable_debug:
		for polygon in snow_walkable_polygons:
			draw_colored_polygon(polygon, Color(1.0, 0.08, 0.08, 0.18))
			draw_polyline(polygon, Color(1.0, 0.08, 0.08, 0.68), 4.0, true)


func _draw_qingxu_lobby_map() -> void:
	var rect := Rect2(-LOBBY_MAP_SIZE * 0.5, LOBBY_MAP_SIZE)
	draw_rect(rect, Color(0.82, 0.81, 0.76, 1.0), true)
	if qingxu_lobby_map != null:
		draw_texture_rect(qingxu_lobby_map, rect, false)
	if qingxu_lobby_left_banner != null:
		draw_texture_rect(qingxu_lobby_left_banner, _map_rect_px_to_world(LOBBY_LEFT_BANNER_RECT_PX, qingxu_lobby_source_size, LOBBY_MAP_SIZE), false)
	if qingxu_lobby_right_banner != null:
		draw_texture_rect(qingxu_lobby_right_banner, _map_rect_px_to_world(LOBBY_RIGHT_BANNER_RECT_PX, qingxu_lobby_source_size, LOBBY_MAP_SIZE), false)
	_draw_qingxu_lobby_start_text()


func _draw_qingxu_lobby_start_text() -> void:
	var text_rect := _map_rect_px_to_world(LOBBY_START_TEXT_RECT_PX, qingxu_lobby_source_size, LOBBY_MAP_SIZE)
	var font_size := 118
	var baseline_y := text_rect.position.y + (text_rect.size.y - QINGXU_LOBBY_START_FONT.get_height(font_size)) * 0.5 + QINGXU_LOBBY_START_FONT.get_ascent(font_size)
	var baseline := Vector2(text_rect.position.x, baseline_y)
	var shadow_offsets := [
		Vector2(4.0, 5.0),
		Vector2(-3.0, 3.0),
		Vector2(0.0, 7.0)
	]
	for offset in shadow_offsets:
		draw_string(QINGXU_LOBBY_START_FONT, baseline + offset, LOBBY_START_TEXT, HORIZONTAL_ALIGNMENT_CENTER, text_rect.size.x, font_size, Color(0.08, 0.07, 0.05, 0.78))
	draw_string(QINGXU_LOBBY_START_FONT, baseline + Vector2(0.0, -2.0), LOBBY_START_TEXT, HORIZONTAL_ALIGNMENT_CENTER, text_rect.size.x, font_size, Color(0.94, 0.86, 0.58, 0.92))
	draw_string(QINGXU_LOBBY_START_FONT, baseline, LOBBY_START_TEXT, HORIZONTAL_ALIGNMENT_CENTER, text_rect.size.x, font_size, Color(0.16, 0.12, 0.07, 1.0))


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
	for index in range(6):
		var angle: float = TAU * float(index) / 6.0 + PI * 0.5
		var inner: Vector2 = center + Vector2.RIGHT.rotated(angle) * 180.0
		var outer: Vector2 = center + Vector2.RIGHT.rotated(angle) * (460.0 if boss_phase == 1 else 580.0)
		draw_line(inner, outer, Color(0.68, 0.14, 0.12, 0.18), 2.0)
