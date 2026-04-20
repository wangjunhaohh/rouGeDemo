extends Area2D
class_name EnemyProjectile

const PROJECTILE_VISUAL_SCALE := 0.62

var direction := Vector2.RIGHT
var speed := 220.0
var damage := 8.0
var lifetime := 5.0
var _pending_tint: Color = Color(1.0, 1.0, 1.0, 1.0)

@onready var visual: Sprite2D = $Visual


func _ready() -> void:
	collision_layer = 0
	collision_mask = 5
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.texture = load("res://art/sprites/projectile_enemy.png") as Texture2D
	visual.scale = Vector2.ONE * PROJECTILE_VISUAL_SCALE
	visual.modulate = _pending_tint
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func setup(shot_direction: Vector2, shot_speed: float, shot_damage: float, tint: Color) -> void:
	direction = shot_direction.normalized()
	speed = shot_speed
	damage = shot_damage
	_pending_tint = tint
	if visual != null:
		visual.modulate = _pending_tint
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	var target: Player = body as Player
	if target == null:
		return
	target.apply_contact_damage(damage, global_position)
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	if not area.is_in_group("player_hurtbox"):
		return
	var target: Player = area.get_meta("player_ref", null) as Player
	if target == null:
		target = area.get_parent() as Player
	if target == null:
		return
	target.apply_contact_damage(damage, global_position)
	queue_free()
