extends Area2D
class_name PlayerProjectile

var direction := Vector2.RIGHT
var speed := 420.0
var remaining_distance := 400.0
var damage := 16.0
var hits_left := 1
var knockback_force := 240.0

var _hit_targets: Dictionary = {}

@onready var visual: Sprite2D = $Visual


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.texture = load("res://art/sprites/projectile_player.png") as Texture2D
	body_entered.connect(_on_body_entered)


func setup(
	shot_damage: float,
	shot_direction: Vector2,
	shot_speed: float,
	shot_range: float,
	shot_pierce: int,
	shot_knockback: float
) -> void:
	damage = shot_damage
	direction = shot_direction.normalized()
	speed = shot_speed
	remaining_distance = shot_range
	hits_left = shot_pierce + 1
	knockback_force = shot_knockback
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	var step := speed * delta
	position += direction * step
	remaining_distance -= step
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
	hits_left -= 1
	if hits_left <= 0:
		queue_free()
