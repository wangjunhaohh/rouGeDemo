extends Control
class_name InkCloudScroll

const CLOUD_TEXTURE := preload("res://art/ui/branch_cloud_layer.png")
const STRIP_HEIGHT := 6.0

@export var drift_speed := 26.0
@export var circle_radius_scale := 0.37

var _offset := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(delta: float) -> void:
	_offset += drift_speed * delta
	queue_redraw()


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	if CLOUD_TEXTURE == null:
		return
	var center := size * 0.5
	var radius := minf(size.x, size.y) * circle_radius_scale
	var texture_size := CLOUD_TEXTURE.get_size()
	var texture_scale := (radius * 1.28) / texture_size.y
	var draw_width := texture_size.x * texture_scale
	var draw_height := texture_size.y * texture_scale
	var normalized_offset := fposmod(_offset, draw_width)
	var start_x := center.x - radius - normalized_offset
	var image_y := center.y - radius * 0.12
	while start_x < center.x + radius:
		_draw_cloud_texture_in_circle(Vector2(start_x, image_y), texture_scale, center, radius, texture_size)
		start_x += draw_width


func _draw_cloud_texture_in_circle(origin: Vector2, texture_scale: float, center: Vector2, radius: float, texture_size: Vector2) -> void:
	var top := int(floor(center.y - radius))
	var bottom := int(ceil(center.y + radius))
	var y := float(top)
	while y < float(bottom):
		var strip_height := minf(STRIP_HEIGHT, float(bottom) - y)
		var local_y := y + strip_height * 0.5 - center.y
		var chord := sqrt(maxf(radius * radius - local_y * local_y, 0.0))
		var clip_left := center.x - chord
		var clip_right := center.x + chord
		var image_left := origin.x
		var image_right := origin.x + texture_size.x * texture_scale
		var visible_left := maxf(clip_left, image_left)
		var visible_right := minf(clip_right, image_right)
		var src_y := (y - origin.y) / texture_scale
		if visible_right > visible_left and src_y >= 0.0 and src_y < texture_size.y:
			var dest_rect := Rect2(visible_left, y, visible_right - visible_left, strip_height)
			var src_rect := Rect2(
				(visible_left - image_left) / texture_scale,
				src_y,
				dest_rect.size.x / texture_scale,
				strip_height / texture_scale
			)
			draw_texture_rect_region(CLOUD_TEXTURE, dest_rect, src_rect, Color(1.0, 1.0, 1.0, 0.78))
		y += STRIP_HEIGHT
