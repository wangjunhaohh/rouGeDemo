extends Node2D
class_name BombardmentCircleEffect

var caster: Node2D
var damage := 12.0
var circle_radius := 180.0
var explosion_radius := 45.0
var duration := 4.0
var tick_interval := 0.35
var warning_delay := 0.28
var burn_damage := 0.0
var burn_duration := 0.0
var slow_duration := 0.0
var slow_amount := 1.0
var tint := Color(0.54, 0.78, 1.0, 1.0)

var _elapsed := 0.0
var _tick_time_left := 0.0
var _pending_points: Array[Dictionary] = []
var _explosions: Array[Dictionary] = []


func setup(next_caster: Node2D, next_damage: float, next_circle_radius: float, next_explosion_radius: float, next_duration: float, next_tick_interval: float, next_warning_delay: float, next_burn_damage: float, next_burn_duration: float, next_slow_duration: float, next_slow_amount: float, next_tint: Color) -> void:
	caster = next_caster
	damage = next_damage
	circle_radius = next_circle_radius
	explosion_radius = next_explosion_radius
	duration = next_duration
	tick_interval = maxf(next_tick_interval, 0.08)
	warning_delay = maxf(next_warning_delay, 0.05)
	burn_damage = next_burn_damage
	burn_duration = next_burn_duration
	slow_duration = next_slow_duration
	slow_amount = next_slow_amount
	tint = next_tint


func _process(delta: float) -> void:
	_elapsed += delta
	if is_instance_valid(caster):
		global_position = caster.global_position
	if _elapsed <= duration:
		_tick_time_left -= delta
		if _tick_time_left <= 0.0:
			_spawn_warning_point()
			_tick_time_left += tick_interval
	_update_pending_points(delta)
	_update_explosions(delta)
	queue_redraw()
	if _elapsed >= duration and _pending_points.is_empty() and _explosions.is_empty():
		queue_free()


func _draw() -> void:
	var progress := clampf(_elapsed / maxf(duration, 0.01), 0.0, 1.0)
	var ring_alpha := 0.75 * (1.0 - progress * 0.45)
	draw_arc(Vector2.ZERO, circle_radius, 0.0, TAU, 64, Color(tint.r, tint.g, tint.b, ring_alpha), 3.0)
	draw_circle(Vector2.ZERO, circle_radius, Color(tint.r, tint.g, tint.b, 0.06))
	for point in _pending_points:
		var alpha: float = clampf(float(point.get("delay", 0.0)) / warning_delay, 0.0, 1.0)
		var offset: Vector2 = point.get("offset", Vector2.ZERO)
		draw_arc(offset, explosion_radius, 0.0, TAU, 24, Color(1.0, 0.74, 0.36, 0.9 * alpha), 2.0)
	for blast in _explosions:
		var time_left: float = float(blast.get("time_left", 0.0))
		var alpha: float = clampf(time_left / 0.2, 0.0, 1.0)
		var offset: Vector2 = blast.get("offset", Vector2.ZERO)
		var radius_value: float = lerpf(explosion_radius * 0.35, explosion_radius, 1.0 - alpha)
		draw_circle(offset, radius_value, Color(0.72, 0.88, 1.0, 0.22 * alpha))
		draw_arc(offset, radius_value, 0.0, TAU, 24, Color(0.88, 0.96, 1.0, 0.85 * alpha), 3.0)


func _spawn_warning_point() -> void:
	var angle := randf() * TAU
	var distance := sqrt(randf()) * circle_radius
	_pending_points.append({
		"offset": Vector2.RIGHT.rotated(angle) * distance,
		"delay": warning_delay
	})


func _update_pending_points(delta: float) -> void:
	for index in range(_pending_points.size() - 1, -1, -1):
		var point: Dictionary = _pending_points[index]
		point["delay"] = float(point.get("delay", 0.0)) - delta
		if float(point.get("delay", 0.0)) <= 0.0:
			var offset: Vector2 = point.get("offset", Vector2.ZERO)
			_apply_explosion(global_position + offset)
			_explosions.append({"offset": offset, "time_left": 0.2})
			_pending_points.remove_at(index)
		else:
			_pending_points[index] = point


func _update_explosions(delta: float) -> void:
	for index in range(_explosions.size() - 1, -1, -1):
		var blast: Dictionary = _explosions[index]
		blast["time_left"] = float(blast.get("time_left", 0.0)) - delta
		if float(blast.get("time_left", 0.0)) <= 0.0:
			_explosions.remove_at(index)
		else:
			_explosions[index] = blast


func _apply_explosion(world_position: Vector2) -> void:
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy: Enemy = enemy_node as Enemy
		if enemy == null or not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		if enemy.global_position.distance_to(world_position) > explosion_radius:
			continue
		enemy.take_damage(damage, world_position, 120.0)
		if burn_damage > 0.0 and burn_duration > 0.0:
			enemy.apply_status_effect("burn", burn_duration, burn_damage, 1, 4)
		if slow_duration > 0.0:
			enemy.apply_status_effect("slow", slow_duration, slow_amount)
