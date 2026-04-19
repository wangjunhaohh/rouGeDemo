extends Area2D
class_name PlayerProjectile

const DEFAULT_PROJECTILE_TEXTURE := preload("res://art/sprites/projectile_player.png")
const PROJECTILE_VISUAL_SCALE := 0.62

var direction := Vector2.RIGHT
var speed := 420.0
var remaining_distance := 400.0
var damage := 16.0
var hits_left := 1
var knockback_force := 240.0
var tint := Color(1.0, 1.0, 1.0, 1.0)
var status_type := ""
var status_duration := 0.0
var status_value := 0.0
var projectile_texture: Texture2D = DEFAULT_PROJECTILE_TEXTURE
var projectile_visual_scale := PROJECTILE_VISUAL_SCALE
var projectile_spin_speed := 0.0

var _hit_targets: Dictionary = {}

@onready var visual: Sprite2D = $Visual


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.texture = projectile_texture
	visual.scale = Vector2.ONE * projectile_visual_scale
	visual.modulate = tint
	body_entered.connect(_on_body_entered)


func setup(
	shot_damage: float,
	shot_direction: Vector2,
	shot_speed: float,
	shot_range: float,
	shot_pierce: int,
	shot_knockback: float,
	shot_tint: Color = Color(1.0, 1.0, 1.0, 1.0),
	shot_texture: Texture2D = DEFAULT_PROJECTILE_TEXTURE,
	shot_visual_scale: float = PROJECTILE_VISUAL_SCALE,
	shot_spin_speed: float = 0.0
) -> void:
	damage = shot_damage
	direction = shot_direction.normalized()
	speed = shot_speed
	remaining_distance = shot_range
	hits_left = shot_pierce + 1
	knockback_force = shot_knockback
	tint = shot_tint
	projectile_texture = shot_texture if shot_texture != null else DEFAULT_PROJECTILE_TEXTURE
	projectile_visual_scale = shot_visual_scale
	projectile_spin_speed = shot_spin_speed
	rotation = direction.angle()
	if visual != null:
		visual.texture = projectile_texture
		visual.scale = Vector2.ONE * projectile_visual_scale
		visual.modulate = tint


func set_status_effect(next_status_type: String, next_duration: float, next_value: float) -> void:
	status_type = next_status_type
	status_duration = next_duration
	status_value = next_value


func _physics_process(delta: float) -> void:
	var step := speed * delta
	position += direction * step
	remaining_distance -= step
	if projectile_spin_speed != 0.0:
		rotation += projectile_spin_speed * delta
	if remaining_distance <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("enemies"):
		return
	var target: Enemy = body as Enemy
	if target == null:
		return
	var target_id: int = target.get_instance_id()
	if _hit_targets.has(target_id):
		return
	_hit_targets[target_id] = true
	target.take_damage(damage, global_position, knockback_force)
	if not status_type.is_empty():
		target.apply_status_effect(status_type, status_duration, status_value)
	hits_left -= 1
	if hits_left <= 0:
		queue_free()
