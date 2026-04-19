extends Area2D
class_name ScorchOrb

const SCORCH_FIELD_SCENE := preload("res://scenes/effects/scorch_field.tscn")

signal effect_spawned(effect: Node2D)

var direction := Vector2.RIGHT
var speed := 250.0
var remaining_distance := 260.0
var impact_damage := 10.0
var knockback_force := 120.0
var field_radius := 82.0
var field_duration := 3.0
var field_tick_interval := 0.5
var field_tick_damage := 2.0
var burn_duration := 2.4
var burn_damage := 4.0
var slow_duration := 0.9
var slow_amount := 0.82
var tint := Color(0.96, 0.44, 0.24, 1.0)

var _exploded := false

@onready var visual: Sprite2D = $Visual


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.texture = load("res://art/sprites/projectile_player.png") as Texture2D
	visual.scale = Vector2.ONE * 0.82
	visual.modulate = tint
	body_entered.connect(_on_body_entered)


func setup(
	next_direction: Vector2,
	next_speed: float,
	next_range: float,
	next_impact_damage: float,
	next_knockback: float,
	next_field_radius: float,
	next_field_duration: float,
	next_field_tick_interval: float,
	next_field_tick_damage: float,
	next_burn_duration: float,
	next_burn_damage: float,
	next_slow_duration: float,
	next_slow_amount: float,
	next_tint: Color
) -> void:
	direction = next_direction.normalized()
	speed = next_speed
	remaining_distance = next_range
	impact_damage = next_impact_damage
	knockback_force = next_knockback
	field_radius = next_field_radius
	field_duration = next_field_duration
	field_tick_interval = next_field_tick_interval
	field_tick_damage = next_field_tick_damage
	burn_duration = next_burn_duration
	burn_damage = next_burn_damage
	slow_duration = next_slow_duration
	slow_amount = next_slow_amount
	tint = next_tint
	rotation = direction.angle()
	if visual != null:
		visual.modulate = tint


func _physics_process(delta: float) -> void:
	var step := speed * delta
	position += direction * step
	remaining_distance -= step
	rotation += delta * 4.6
	if remaining_distance <= 0.0:
		_explode()


func _on_body_entered(body: Node) -> void:
	if _exploded or not body.is_in_group("enemies"):
		return
	var enemy: Enemy = body as Enemy
	if enemy != null:
		enemy.take_damage(impact_damage, global_position, knockback_force)
	_explode()


func _explode() -> void:
	if _exploded:
		return
	_exploded = true
	var field := SCORCH_FIELD_SCENE.instantiate()
	field.global_position = global_position
	field.setup(
		field_radius,
		field_duration,
		field_tick_interval,
		field_tick_damage,
		burn_duration,
		burn_damage,
		slow_duration,
		slow_amount,
		tint
	)
	effect_spawned.emit(field)
	queue_free()
