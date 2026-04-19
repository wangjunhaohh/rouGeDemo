extends Area2D
class_name ScorchField

var radius := 78.0
var duration := 3.0
var tick_interval := 0.5
var tick_damage := 2.0
var burn_duration := 2.4
var burn_damage := 4.0
var slow_duration := 0.9
var slow_amount := 0.82
var tint := Color(0.98, 0.44, 0.22, 1.0)

var _time_left := 0.0
var _tick_left := 0.0
var _pulse_time := 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var fill: Polygon2D = $Fill
@onready var ring: Line2D = $Ring


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	_time_left = duration
	_tick_left = 0.12
	_update_shape(radius)


func setup(
	next_radius: float,
	next_duration: float,
	next_tick_interval: float,
	next_tick_damage: float,
	next_burn_duration: float,
	next_burn_damage: float,
	next_slow_duration: float,
	next_slow_amount: float,
	next_tint: Color
) -> void:
	radius = next_radius
	duration = next_duration
	tick_interval = next_tick_interval
	tick_damage = next_tick_damage
	burn_duration = next_burn_duration
	burn_damage = next_burn_damage
	slow_duration = next_slow_duration
	slow_amount = next_slow_amount
	tint = next_tint


func _physics_process(delta: float) -> void:
	_time_left = maxf(_time_left - delta, 0.0)
	_tick_left = maxf(_tick_left - delta, 0.0)
	_pulse_time += delta

	var life_ratio: float = 0.0
	if duration > 0.0:
		life_ratio = _time_left / duration
	var pulse_alpha: float = 0.52 + sin(_pulse_time * 6.0) * 0.1
	fill.color = Color(tint.r, tint.g, tint.b, clampf(0.18 + pulse_alpha * 0.18 * life_ratio, 0.06, 0.34))
	ring.default_color = Color(tint.r, tint.g, tint.b, clampf(0.4 + life_ratio * 0.45, 0.2, 0.9))

	if _tick_left <= 0.0:
		_tick_left = tick_interval
		_apply_tick()

	if _time_left <= 0.0:
		queue_free()


func _apply_tick() -> void:
	for body in get_overlapping_bodies():
		if not body.is_in_group("enemies"):
			continue
		var enemy: Enemy = body as Enemy
		if enemy == null:
			continue
		enemy.take_damage(tick_damage, global_position, 0.0)
		enemy.apply_status_effect("burn", burn_duration, burn_damage)
		if slow_duration > 0.0 and slow_amount < 1.0:
			enemy.apply_status_effect("slow", slow_duration, slow_amount)


func _update_shape(next_radius: float) -> void:
	var circle := collision_shape.shape as CircleShape2D
	if circle != null:
		circle.radius = next_radius
	var points: PackedVector2Array = _build_circle(next_radius, 24)
	fill.polygon = points
	var ring_points := PackedVector2Array()
	ring_points.append_array(points)
	ring_points.append(points[0])
	ring.points = ring_points


func _build_circle(next_radius: float, point_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(point_count):
		var angle := TAU * float(index) / float(point_count)
		points.append(Vector2.RIGHT.rotated(angle) * next_radius)
	return points
