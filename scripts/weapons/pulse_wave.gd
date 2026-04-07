extends Area2D
class_name PulseWave

var damage := 18.0
var max_radius := 96.0
var duration := 0.35
var knockback_force := 180.0

var _elapsed := 0.0
var _hit_targets: Dictionary = {}

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Polygon2D = $Visual


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	_update_radius(12.0)


func setup(pulse_damage: float, pulse_radius: float, pulse_duration: float, pulse_knockback: float) -> void:
	damage = pulse_damage
	max_radius = pulse_radius
	duration = pulse_duration
	knockback_force = pulse_knockback


func _physics_process(delta: float) -> void:
	_elapsed += delta
	var progress: float = minf(_elapsed / duration, 1.0)
	var radius: float = lerpf(12.0, max_radius, progress)
	_update_radius(radius)
	modulate.a = 0.85 - progress * 0.7

	for body in get_overlapping_bodies():
		if not body.is_in_group("enemies"):
			continue
		var enemy_body: Enemy = body as Enemy
		if enemy_body == null:
			continue
		var target_id: int = enemy_body.get_instance_id()
		if _hit_targets.has(target_id):
			continue
		_hit_targets[target_id] = true
		enemy_body.take_damage(damage, global_position, knockback_force)

	if progress >= 1.0:
		queue_free()


func _update_radius(radius: float) -> void:
	var circle := collision_shape.shape as CircleShape2D
	if circle != null:
		circle.radius = radius
	visual.polygon = _build_circle(radius, 24)


func _build_circle(radius: float, point_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(point_count):
		var angle := TAU * float(index) / float(point_count)
		points.append(Vector2.RIGHT.rotated(angle) * radius)
	return points
