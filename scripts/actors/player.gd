extends CharacterBody2D
class_name Player

signal projectile_spawned(projectile: Node2D)
signal effect_spawned(effect: Node2D)
signal health_changed(current_health: float, max_health: float)
signal shot_fired(weapon_name: String)
signal died

@export var move_speed := 240.0
@export var max_health := 100.0
@export var acceleration := 1800.0
@export var friction := 2200.0
@export var invulnerability_time := 0.55
@export var pickup_radius := 56.0
@export var arena_half_size := Vector2(1560.0, 1560.0)
@export var projectile_scene: PackedScene
@export var pulse_scene: PackedScene

var current_health := 100.0
var projectile_damage := 16.0
var projectile_cooldown := 0.75
var projectile_speed := 420.0
var projectile_count := 1
var projectile_pierce := 0
var projectile_range := 420.0
var knockback_force := 260.0

var pulse_enabled := false
var pulse_damage := 20.0
var pulse_radius := 108.0
var pulse_cooldown := 3.2
var pulse_knockback := 180.0

var _projectile_timer := 0.0
var _pulse_timer := 0.0
var _invulnerability_left := 0.0
var _last_move_direction := Vector2.RIGHT
var _shake_time_left := 0.0
var _shake_strength := 0.0

@onready var body_visual: Sprite2D = $Body
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	add_to_group("player")
	collision_layer = 1
	collision_mask = 0
	current_health = max_health
	_projectile_timer = projectile_cooldown * 0.3
	_pulse_timer = pulse_cooldown
	_apply_shape()
	health_changed.emit(current_health, max_health)


func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_handle_attack(delta)
	_handle_pulse(delta)
	_handle_invulnerability(delta)
	_update_camera_shake(delta)


func apply_contact_damage(amount: float, source_position: Vector2) -> void:
	if current_health <= 0.0 or _invulnerability_left > 0.0:
		return
	current_health = maxf(current_health - amount, 0.0)
	_invulnerability_left = invulnerability_time
	velocity += (global_position - source_position).normalized() * 160.0
	health_changed.emit(current_health, max_health)
	_trigger_feedback("hurt")
	trigger_camera_shake(8.0, 0.16)
	if current_health <= 0.0:
		died.emit()


func apply_upgrade(upgrade: UpgradeData) -> void:
	_apply_effect(upgrade.effect_type, upgrade.amount)
	if not upgrade.secondary_effect_type.is_empty():
		_apply_effect(upgrade.secondary_effect_type, upgrade.secondary_amount)
	health_changed.emit(current_health, max_health)


func get_pickup_radius() -> float:
	return pickup_radius


func apply_meta_bonus(effect_type: String, amount: float) -> void:
	_apply_effect(effect_type, amount)


func refresh_health_ui() -> void:
	health_changed.emit(current_health, max_health)


func get_build_summary() -> String:
	var pulse_text := "未解锁"
	if pulse_enabled:
		pulse_text = "伤害 %.0f / 冷却 %.1fs" % [pulse_damage, pulse_cooldown]
	return "主武器 %d 发 | %.1fs 冷却 | %.0f 伤害 | 穿透 %d | 脉冲 %s" % [
		projectile_count,
		projectile_cooldown,
		projectile_damage,
		projectile_pierce,
		pulse_text
	]


func _handle_movement(delta: float) -> void:
	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_direction.length() > 0.0:
		_last_move_direction = input_direction.normalized()
		velocity = velocity.move_toward(_last_move_direction * move_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()
	global_position = Vector2(
		clampf(global_position.x, -arena_half_size.x, arena_half_size.x),
		clampf(global_position.y, -arena_half_size.y, arena_half_size.y)
	)
	body_visual.rotation = _last_move_direction.angle()


func _handle_attack(delta: float) -> void:
	if projectile_scene == null:
		return
	_projectile_timer -= delta
	if _projectile_timer > 0.0:
		return

	var targets := _find_targets()
	if targets.is_empty():
		return

	_projectile_timer = projectile_cooldown
	for shot_index in range(projectile_count):
		var target: Node2D = targets[shot_index % targets.size()]
		var direction: Vector2 = (target.global_position - global_position).normalized()
		var projectile: PlayerProjectile = projectile_scene.instantiate() as PlayerProjectile
		projectile.global_position = global_position
		projectile.setup(
			projectile_damage,
			direction,
			projectile_speed,
			projectile_range,
			projectile_pierce,
			knockback_force
		)
		projectile_spawned.emit(projectile)
	shot_fired.emit("projectile")


func _handle_pulse(delta: float) -> void:
	if not pulse_enabled or pulse_scene == null:
		return
	_pulse_timer -= delta
	if _pulse_timer > 0.0:
		return

	_pulse_timer = pulse_cooldown
	var pulse: PulseWave = pulse_scene.instantiate() as PulseWave
	pulse.global_position = global_position
	pulse.setup(pulse_damage, pulse_radius, 0.35, pulse_knockback)
	effect_spawned.emit(pulse)
	shot_fired.emit("pulse")


func _handle_invulnerability(delta: float) -> void:
	if _invulnerability_left > 0.0:
		_invulnerability_left = maxf(_invulnerability_left - delta, 0.0)
		body_visual.modulate = Color(1.0, 0.55, 0.55, 1.0)
	else:
		body_visual.modulate = Color(1.0, 1.0, 1.0, 1.0)


func trigger_camera_shake(strength: float, duration: float) -> void:
	_shake_strength = maxf(_shake_strength, strength)
	_shake_time_left = maxf(_shake_time_left, duration)


func _update_camera_shake(delta: float) -> void:
	if _shake_time_left <= 0.0:
		camera.offset = camera.offset.lerp(Vector2.ZERO, minf(delta * 18.0, 1.0))
		return

	_shake_time_left = maxf(_shake_time_left - delta, 0.0)
	camera.offset = Vector2(randf_range(-_shake_strength, _shake_strength), randf_range(-_shake_strength, _shake_strength))
	_shake_strength = lerpf(_shake_strength, 0.0, minf(delta * 12.0, 1.0))


func _find_targets() -> Array[Node2D]:
	var targets: Array[Node2D] = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node2D and enemy.is_inside_tree() and not enemy.is_queued_for_deletion():
			targets.append(enemy)

	targets.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position)
	)
	return targets


func _apply_effect(effect_type: String, amount: float) -> void:
	match effect_type:
		"projectile_damage":
			projectile_damage += amount
		"projectile_cooldown":
			projectile_cooldown = maxf(0.18, projectile_cooldown + amount)
		"projectile_count":
			projectile_count += int(amount)
		"projectile_pierce":
			projectile_pierce += int(amount)
		"projectile_range":
			projectile_range += amount
		"move_speed":
			move_speed += amount
		"max_health":
			max_health += amount
			current_health = minf(current_health + amount, max_health)
		"pickup_radius":
			pickup_radius += amount
		"unlock_pulse":
			pulse_enabled = true
			_pulse_timer = minf(_pulse_timer, 0.25)
		"pulse_damage":
			pulse_damage += amount
		"pulse_radius":
			pulse_radius += amount
		"pulse_cooldown":
			pulse_cooldown = maxf(0.8, pulse_cooldown + amount)
		_:
			push_warning("Unknown upgrade effect: %s" % effect_type)


func _apply_shape() -> void:
	var circle := collision_shape.shape as CircleShape2D
	if circle != null:
		circle.radius = 14.0
	body_visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body_visual.centered = true
	body_visual.texture = load("res://art/sprites/player.png") as Texture2D


func _trigger_feedback(feedback_name: String) -> void:
	var game: Node = get_tree().get_first_node_in_group("game")
	if game != null and game.has_method("on_player_feedback"):
		game.on_player_feedback(feedback_name, global_position)
