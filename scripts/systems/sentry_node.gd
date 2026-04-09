extends Node2D
class_name SentryNode

var duration := 8.0
var fire_interval := 0.8
var attack_range := 340.0
var damage := 10.0
var knockback_force := 120.0
var accent_color := Color(0.58, 0.95, 1.0, 1.0)

var _time_left := 0.0
var _fire_left := 0.0
var _beam_time_left := 0.0

@onready var base: Sprite2D = $Base
@onready var glow: Sprite2D = $Glow
@onready var beam: Line2D = $Beam


func _ready() -> void:
	_time_left = duration
	_fire_left = 0.2
	base.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	glow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	base.texture = preload("res://art/sprites/weapon_blaster.png")
	glow.texture = preload("res://art/sprites/weapon_flash.png")
	base.modulate = accent_color
	glow.modulate = Color(accent_color.r, accent_color.g, accent_color.b, 0.0)
	beam.default_color = accent_color
	beam.clear_points()


func setup(lifetime: float, interval: float, sentry_damage: float, sentry_range: float, tint: Color) -> void:
	duration = lifetime
	fire_interval = interval
	damage = sentry_damage
	attack_range = sentry_range
	accent_color = tint


func _physics_process(delta: float) -> void:
	_time_left = maxf(_time_left - delta, 0.0)
	_fire_left = maxf(_fire_left - delta, 0.0)
	_beam_time_left = maxf(_beam_time_left - delta, 0.0)
	if _beam_time_left <= 0.0:
		glow.modulate.a = lerpf(glow.modulate.a, 0.0, minf(delta * 14.0, 1.0))
		beam.clear_points()

	base.rotation += delta * 0.45
	glow.rotation -= delta * 1.2
	glow.scale = Vector2.ONE * (1.0 + sin((duration - _time_left) * 4.2) * 0.06)
	if _time_left <= 0.0:
		queue_free()
		return
	if _fire_left > 0.0:
		return

	var target: Enemy = _find_target()
	_fire_left = fire_interval
	if target == null:
		return

	target.take_damage(damage, global_position, knockback_force)
	var local_target: Vector2 = to_local(target.global_position)
	base.rotation = local_target.angle()
	glow.modulate = Color(accent_color.r, accent_color.g, accent_color.b, 0.92)
	beam.clear_points()
	beam.add_point(Vector2.ZERO)
	beam.add_point(local_target)
	_beam_time_left = 0.08


func _find_target() -> Enemy:
	var best_target: Enemy
	var best_distance := attack_range * attack_range
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var current_enemy: Enemy = enemy as Enemy
		if current_enemy == null or not is_instance_valid(current_enemy):
			continue
		var distance_sq: float = global_position.distance_squared_to(current_enemy.global_position)
		if distance_sq > best_distance:
			continue
		best_distance = distance_sq
		best_target = current_enemy
	return best_target
