extends Node2D
class_name SkyPalaceMap

const MAP_SOURCE_SIZE := Vector2(1672.0, 941.0)
const MAP_SIZE := MAP_SOURCE_SIZE
const PLAYER_START_POSITION := Vector2(0.0, 68.0)
const CAMERA_ZOOM := Vector2(1.0, 1.0)
const CAMERA_OFFSET := Vector2.ZERO
const COLLISION_LAYER := 8
const MAP_COLLIDER_GROUP := "arena_runtime_colliders"
const ASSET_ROOT := "res://assets/maps/sky_palace/"
const REFERENCE_OVERLAY_ALPHA := 0.0
const SPRITE_TINT := Color(0.88, 0.92, 0.9, 0.94)
const BACKGROUND_Z := -3900
const GROUND_Z := -3000
const FOREGROUND_Z := 3000
const CANVAS_Z_MIN := -4096
const CANVAS_Z_MAX := 4096

var _textures: Dictionary = {}
var _walkable_ellipses: Array[Dictionary] = []
var _walkable_polygons: Array[PackedVector2Array] = []

@onready var background_layer: Node2D = $Background
@onready var ground_layer: Node2D = $Ground
@onready var collision_layer_node: Node2D = $Collision
@onready var cliff_blockers: Node2D = $Collision/CliffBlockers
@onready var fence_blockers: Node2D = $Collision/FenceBlockers
@onready var building_blockers: Node2D = $Collision/BuildingBlockers
@onready var prop_blockers: Node2D = $Collision/PropBlockers
@onready var ysort_objects: Node2D = $YSortObjects
@onready var buildings_layer: Node2D = $YSortObjects/Buildings
@onready var trees_layer: Node2D = $YSortObjects/Trees
@onready var rocks_layer: Node2D = $YSortObjects/Rocks
@onready var fences_back_layer: Node2D = $YSortObjects/FencesBack
@onready var props_layer: Node2D = $YSortObjects/Props
@onready var foreground_layer: Node2D = $Foreground
@onready var fences_front_layer: Node2D = $Foreground/FencesFront
@onready var tree_tops_layer: Node2D = $Foreground/TreeTops
@onready var mist_front_layer: Node2D = $Foreground/MistFront


func _ready() -> void:
	add_to_group(MAP_COLLIDER_GROUP)
	z_as_relative = false
	z_index = BACKGROUND_Z
	ysort_objects.y_sort_enabled = true
	_load_textures()
	_cache_walkable_shapes()
	_build_visuals()
	_build_collision()
	queue_redraw()


func _draw() -> void:
	var map_rect := Rect2(-MAP_SIZE * 0.5, MAP_SIZE)
	draw_rect(map_rect, Color(0.84, 0.84, 0.78, 1.0), true)
	draw_rect(map_rect, Color(0.68, 0.78, 0.8, 0.24), true)

	for index in range(10):
		var y := -MAP_SIZE.y * 0.46 + float(index) * 76.0
		var alpha := 0.1 - float(index) * 0.006
		var left := Vector2(-MAP_SIZE.x * 0.48, y)
		var right := Vector2(MAP_SIZE.x * 0.48, y + sin(float(index) * 1.7) * 10.0)
		draw_line(left, right, Color(0.95, 0.97, 0.92, maxf(alpha, 0.035)), 9.0)

	_draw_mountain_silhouette(Vector2(-650.0, -255.0), 170.0, Color(0.38, 0.5, 0.52, 0.13))
	_draw_mountain_silhouette(Vector2(-460.0, -300.0), 125.0, Color(0.38, 0.5, 0.52, 0.1))
	_draw_mountain_silhouette(Vector2(575.0, -280.0), 150.0, Color(0.38, 0.5, 0.52, 0.12))
	_draw_mountain_silhouette(Vector2(715.0, -220.0), 110.0, Color(0.38, 0.5, 0.52, 0.1))
	_draw_template_island_bases()
	_draw_template_water_details()
	_draw_template_stone_paths()


func get_map_size() -> Vector2:
	return MAP_SIZE


func get_player_start_position() -> Vector2:
	return PLAYER_START_POSITION


func get_player_camera_zoom() -> Vector2:
	return CAMERA_ZOOM


func get_player_camera_offset() -> Vector2:
	return CAMERA_OFFSET


func _px(pixel_position: Vector2) -> Vector2:
	return pixel_position - MAP_SOURCE_SIZE * 0.5


func _baseline_y(pixel_y: float) -> int:
	return int(round(pixel_y - MAP_SOURCE_SIZE.y * 0.5))


func _draw_mountain_silhouette(center: Vector2, size: float, color: Color) -> void:
	var points := PackedVector2Array([
		center + Vector2(-size * 0.6, size * 0.72),
		center + Vector2(-size * 0.25, -size * 0.44),
		center + Vector2(-size * 0.03, size * 0.1),
		center + Vector2(size * 0.22, -size * 0.72),
		center + Vector2(size * 0.55, size * 0.72)
	])
	draw_colored_polygon(points, color)


func _draw_template_island_bases() -> void:
	var stone_fill := Color(0.47, 0.55, 0.52, 0.36)
	var moss_fill := Color(0.27, 0.43, 0.35, 0.22)
	var cliff_edge := Color(0.26, 0.34, 0.34, 0.28)
	_draw_island_polygon([
		Vector2(646.0, 270.0),
		Vector2(1018.0, 270.0),
		Vector2(1075.0, 398.0),
		Vector2(1000.0, 468.0),
		Vector2(836.0, 494.0),
		Vector2(668.0, 468.0),
		Vector2(592.0, 402.0)
	], stone_fill, cliff_edge)
	_draw_island_polygon([
		Vector2(410.0, 274.0),
		Vector2(638.0, 270.0),
		Vector2(694.0, 408.0),
		Vector2(560.0, 494.0),
		Vector2(356.0, 438.0),
		Vector2(340.0, 340.0)
	], stone_fill, cliff_edge)
	_draw_island_polygon([
		Vector2(1042.0, 278.0),
		Vector2(1302.0, 282.0),
		Vector2(1340.0, 434.0),
		Vector2(1160.0, 496.0),
		Vector2(984.0, 416.0)
	], stone_fill, cliff_edge)
	_draw_island_polygon([
		Vector2(112.0, 388.0),
		Vector2(438.0, 404.0),
		Vector2(526.0, 558.0),
		Vector2(340.0, 692.0),
		Vector2(88.0, 640.0),
		Vector2(22.0, 488.0)
	], stone_fill, cliff_edge)
	_draw_island_polygon([
		Vector2(1222.0, 404.0),
		Vector2(1550.0, 390.0),
		Vector2(1640.0, 520.0),
		Vector2(1530.0, 678.0),
		Vector2(1282.0, 666.0),
		Vector2(1164.0, 548.0)
	], stone_fill, cliff_edge)
	_draw_island_polygon([
		Vector2(492.0, 642.0),
		Vector2(710.0, 654.0),
		Vector2(714.0, 828.0),
		Vector2(520.0, 906.0),
		Vector2(380.0, 820.0)
	], moss_fill, cliff_edge)
	_draw_island_polygon([
		Vector2(962.0, 656.0),
		Vector2(1184.0, 640.0),
		Vector2(1290.0, 794.0),
		Vector2(1152.0, 910.0),
		Vector2(960.0, 846.0)
	], moss_fill, cliff_edge)
	_draw_island_polygon([
		Vector2(704.0, 744.0),
		Vector2(968.0, 744.0),
		Vector2(1026.0, 934.0),
		Vector2(648.0, 934.0)
	], Color(0.45, 0.52, 0.48, 0.24), cliff_edge)


func _draw_template_water_details() -> void:
	var water_fill := Color(0.45, 0.68, 0.72, 0.28)
	var water_edge := Color(0.78, 0.92, 0.92, 0.34)
	_draw_ellipse_px(Vector2(616.0, 724.0), Vector2(98.0, 34.0), water_fill, water_edge)
	_draw_ellipse_px(Vector2(1054.0, 724.0), Vector2(102.0, 34.0), water_fill, water_edge)
	_draw_ellipse_px(Vector2(528.0, 824.0), Vector2(112.0, 44.0), Color(0.45, 0.68, 0.72, 0.18), water_edge)
	_draw_ellipse_px(Vector2(1150.0, 824.0), Vector2(118.0, 44.0), Color(0.45, 0.68, 0.72, 0.18), water_edge)
	_draw_waterfall_strands(Vector2(650.0, 382.0), 92.0, 52.0)
	_draw_waterfall_strands(Vector2(1026.0, 382.0), 96.0, 54.0)
	_draw_waterfall_strands(Vector2(386.0, 668.0), 118.0, 50.0)
	_draw_waterfall_strands(Vector2(1278.0, 666.0), 120.0, 52.0)


func _draw_template_stone_paths() -> void:
	var fill := Color(0.73, 0.72, 0.65, 0.72)
	var edge := Color(0.47, 0.5, 0.48, 0.42)
	_draw_path_polygon([
		Vector2(650.0, 378.0),
		Vector2(1022.0, 378.0),
		Vector2(980.0, 462.0),
		Vector2(692.0, 462.0)
	], fill, edge)
	_draw_path_polygon([
		Vector2(782.0, 315.0),
		Vector2(892.0, 315.0),
		Vector2(900.0, 545.0),
		Vector2(770.0, 545.0)
	], fill, edge)
	_draw_path_polygon([
		Vector2(735.0, 520.0),
		Vector2(936.0, 520.0),
		Vector2(915.0, 920.0),
		Vector2(758.0, 920.0)
	], fill, edge)
	_draw_path_polygon([
		Vector2(315.0, 548.0),
		Vector2(645.0, 488.0),
		Vector2(760.0, 534.0),
		Vector2(638.0, 622.0),
		Vector2(340.0, 674.0)
	], fill, edge)
	_draw_path_polygon([
		Vector2(910.0, 534.0),
		Vector2(1032.0, 488.0),
		Vector2(1360.0, 548.0),
		Vector2(1340.0, 674.0),
		Vector2(1034.0, 622.0)
	], fill, edge)
	_draw_path_polygon([
		Vector2(140.0, 512.0),
		Vector2(382.0, 510.0),
		Vector2(506.0, 586.0),
		Vector2(420.0, 664.0),
		Vector2(138.0, 632.0)
	], fill, edge)
	_draw_path_polygon([
		Vector2(1288.0, 586.0),
		Vector2(1418.0, 508.0),
		Vector2(1542.0, 510.0),
		Vector2(1540.0, 632.0),
		Vector2(1266.0, 666.0)
	], fill, edge)
	_draw_path_polygon([
		Vector2(642.0, 682.0),
		Vector2(1028.0, 682.0),
		Vector2(984.0, 774.0),
		Vector2(690.0, 774.0)
	], fill, edge)
	_draw_path_polygon([
		Vector2(762.0, 776.0),
		Vector2(912.0, 776.0),
		Vector2(916.0, 928.0),
		Vector2(758.0, 928.0)
	], fill, edge)
	_draw_path_tile_lines()


func _draw_path_tile_lines() -> void:
	var line_color := Color(0.54, 0.56, 0.52, 0.24)
	for pixel_y in [424.0, 474.0, 524.0, 574.0, 624.0, 674.0, 724.0, 774.0, 824.0]:
		draw_line(_px(Vector2(744.0, pixel_y)), _px(Vector2(930.0, pixel_y + 8.0)), line_color, 1.0)
	for pixel_x in [786.0, 834.0, 882.0]:
		draw_line(_px(Vector2(pixel_x, 328.0)), _px(Vector2(pixel_x + 10.0, 910.0)), line_color, 1.0)
	for segment in range(8):
		var angle := TAU * float(segment) / 8.0
		draw_line(
			_px(Vector2(836.0, 536.0)),
			_px(Vector2(836.0, 536.0)) + Vector2(cos(angle) * 225.0, sin(angle) * 116.0),
			Color(0.52, 0.54, 0.5, 0.14),
			1.0
		)


func _draw_path_polygon(raw_points: Array[Vector2], fill: Color, edge: Color) -> void:
	var points := PackedVector2Array()
	for point in raw_points:
		points.append(_px(point))
	draw_colored_polygon(points, fill)
	points.append(points[0])
	draw_polyline(points, edge, 2.0)


func _draw_island_polygon(raw_points: Array[Vector2], fill: Color, edge: Color) -> void:
	var points := PackedVector2Array()
	for point in raw_points:
		points.append(_px(point))
	draw_colored_polygon(points, fill)
	points.append(points[0])
	draw_polyline(points, edge, 2.0)


func _draw_ellipse_px(pixel_position: Vector2, radius: Vector2, fill: Color, edge: Color) -> void:
	var points := _ellipse_points(_px(pixel_position), radius, 40)
	draw_colored_polygon(points, fill)
	points.append(points[0])
	draw_polyline(points, edge, 1.6)


func _ellipse_points(center: Vector2, radius: Vector2, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for segment in range(segments):
		var angle := TAU * float(segment) / float(segments)
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	return points


func _draw_waterfall_strands(pixel_position: Vector2, length: float, width: float) -> void:
	var origin := _px(pixel_position)
	for strand in range(5):
		var offset_x := -width * 0.5 + float(strand) * width * 0.25
		var start := origin + Vector2(offset_x, -length * 0.45)
		var end := origin + Vector2(offset_x + sin(float(strand) * 1.8) * 8.0, length * 0.52)
		draw_line(start, end, Color(0.68, 0.89, 0.92, 0.24), 4.0)
		draw_line(start + Vector2(3.0, 0.0), end + Vector2(1.0, 0.0), Color(0.96, 1.0, 1.0, 0.22), 1.4)


func is_position_walkable(world_position: Vector2) -> bool:
	for ellipse in _walkable_ellipses:
		var center: Vector2 = ellipse["center"]
		var radius: Vector2 = ellipse["radius"]
		var normalized := Vector2(
			(world_position.x - center.x) / radius.x,
			(world_position.y - center.y) / radius.y
		)
		if normalized.length_squared() <= 1.0:
			return true

	for polygon in _walkable_polygons:
		if Geometry2D.is_point_in_polygon(world_position, polygon):
			return true

	return false


func _load_textures() -> void:
	var paths := [
		"reference/reference_sky_palace.png",
		"ground/center_round_platform.png",
		"ground/left_platform.png",
		"ground/right_platform.png",
		"ground/bottom_path.png",
		"ground/bridge_left.png",
		"ground/bridge_right.png",
		"ground/stairs_left.png",
		"ground/stairs_right.png",
		"buildings/main_hall.png",
		"buildings/side_hall.png",
		"buildings/library_hall.png",
		"buildings/monument.png",
		"buildings/notice_board.png",
		"fences/fence_long.png",
		"fences/fence_short.png",
		"fences/fence_short_low.png",
		"fences/fence_curve.png",
		"props/bamboo.png",
		"props/tree_pink.png",
		"props/tree_green.png",
		"props/rock_01.png",
		"props/rock_02.png",
		"props/rock_03.png",
		"props/rock_small.png",
		"props/shrub_01.png",
		"props/shrub_small_01.png",
		"props/shrub_small_02.png",
		"props/waterfall_01.png",
		"props/waterfall_02.png",
		"props/waterfall_03.png",
		"props/waterfall_04.png",
		"props/water_rock_pool.png",
		"props/lotus_01.png",
		"props/lotus_02.png",
		"props/lotus_03.png",
		"props/lotus_04.png",
		"props/flowers_01.png",
		"props/lamp_01.png",
		"props/lamp_02.png",
		"props/lamp_small.png",
		"props/banner_green.png",
		"props/banner_brown.png",
		"props/banner_blue.png",
		"props/banner_small.png",
		"props/sign_round.png",
		"props/sign_medallion.png"
	]
	for path in paths:
		_textures[path] = _load_texture(ASSET_ROOT + path)


func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var texture := load(path) as Texture2D
		if texture != null:
			return texture

	var image := Image.new()
	var error := image.load(ProjectSettings.globalize_path(path))
	if error != OK:
		push_warning("Sky palace texture missing: %s" % path)
		return null
	return ImageTexture.create_from_image(image)


func _cache_walkable_shapes() -> void:
	_walkable_ellipses = [
		{"center": _px(Vector2(836.0, 536.0)), "radius": Vector2(220.0, 116.0)},
		{"center": _px(Vector2(524.0, 568.0)), "radius": Vector2(148.0, 82.0)},
		{"center": _px(Vector2(1148.0, 584.0)), "radius": Vector2(140.0, 82.0)},
		{"center": _px(Vector2(540.0, 312.0)), "radius": Vector2(126.0, 86.0)},
		{"center": _px(Vector2(1130.0, 330.0)), "radius": Vector2(128.0, 82.0)},
		{"center": _px(Vector2(206.0, 526.0)), "radius": Vector2(155.0, 78.0)},
		{"center": _px(Vector2(1452.0, 528.0)), "radius": Vector2(160.0, 78.0)},
		{"center": _px(Vector2(836.0, 742.0)), "radius": Vector2(180.0, 60.0)}
	]
	_walkable_polygons = [
		PackedVector2Array([
			_px(Vector2(780.0, 318.0)),
			_px(Vector2(892.0, 318.0)),
			_px(Vector2(908.0, 452.0)),
			_px(Vector2(872.0, 476.0)),
			_px(Vector2(798.0, 476.0)),
			_px(Vector2(764.0, 452.0))
		]),
		PackedVector2Array([
			_px(Vector2(620.0, 478.0)),
			_px(Vector2(775.0, 512.0)),
			_px(Vector2(775.0, 598.0)),
			_px(Vector2(610.0, 626.0)),
			_px(Vector2(470.0, 594.0)),
			_px(Vector2(480.0, 520.0))
		]),
		PackedVector2Array([
			_px(Vector2(898.0, 512.0)),
			_px(Vector2(1052.0, 476.0)),
			_px(Vector2(1200.0, 520.0)),
			_px(Vector2(1208.0, 594.0)),
			_px(Vector2(1048.0, 626.0)),
			_px(Vector2(898.0, 598.0))
		]),
		PackedVector2Array([
			_px(Vector2(790.0, 625.0)),
			_px(Vector2(882.0, 625.0)),
			_px(Vector2(896.0, 910.0)),
			_px(Vector2(776.0, 910.0))
		]),
		PackedVector2Array([
			_px(Vector2(180.0, 500.0)),
			_px(Vector2(420.0, 502.0)),
			_px(Vector2(524.0, 574.0)),
			_px(Vector2(424.0, 666.0)),
			_px(Vector2(168.0, 632.0))
		]),
		PackedVector2Array([
			_px(Vector2(1248.0, 574.0)),
			_px(Vector2(1374.0, 502.0)),
			_px(Vector2(1536.0, 506.0)),
			_px(Vector2(1530.0, 632.0)),
			_px(Vector2(1276.0, 666.0))
		]),
		PackedVector2Array([
			_px(Vector2(654.0, 670.0)),
			_px(Vector2(1018.0, 670.0)),
			_px(Vector2(992.0, 782.0)),
			_px(Vector2(684.0, 782.0))
		])
	]


func _build_visuals() -> void:
	if REFERENCE_OVERLAY_ALPHA > 0.0:
		_add_sprite_px(background_layer, "ReferenceImage", "reference/reference_sky_palace.png", Vector2(836.0, 470.5), 1.0, BACKGROUND_Z + 4, Color(1.0, 1.0, 1.0, REFERENCE_OVERLAY_ALPHA))

	# First pass: center round platform, the upper approach, and the main hall lock to the template.
	_add_sprite_px(ground_layer, "CenterRoundPlatform", "ground/center_round_platform.png", Vector2(836.0, 535.0), 1.36, GROUND_Z + 80)
	_add_sprite_px(ground_layer, "TopLanding", "ground/bottom_path.png", Vector2(836.0, 425.0), 0.78, GROUND_Z + 58)
	_add_sprite_px(ground_layer, "StairsToHall", "ground/stairs_left.png", Vector2(836.0, 374.0), 0.74, GROUND_Z + 70)
	_add_sprite_px(ground_layer, "BottomPath", "ground/bottom_path.png", Vector2(836.0, 705.0), 1.0, GROUND_Z + 70)
	_add_sprite_px(ground_layer, "BottomStairs", "ground/stairs_right.png", Vector2(836.0, 820.0), 0.72, GROUND_Z + 78)
	_add_sprite_px(ground_layer, "UpperLeftPad", "ground/right_platform.png", Vector2(545.0, 378.0), 0.86, GROUND_Z + 54)
	_add_sprite_px(ground_layer, "UpperRightPad", "ground/left_platform.png", Vector2(1128.0, 388.0), 0.78, GROUND_Z + 54)

	# Immediate side platforms and bridges, placed from the center outward to match the second reference.
	_add_sprite_px(ground_layer, "LeftRoundPlatform", "ground/left_platform.png", Vector2(515.0, 575.0), 1.08, GROUND_Z + 60)
	_add_sprite_px(ground_layer, "BridgeLeft", "ground/bridge_left.png", Vector2(420.0, 612.0), 1.03, GROUND_Z + 72)
	_add_sprite_px(ground_layer, "RightRoundPlatform", "ground/right_platform.png", Vector2(1160.0, 595.0), 1.18, GROUND_Z + 60)
	_add_sprite_px(ground_layer, "BridgeRight", "ground/bridge_right.png", Vector2(1276.0, 622.0), 1.0, GROUND_Z + 72)
	_add_sprite_px(ground_layer, "SideHallStoneBase", "ground/right_platform.png", Vector2(206.0, 525.0), 1.04, GROUND_Z + 58)
	_add_sprite_px(ground_layer, "LibraryStoneBase", "ground/left_platform.png", Vector2(1450.0, 526.0), 1.0, GROUND_Z + 58)
	_add_sprite_px(ground_layer, "LowerLeftBridge", "ground/bridge_right.png", Vector2(570.0, 742.0), 0.72, GROUND_Z + 74)
	_add_sprite_px(ground_layer, "LowerRightBridge", "ground/bridge_left.png", Vector2(1098.0, 742.0), 0.72, GROUND_Z + 74)
	_add_sprite_px(ground_layer, "BottomMarkerPad", "ground/bottom_path.png", Vector2(836.0, 878.0), 0.68, GROUND_Z + 72)

	_add_y_sprite_px(buildings_layer, "MainHall", "buildings/main_hall.png", Vector2(836.0, 214.0), 0.84, 333.0)
	_add_y_sprite_px(buildings_layer, "Monument", "buildings/monument.png", Vector2(545.0, 307.0), 0.55, 372.0)
	_add_y_sprite_px(buildings_layer, "NoticeBoard", "buildings/notice_board.png", Vector2(1116.0, 344.0), 0.66, 425.0)
	_add_y_sprite_px(buildings_layer, "SideHall", "buildings/side_hall.png", Vector2(195.0, 432.0), 0.8, 498.0)
	_add_y_sprite_px(buildings_layer, "LibraryHall", "buildings/library_hall.png", Vector2(1406.0, 430.0), 0.82, 512.0)

	_add_y_sprite_px(rocks_layer, "UpperLeftRock", "props/rock_03.png", Vector2(646.0, 368.0), 0.46, 424.0)
	_add_y_sprite_px(rocks_layer, "UpperRightRock", "props/rock_02.png", Vector2(1028.0, 370.0), 0.48, 426.0)
	_add_y_sprite_px(props_layer, "LeftWaterfall", "props/waterfall_03.png", Vector2(640.0, 382.0), 0.44, 456.0)
	_add_y_sprite_px(props_layer, "RightWaterfall", "props/waterfall_04.png", Vector2(1032.0, 382.0), 0.46, 456.0)
	_add_y_sprite_px(props_layer, "LeftSmallPool", "props/water_rock_pool.png", Vector2(614.0, 708.0), 0.62, 770.0)
	_add_y_sprite_px(props_layer, "RightSmallPool", "props/water_rock_pool.png", Vector2(1058.0, 708.0), 0.62, 770.0)
	_add_y_sprite_px(props_layer, "LeftLamp", "props/lamp_02.png", Vector2(590.0, 438.0), 0.45, 486.0)
	_add_y_sprite_px(props_layer, "RightLamp", "props/lamp_02.png", Vector2(1085.0, 438.0), 0.45, 486.0)
	_add_y_sprite_px(props_layer, "FrontLampLeft", "props/lamp_01.png", Vector2(703.0, 745.0), 0.44, 802.0)
	_add_y_sprite_px(props_layer, "FrontLampRight", "props/lamp_01.png", Vector2(967.0, 745.0), 0.44, 802.0)
	_add_y_sprite_px(props_layer, "LowerGateLeftLamp", "props/lamp_small.png", Vector2(760.0, 829.0), 0.48, 877.0)
	_add_y_sprite_px(props_layer, "LowerGateRightLamp", "props/lamp_small.png", Vector2(912.0, 829.0), 0.48, 877.0)

	_add_y_sprite_px(fences_back_layer, "RearLeftFence", "fences/fence_short_low.png", Vector2(585.0, 465.0), 0.72, 486.0)
	_add_y_sprite_px(fences_back_layer, "RearRightFence", "fences/fence_short_low.png", Vector2(1088.0, 465.0), 0.72, 486.0)
	_add_y_sprite_px(fences_back_layer, "UpperLeftFence", "fences/fence_short.png", Vector2(706.0, 444.0), 0.64, 480.0)
	_add_y_sprite_px(fences_back_layer, "UpperRightFence", "fences/fence_short.png", Vector2(966.0, 444.0), 0.64, 480.0)
	_add_y_sprite_px(fences_back_layer, "SideHallRearFence", "fences/fence_short_low.png", Vector2(352.0, 497.0), 0.62, 516.0)
	_add_y_sprite_px(fences_back_layer, "LibraryRearFence", "fences/fence_short_low.png", Vector2(1296.0, 497.0), 0.62, 516.0)
	_add_y_sprite_px(fences_back_layer, "LeftBridgeFence", "fences/fence_curve.png", Vector2(640.0, 604.0), 0.72, 634.0)
	_add_y_sprite_px(fences_back_layer, "RightBridgeFence", "fences/fence_curve.png", Vector2(1030.0, 604.0), 0.72, 634.0)

	_add_y_sprite_px(trees_layer, "PinkTree", "props/tree_pink.png", Vector2(280.0, 836.0), 0.8, 914.0)
	_add_y_sprite_px(trees_layer, "GreenTree", "props/tree_green.png", Vector2(1370.0, 838.0), 0.7, 908.0)
	_add_y_sprite_px(trees_layer, "BambooLeft", "props/bamboo.png", Vector2(110.0, 335.0), 0.72, 418.0)
	_add_y_sprite_px(trees_layer, "BambooHallLeft", "props/bamboo.png", Vector2(318.0, 394.0), 0.48, 480.0)
	_add_y_sprite_px(trees_layer, "BambooHallRight", "props/bamboo.png", Vector2(1490.0, 394.0), 0.46, 480.0)
	_add_y_sprite_px(trees_layer, "SmallPinkTreeRight", "props/tree_pink.png", Vector2(1272.0, 386.0), 0.38, 456.0)

	_add_y_sprite_px(rocks_layer, "BottomRightRock", "props/rock_01.png", Vector2(1230.0, 860.0), 0.72, 925.0)
	_add_y_sprite_px(rocks_layer, "BottomLeftRock", "props/rock_02.png", Vector2(520.0, 852.0), 0.62, 910.0)
	_add_y_sprite_px(rocks_layer, "SideHallCliffRock", "props/rock_small.png", Vector2(350.0, 622.0), 0.56, 666.0)
	_add_y_sprite_px(rocks_layer, "LibraryCliffRock", "props/rock_small.png", Vector2(1320.0, 624.0), 0.56, 668.0)
	_add_y_sprite_px(props_layer, "LeftLotus", "props/lotus_02.png", Vector2(585.0, 730.0), 0.62, 750.0)
	_add_y_sprite_px(props_layer, "RightLotus", "props/lotus_02.png", Vector2(1080.0, 730.0), 0.62, 750.0)
	_add_y_sprite_px(props_layer, "LeftLotusSmall", "props/lotus_04.png", Vector2(514.0, 790.0), 0.48, 806.0)
	_add_y_sprite_px(props_layer, "RightLotusSmall", "props/lotus_04.png", Vector2(1160.0, 790.0), 0.48, 806.0)
	_add_y_sprite_px(props_layer, "SideShrubLeft", "props/shrub_small_01.png", Vector2(476.0, 462.0), 0.52, 492.0)
	_add_y_sprite_px(props_layer, "SideShrubRight", "props/shrub_small_02.png", Vector2(1194.0, 462.0), 0.52, 492.0)

	_add_sprite_px(fences_front_layer, "CenterFrontFence", "fences/fence_long.png", Vector2(836.0, 684.0), 0.9, FOREGROUND_Z + 70)
	_add_sprite_px(fences_front_layer, "LeftFrontCurveFence", "fences/fence_curve.png", Vector2(652.0, 672.0), 0.74, FOREGROUND_Z + 62)
	_add_sprite_px(fences_front_layer, "RightFrontCurveFence", "fences/fence_curve.png", Vector2(1020.0, 672.0), 0.74, FOREGROUND_Z + 62)
	_add_sprite_px(fences_front_layer, "SideHallFrontFence", "fences/fence_short.png", Vector2(330.0, 612.0), 0.66, FOREGROUND_Z + 58)
	_add_sprite_px(fences_front_layer, "LibraryFrontFence", "fences/fence_short.png", Vector2(1334.0, 614.0), 0.66, FOREGROUND_Z + 58)
	_add_sprite_px(fences_front_layer, "LowerFrontFence", "fences/fence_long.png", Vector2(836.0, 780.0), 0.78, FOREGROUND_Z + 60)
	_add_sprite_px(tree_tops_layer, "PinkTreeTopMask", "props/tree_pink.png", Vector2(280.0, 836.0), 0.8, FOREGROUND_Z + 48, Color(1.0, 1.0, 1.0, 0.7))


func _build_collision() -> void:
	_add_rect_blocker(building_blockers, "MainHallBlocker", _px(Vector2(836.0, 328.0)), Vector2(270.0, 58.0))
	_add_rect_blocker(building_blockers, "MonumentBlocker", _px(Vector2(545.0, 365.0)), Vector2(74.0, 58.0))
	_add_rect_blocker(building_blockers, "NoticeBoardBlocker", _px(Vector2(1116.0, 423.0)), Vector2(112.0, 42.0))
	_add_rect_blocker(building_blockers, "SideHallBlocker", _px(Vector2(195.0, 495.0)), Vector2(210.0, 72.0))
	_add_rect_blocker(building_blockers, "LibraryHallBlocker", _px(Vector2(1406.0, 512.0)), Vector2(224.0, 76.0))

	_add_rect_blocker(fence_blockers, "CenterFrontFenceBlocker", _px(Vector2(836.0, 684.0)), Vector2(300.0, 18.0))
	_add_rect_blocker(fence_blockers, "RearLeftFenceBlocker", _px(Vector2(585.0, 466.0)), Vector2(90.0, 16.0))
	_add_rect_blocker(fence_blockers, "RearRightFenceBlocker", _px(Vector2(1088.0, 466.0)), Vector2(90.0, 16.0))
	_add_rect_blocker(fence_blockers, "LeftFrontCurveFenceBlocker", _px(Vector2(652.0, 672.0)), Vector2(110.0, 18.0), -0.14)
	_add_rect_blocker(fence_blockers, "RightFrontCurveFenceBlocker", _px(Vector2(1020.0, 672.0)), Vector2(110.0, 18.0), 0.14)

	_add_rect_blocker(prop_blockers, "PinkTreeTrunkBlocker", _px(Vector2(280.0, 912.0)), Vector2(46.0, 42.0))
	_add_rect_blocker(prop_blockers, "GreenTreeTrunkBlocker", _px(Vector2(1370.0, 908.0)), Vector2(42.0, 42.0))
	_add_rect_blocker(prop_blockers, "BambooBlocker", _px(Vector2(110.0, 417.0)), Vector2(44.0, 42.0))
	_add_rect_blocker(prop_blockers, "BottomRightRockBlocker", _px(Vector2(1230.0, 925.0)), Vector2(82.0, 42.0))
	_add_rect_blocker(prop_blockers, "BottomLeftRockBlocker", _px(Vector2(520.0, 910.0)), Vector2(72.0, 38.0))
	_add_rect_blocker(prop_blockers, "SideHallCliffRockBlocker", _px(Vector2(350.0, 666.0)), Vector2(54.0, 28.0))
	_add_rect_blocker(prop_blockers, "LibraryCliffRockBlocker", _px(Vector2(1320.0, 668.0)), Vector2(54.0, 28.0))

	_add_rect_blocker(cliff_blockers, "LeftBridgeUpperRail", _px(Vector2(585.0, 510.0)), Vector2(220.0, 14.0), 0.2)
	_add_rect_blocker(cliff_blockers, "LeftBridgeLowerRail", _px(Vector2(505.0, 642.0)), Vector2(220.0, 14.0), 0.2)
	_add_rect_blocker(cliff_blockers, "RightBridgeUpperRail", _px(Vector2(1088.0, 510.0)), Vector2(220.0, 14.0), -0.2)
	_add_rect_blocker(cliff_blockers, "RightBridgeLowerRail", _px(Vector2(1180.0, 650.0)), Vector2(220.0, 14.0), -0.2)
	_add_rect_blocker(cliff_blockers, "SideHallLowerCliff", _px(Vector2(298.0, 676.0)), Vector2(260.0, 18.0), 0.12)
	_add_rect_blocker(cliff_blockers, "LibraryLowerCliff", _px(Vector2(1390.0, 676.0)), Vector2(260.0, 18.0), -0.12)


func _add_sprite_px(parent: Node2D, node_name: String, texture_path: String, pixel_position: Vector2, sprite_scale: float, sprite_z: int, sprite_modulate: Color = Color.WHITE) -> Sprite2D:
	return _add_sprite(parent, node_name, texture_path, _px(pixel_position), sprite_scale, sprite_z, sprite_modulate)


func _add_y_sprite_px(parent: Node2D, node_name: String, texture_path: String, pixel_position: Vector2, sprite_scale: float, baseline_pixel_y: float) -> Sprite2D:
	return _add_sprite_px(parent, node_name, texture_path, pixel_position, sprite_scale, _baseline_y(baseline_pixel_y))


func _add_sprite(parent: Node2D, node_name: String, texture_path: String, sprite_position: Vector2, sprite_scale: float, sprite_z: int, sprite_modulate: Color = Color.WHITE) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = _textures.get(texture_path, null) as Texture2D
	sprite.position = sprite_position
	sprite.scale = Vector2.ONE * sprite_scale
	sprite.modulate = sprite_modulate * SPRITE_TINT
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.z_as_relative = false
	sprite.z_index = clampi(sprite_z, CANVAS_Z_MIN, CANVAS_Z_MAX)
	parent.add_child(sprite)
	return sprite


func _add_y_sprite(parent: Node2D, node_name: String, texture_path: String, sprite_position: Vector2, sprite_scale: float, baseline_y: int) -> Sprite2D:
	return _add_sprite(parent, node_name, texture_path, sprite_position, sprite_scale, baseline_y)


func _add_rect_blocker(parent: Node2D, node_name: String, blocker_position: Vector2, blocker_size: Vector2, blocker_rotation: float = 0.0) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = node_name
	body.position = blocker_position
	body.rotation = blocker_rotation
	body.collision_layer = COLLISION_LAYER
	body.collision_mask = 0
	body.add_to_group(MAP_COLLIDER_GROUP)

	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = blocker_size
	shape.shape = rectangle
	body.add_child(shape)
	parent.add_child(body)
	return body
