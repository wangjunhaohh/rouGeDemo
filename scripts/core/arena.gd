extends Node2D

const ARENA_TILE := preload("res://art/backgrounds/arena_tile.png")

@export var arena_size := Vector2(3200.0, 3200.0)
@export var cell_size := 64.0
@export var background_color := Color(0.07, 0.08, 0.1, 1.0)
@export var grid_color := Color(0.12, 0.14, 0.18, 1.0)
@export var border_color := Color(0.3, 0.34, 0.4, 1.0)


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var half_size := arena_size * 0.5
	var rect := Rect2(-half_size, arena_size)
	draw_rect(rect, background_color, true)
	draw_texture_rect(ARENA_TILE, rect, true)

	var start_x := int(-half_size.x)
	var end_x := int(half_size.x)
	var start_y := int(-half_size.y)
	var end_y := int(half_size.y)

	var x := start_x
	while x <= end_x:
		draw_line(Vector2(x, start_y), Vector2(x, end_y), grid_color, 1.0)
		x += int(cell_size)

	var y := start_y
	while y <= end_y:
		draw_line(Vector2(start_x, y), Vector2(end_x, y), grid_color, 1.0)
		y += int(cell_size)

	draw_rect(rect, border_color, false, 4.0)
