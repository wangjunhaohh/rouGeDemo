extends Node2D
class_name SlashSequenceEffect

var caster: Node2D
var damage := 10.0
var radius := 160.0
var slash_count := 5
var duration := 1.2
var max_hit_per_target := 4
var knockback_force := 170.0
var tint := Color(0.84, 0.94, 1.0, 1.0)

var _elapsed := 0.0
var _visual_total_duration := 0.0
var _visual_hold_time := 0.0
var _next_slash_index := 0
var _hit_counts: Dictionary = {}
var _slash_marks: Array[Dictionary] = []
var _visual_sprite: AnimatedSprite2D
var _uses_visual_frames := false


func setup(next_caster: Node2D, next_damage: float, next_radius: float, next_slash_count: int, next_duration: float, next_max_hit_per_target: int, next_knockback_force: float, next_tint: Color, visual_config: Dictionary = {}) -> void:
	caster = next_caster
	damage = next_damage
	radius = next_radius
	slash_count = maxi(next_slash_count, 1)
	duration = maxf(next_duration, 0.1)
	max_hit_per_target = maxi(next_max_hit_per_target, 1)
	knockback_force = next_knockback_force
	tint = next_tint
	_apply_visual_config(visual_config)


func _physics_process(delta: float) -> void:
	_elapsed += delta
	if is_instance_valid(caster):
		global_position = caster.global_position
	if _uses_visual_frames and _visual_sprite != null and _visual_sprite.visible and _elapsed >= _visual_total_duration + _visual_hold_time:
		_visual_sprite.visible = false
	var interval: float = duration / float(slash_count)
	while _next_slash_index < slash_count and _elapsed >= interval * float(_next_slash_index):
		_apply_slash(_next_slash_index)
		_next_slash_index += 1
	for index in range(_slash_marks.size() - 1, -1, -1):
		var mark: Dictionary = _slash_marks[index]
		mark["time_left"] = float(mark.get("time_left", 0.0)) - delta
		if float(mark.get("time_left", 0.0)) <= 0.0:
			_slash_marks.remove_at(index)
		else:
			_slash_marks[index] = mark
	queue_redraw()
	var lifetime := maxf(duration + 0.22, _visual_total_duration + 0.05)
	if _elapsed >= lifetime and _slash_marks.is_empty():
		queue_free()


func _draw() -> void:
	if _uses_visual_frames:
		return
	var ring_color := Color(tint.r, tint.g, tint.b, 0.18)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, ring_color, 2.0)
	for mark in _slash_marks:
		var alpha: float = clampf(float(mark.get("time_left", 0.0)) / 0.18, 0.0, 1.0)
		var color := Color(tint.r, tint.g, tint.b, 0.9 * alpha)
		var angle: float = float(mark.get("angle", 0.0))
		var direction := Vector2.RIGHT.rotated(angle)
		var tangent := direction.rotated(PI * 0.5)
		var center: Vector2 = direction * radius * 0.36
		draw_line(center - tangent * radius * 0.58, center + tangent * radius * 0.58, color, 5.0)


func _apply_slash(slash_index: int) -> void:
	var angle := TAU * float(slash_index) / float(slash_count) + randf_range(-0.22, 0.22)
	if not _uses_visual_frames:
		_slash_marks.append({"angle": angle, "time_left": 0.18})
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy: Enemy = enemy_node as Enemy
		if enemy == null or not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		if enemy.global_position.distance_to(global_position) > radius:
			continue
		var target_id: int = enemy.get_instance_id()
		var current_hits: int = int(_hit_counts.get(target_id, 0))
		if current_hits >= max_hit_per_target:
			continue
		_hit_counts[target_id] = current_hits + 1
		enemy.take_damage(damage, global_position, knockback_force)


func _apply_visual_config(visual_config: Dictionary) -> void:
	var sprite_frames := visual_config.get("sprite_frames", null) as SpriteFrames
	if sprite_frames == null:
		return
	var animation_name := String(visual_config.get("animation", "cast"))
	if animation_name.is_empty() or not sprite_frames.has_animation(animation_name):
		var names := sprite_frames.get_animation_names()
		if names.is_empty():
			return
		animation_name = String(names[0])
	if sprite_frames.get_frame_count(animation_name) <= 0:
		return

	_uses_visual_frames = true
	_visual_sprite = AnimatedSprite2D.new()
	_visual_sprite.sprite_frames = sprite_frames
	_visual_sprite.animation = animation_name
	_visual_sprite.centered = true
	_visual_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_visual_sprite.z_index = int(visual_config.get("z_index", 0))
	var base_size := maxf(float(visual_config.get("base_size", 384.0)), 1.0)
	var radius_scale := maxf(float(visual_config.get("radius_scale", 2.0)), 0.1)
	_visual_sprite.scale = Vector2.ONE * (radius * radius_scale / base_size)
	var alpha := clampf(float(visual_config.get("alpha", 1.0)), 0.0, 1.0)
	_visual_sprite.modulate = Color(1.0, 1.0, 1.0, alpha)
	_visual_sprite.speed_scale = maxf(float(visual_config.get("speed_scale", 1.0)), 0.05)
	_visual_hold_time = maxf(float(visual_config.get("hold_time", 0.0)), 0.0)
	add_child(_visual_sprite)
	_visual_sprite.play(animation_name)

	var frame_count := sprite_frames.get_frame_count(animation_name)
	var animation_speed := maxf(sprite_frames.get_animation_speed(animation_name), 1.0)
	_visual_total_duration = float(frame_count) / (animation_speed * _visual_sprite.speed_scale)
