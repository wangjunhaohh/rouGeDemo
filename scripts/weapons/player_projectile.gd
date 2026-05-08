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
var status_effects: Array[Dictionary] = []
var damage_vs_status_multiplier := 1.0
var projectile_texture: Texture2D = DEFAULT_PROJECTILE_TEXTURE
var projectile_visual_scale := PROJECTILE_VISUAL_SCALE
var projectile_spin_speed := 0.0
var area_damage_on_impact := false
var area_damage_radius := 0.0
var impact_duration := 0.12

var _hit_targets: Dictionary = {}
var _impacting := false
var _impact_time_left := 0.0
var _flight_animation := "flight"
var _impact_animation := "impact"
var _animated_visual: AnimatedSprite2D

@onready var visual: Sprite2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.texture = projectile_texture
	visual.scale = Vector2.ONE * projectile_visual_scale
	visual.modulate = tint
	visual.visible = _animated_visual == null
	_play_flight_animation()
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
		visual.visible = _animated_visual == null


func apply_projectile_visual_config(config: Dictionary) -> void:
	projectile_visual_scale = float(config.get("visual_scale", projectile_visual_scale))
	projectile_spin_speed = float(config.get("spin", projectile_spin_speed))
	area_damage_on_impact = bool(config.get("area_damage_on_impact", area_damage_on_impact))
	area_damage_radius = maxf(float(config.get("area_damage_radius", area_damage_radius)), 0.0)
	impact_duration = maxf(float(config.get("impact_duration", impact_duration)), 0.01)
	_flight_animation = String(config.get("flight_animation", _flight_animation))
	_impact_animation = String(config.get("impact_animation", _impact_animation))
	_apply_collision_radius_from_config(float(config.get("collision_radius", 0.0)))

	var sprite_frames := config.get("sprite_frames", null) as SpriteFrames
	if sprite_frames == null:
		return
	var animated_visual := _ensure_animated_visual()
	if animated_visual == null:
		return
	animated_visual.sprite_frames = sprite_frames
	animated_visual.scale = Vector2.ONE * projectile_visual_scale
	animated_visual.modulate = config.get("modulate", Color(1.0, 1.0, 1.0, 1.0)) as Color
	animated_visual.texture_filter = int(config.get("texture_filter", CanvasItem.TEXTURE_FILTER_NEAREST))
	animated_visual.z_index = int(config.get("z_index", 0))
	if visual != null:
		visual.visible = false
	_play_flight_animation()


func clear_status_effects() -> void:
	status_effects.clear()


func add_status_effect(next_status_type: String, next_duration: float, next_value: float, stacks: int = 1, max_stacks: int = -1, chance: float = 1.0) -> void:
	status_effects.append({
		"type": next_status_type,
		"duration": next_duration,
		"value": next_value,
		"stacks": stacks,
		"max_stacks": max_stacks,
		"chance": chance
	})


func set_status_effect(next_status_type: String, next_duration: float, next_value: float) -> void:
	clear_status_effects()
	add_status_effect(next_status_type, next_duration, next_value)


func set_damage_vs_status_multiplier(multiplier: float) -> void:
	damage_vs_status_multiplier = maxf(multiplier, 1.0)


func _physics_process(delta: float) -> void:
	if _impacting:
		_impact_time_left = maxf(_impact_time_left - delta, 0.0)
		if _impact_time_left <= 0.0:
			queue_free()
		return
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
	if area_damage_on_impact:
		_start_area_impact()
		return
	_apply_hit_to_target(target)
	hits_left -= 1
	if hits_left <= 0:
		queue_free()


func _apply_hit_to_target(target: Enemy) -> bool:
	if target == null or not is_instance_valid(target) or target.is_queued_for_deletion():
		return false
	var target_id: int = target.get_instance_id()
	if _hit_targets.has(target_id):
		return false
	_hit_targets[target_id] = true
	var resolved_damage: float = damage
	if damage_vs_status_multiplier > 1.0 and target.has_any_status_effect():
		resolved_damage *= damage_vs_status_multiplier
	target.take_damage(resolved_damage, global_position, knockback_force)
	for payload in status_effects:
		var chance: float = clampf(float(payload.get("chance", 1.0)), 0.0, 1.0)
		if chance < 1.0 and randf() > chance:
			continue
		target.apply_status_effect(
			String(payload.get("type", "")),
			float(payload.get("duration", 0.0)),
			float(payload.get("value", 0.0)),
			int(payload.get("stacks", 1)),
			int(payload.get("max_stacks", -1))
		)
	return true


func _start_area_impact() -> void:
	if _impacting:
		return
	_impacting = true
	speed = 0.0
	set_deferred("monitoring", false)
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	var radius := area_damage_radius
	if radius <= 0.0:
		radius = _current_collision_radius()
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy: Enemy = enemy_node as Enemy
		if enemy == null or not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		if enemy.global_position.distance_to(global_position) > radius:
			continue
		_apply_hit_to_target(enemy)
	_play_impact_animation()
	_impact_time_left = impact_duration


func _ensure_animated_visual() -> AnimatedSprite2D:
	if _animated_visual != null:
		return _animated_visual
	_animated_visual = AnimatedSprite2D.new()
	_animated_visual.name = "AnimatedVisual"
	_animated_visual.centered = true
	add_child(_animated_visual)
	return _animated_visual


func _play_flight_animation() -> void:
	if _animated_visual == null or _animated_visual.sprite_frames == null:
		return
	if not _animated_visual.sprite_frames.has_animation(_flight_animation):
		return
	_animated_visual.play(_flight_animation)


func _play_impact_animation() -> void:
	if _animated_visual == null or _animated_visual.sprite_frames == null:
		return
	if not _animated_visual.sprite_frames.has_animation(_impact_animation):
		return
	_animated_visual.play(_impact_animation)


func _apply_collision_radius_from_config(configured_radius: float = 0.0) -> void:
	var radius := configured_radius
	if radius <= 0.0:
		return
	if collision_shape == null:
		if has_node("CollisionShape2D"):
			collision_shape = $CollisionShape2D
		else:
			return
	if collision_shape.shape == null or not (collision_shape.shape is CircleShape2D):
		return
	collision_shape.shape = collision_shape.shape.duplicate()
	var circle := collision_shape.shape as CircleShape2D
	circle.radius = maxf(radius, 1.0)


func _current_collision_radius() -> float:
	if collision_shape == null or collision_shape.shape == null or not (collision_shape.shape is CircleShape2D):
		return 6.0
	return (collision_shape.shape as CircleShape2D).radius
