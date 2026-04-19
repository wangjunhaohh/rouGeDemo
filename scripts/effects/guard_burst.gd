extends Area2D
class_name GuardBurst

var damage := 12.0
var max_radius := 96.0
var duration := 0.2
var knockback_force := 280.0
var tint := Color(0.96, 0.86, 0.58, 1.0)

var _elapsed := 0.0
var _hit_targets: Dictionary = {}

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var fill: Polygon2D = $Fill
@onready var ring: Line2D = $Ring


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	_update_radius(12.0)
	fill.color = Color(tint.r, tint.g, tint.b, 0.22)
	ring.default_color = Color(tint.r, tint.g, tint.b, 0.9)


func setup(next_damage: float, next_radius: float, next_duration: float, next_knockback: float, next_tint: Color) -> void:
	damage = next_damage
	max_radius = next_radius
	duration = next_duration
	knockback_force = next_knockback
	tint = next_tint


func _physics_process(delta: float) -> void:
	_elapsed += delta
	var progress: float = minf(_elapsed / duration, 1.0)
	var radius: float = lerpf(12.0, max_radius, progress)
	_update_radius(radius)
	var alpha: float = 1.0 - progress
	fill.color = Color(tint.r, tint.g, tint.b, 0.24 * alpha)
	ring.default_color = Color(tint.r, tint.g, tint.b, 0.92 * alpha)

	for body in get_overlapping_bodies():
		if not body.is_in_group("enemies"):
			continue
		var enemy: Enemy = body as Enemy
		if enemy == null:
			continue
		var target_id: int = enemy.get_instance_id()
		if _hit_targets.has(target_id):
			continue
		_hit_targets[target_id] = true
		enemy.take_damage(damage, global_position, knockback_force)

	if progress >= 1.0:
		queue_free()


func _update_radius(radius: float) -> void:
	var circle := collision_shape.shape as CircleShape2D
	if circle != null:
		circle.radius = radius
	var points: PackedVector2Array = _build_circle(radius, 18)
	fill.polygon = points
	var ring_points := PackedVector2Array()
	ring_points.append_array(points)
	ring_points.append(points[0])
	ring.points = ring_points


func _build_circle(radius: float, point_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(point_count):
		var angle := TAU * float(index) / float(point_count)
		points.append(Vector2.RIGHT.rotated(angle) * radius)
	return points
