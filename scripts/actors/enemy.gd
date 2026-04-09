extends CharacterBody2D
class_name Enemy

signal defeated(world_position: Vector2, experience_reward: int, enemy_id: String, was_elite: bool, was_boss: bool)
signal projectile_spawned(projectile: Node2D)
signal boss_skill_triggered(skill_name: String, world_position: Vector2, phase: int)

@export var projectile_scene: PackedScene

var data: EnemyData
var player: Player
var enemy_id := ""
var current_health := 1.0
var max_health_runtime := 1.0
var move_speed_runtime := 100.0
var touch_damage_runtime := 8.0
var experience_reward_runtime := 5
var size_runtime := 12.0
var preferred_distance_runtime := 220.0
var projectile_cooldown_runtime := 2.0
var projectile_speed_runtime := 220.0
var projectile_damage_runtime := 8.0
var is_elite := false
var is_boss := false

var _contact_cooldown_left := 0.0
var _shot_cooldown_left := 0.0
var _flash_left := 0.0
var _strafe_sign := 1.0
var _boss_phase := 1
var _boss_skill_cooldown_left := 0.0
var _boss_pattern_index := 0
var _boss_charge_time_left := 0.0
var _boss_charge_direction := Vector2.ZERO
var _burn_time_left := 0.0
var _burn_tick_left := 0.0
var _burn_damage := 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var body_visual: Sprite2D = $Body


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 0


func setup(config: EnemyData, target_player: Player, elite: bool = false) -> void:
	data = config
	player = target_player
	enemy_id = data.enemy_id
	is_elite = elite
	is_boss = data.enemy_id == "boss"
	_strafe_sign = -1.0 if randf() < 0.5 else 1.0
	_boss_phase = 1
	_boss_skill_cooldown_left = 3.8
	_boss_pattern_index = 0
	_boss_charge_time_left = 0.0
	_boss_charge_direction = Vector2.ZERO
	_setup_runtime_stats()
	_apply_data()


func _physics_process(delta: float) -> void:
	if data == null or player == null or not is_instance_valid(player):
		return

	_handle_status_effects(delta)
	if current_health <= 0.0:
		return

	var to_player := player.global_position - global_position
	var distance := to_player.length()
	var direction := Vector2.ZERO

	if is_boss:
		_update_boss_phase()
		_handle_boss_skills(to_player, distance, delta)
		if _boss_charge_time_left > 0.0:
			direction = _boss_charge_direction
			_boss_charge_time_left = maxf(_boss_charge_time_left - delta, 0.0)
		elif distance > preferred_distance_runtime + 42.0:
			direction = to_player.normalized()
		elif distance < preferred_distance_runtime - 36.0:
			direction = -to_player.normalized() * 0.72
		else:
			direction = to_player.normalized().orthogonal() * _strafe_sign
		_handle_shooting(to_player, distance, delta)
	else:
		match data.behavior:
			"shooter":
				if distance > preferred_distance_runtime + 30.0:
					direction = to_player.normalized()
				elif distance < preferred_distance_runtime - 30.0:
					direction = -to_player.normalized()
				else:
					direction = to_player.normalized().orthogonal() * _strafe_sign
				_handle_shooting(to_player, distance, delta)
			_:
				direction = to_player.normalized()

	var speed_multiplier: float = 1.0
	if is_boss and _boss_charge_time_left > 0.0:
		speed_multiplier = 4.6 if _boss_phase >= 2 else 4.0
	velocity = velocity.move_toward(direction * move_speed_runtime * speed_multiplier, move_speed_runtime * 8.0 * speed_multiplier * delta)
	move_and_slide()
	_handle_contact_damage(distance, delta)
	_handle_flash(delta)


func take_damage(amount: float, source_position: Vector2, knockback_force: float) -> void:
	_apply_damage(amount, source_position, knockback_force, true)


func apply_status_effect(status_type: String, duration: float, value: float) -> void:
	match status_type:
		"burn":
			_burn_time_left = maxf(_burn_time_left, duration)
			_burn_tick_left = minf(_burn_tick_left, 0.18) if _burn_tick_left > 0.0 else 0.18
			_burn_damage = maxf(_burn_damage, value)
			_flash_left = maxf(_flash_left, 0.05)


func _apply_damage(amount: float, source_position: Vector2, knockback_force: float, notify_feedback: bool) -> void:
	if current_health <= 0.0:
		return
	current_health -= amount
	_flash_left = 0.08
	velocity += (global_position - source_position).normalized() * knockback_force
	if notify_feedback:
		_notify_hit_feedback(current_health <= 0.0)
	if current_health <= 0.0:
		defeated.emit(global_position, experience_reward_runtime, enemy_id, is_elite, is_boss)
		queue_free()


func _handle_shooting(to_player: Vector2, distance: float, delta: float) -> void:
	if projectile_scene == null:
		return
	if is_boss and _boss_charge_time_left > 0.0:
		return
	_shot_cooldown_left -= delta
	if _shot_cooldown_left > 0.0 or distance > preferred_distance_runtime + 140.0:
		return

	_shot_cooldown_left = projectile_cooldown_runtime
	var projectile: EnemyProjectile = projectile_scene.instantiate() as EnemyProjectile
	projectile.global_position = global_position
	projectile.setup(
		to_player.normalized(),
		projectile_speed_runtime,
		projectile_damage_runtime,
		body_visual.modulate.lightened(0.12)
	)
	projectile_spawned.emit(projectile)


func _handle_boss_skills(to_player: Vector2, _distance: float, delta: float) -> void:
	if not is_boss:
		return
	if _boss_charge_time_left > 0.0:
		return
	_boss_skill_cooldown_left = maxf(_boss_skill_cooldown_left - delta, 0.0)
	if _boss_skill_cooldown_left > 0.0:
		return

	if _boss_phase == 1:
		if _boss_pattern_index % 2 == 0:
			_cast_boss_cone(to_player.normalized(), 5, 0.22, 1.0, 1.0)
			boss_skill_triggered.emit("ember_burst", global_position, _boss_phase)
		else:
			_start_boss_charge(to_player.normalized(), 0.52)
			boss_skill_triggered.emit("ember_charge", global_position, _boss_phase)
		_boss_skill_cooldown_left = 5.0
	else:
		match _boss_pattern_index % 3:
			0:
				_cast_boss_ring(10)
				boss_skill_triggered.emit("ring_burst", global_position, _boss_phase)
			1:
				_start_boss_charge(to_player.normalized(), 0.66)
				boss_skill_triggered.emit("ember_charge", global_position, _boss_phase)
			_:
				boss_skill_triggered.emit("summon_guards", global_position, _boss_phase)
		_boss_skill_cooldown_left = 4.1
	_boss_pattern_index += 1


func _cast_boss_cone(direction: Vector2, projectile_count: int, spread_step: float, speed_scale: float, damage_scale: float) -> void:
	var center_index: float = float(projectile_count - 1) * 0.5
	for index in range(projectile_count):
		var offset: float = (float(index) - center_index) * spread_step
		_spawn_custom_projectile(
			direction.rotated(offset),
			projectile_speed_runtime * speed_scale,
			projectile_damage_runtime * damage_scale,
			Color(1.0, 0.56, 0.48, 1.0)
		)


func _cast_boss_ring(projectile_count: int) -> void:
	for index in range(projectile_count):
		var angle: float = TAU * float(index) / float(projectile_count)
		_spawn_custom_projectile(
			Vector2.RIGHT.rotated(angle),
			projectile_speed_runtime * 1.08,
			projectile_damage_runtime * 1.05,
			Color(1.0, 0.44, 0.34, 1.0)
		)


func _start_boss_charge(direction: Vector2, duration: float) -> void:
	_boss_charge_direction = direction
	_boss_charge_time_left = duration
	_contact_cooldown_left = 0.0


func _spawn_custom_projectile(direction: Vector2, speed: float, damage: float, tint: Color) -> void:
	if projectile_scene == null:
		return
	var projectile: EnemyProjectile = projectile_scene.instantiate() as EnemyProjectile
	projectile.global_position = global_position
	projectile.setup(direction.normalized(), speed, damage, tint)
	projectile_spawned.emit(projectile)


func _handle_contact_damage(distance: float, delta: float) -> void:
	_contact_cooldown_left = maxf(_contact_cooldown_left - delta, 0.0)
	if distance > size_runtime + 18.0 or _contact_cooldown_left > 0.0:
		return
	_contact_cooldown_left = 0.9
	player.apply_contact_damage(touch_damage_runtime, global_position)


func _handle_status_effects(delta: float) -> void:
	if _burn_time_left <= 0.0:
		return
	_burn_time_left = maxf(_burn_time_left - delta, 0.0)
	_burn_tick_left = maxf(_burn_tick_left - delta, 0.0)
	if _burn_tick_left > 0.0:
		return
	_burn_tick_left = 0.42
	_apply_damage(_burn_damage, global_position, 0.0, false)


func _handle_flash(delta: float) -> void:
	if _flash_left > 0.0:
		_flash_left -= delta
		body_visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		body_visual.modulate = _get_display_color()


func _apply_data() -> void:
	if data == null:
		return
	var circle := collision_shape.shape as CircleShape2D
	if circle != null:
		circle.radius = size_runtime
	body_visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body_visual.centered = true
	body_visual.texture = _resolve_texture()
	body_visual.scale = Vector2.ONE * maxf(size_runtime / 32.0, 0.8)
	body_visual.modulate = _get_display_color()


func _setup_runtime_stats() -> void:
	var health_multiplier := 1.0
	var speed_multiplier := 1.0
	var damage_multiplier := 1.0
	var xp_multiplier := 1.0
	var size_multiplier := 1.0
	if is_elite:
		health_multiplier = 2.4
		speed_multiplier = 1.12
		damage_multiplier = 1.3
		xp_multiplier = 2.5
		size_multiplier = 1.18
	if is_boss:
		health_multiplier = 1.0
		speed_multiplier = 1.0
		damage_multiplier = 1.0
		xp_multiplier = 1.0
		size_multiplier = 1.0

	max_health_runtime = data.max_health * health_multiplier
	current_health = max_health_runtime
	move_speed_runtime = data.move_speed * speed_multiplier
	touch_damage_runtime = data.touch_damage * damage_multiplier
	experience_reward_runtime = int(round(data.experience_reward * xp_multiplier))
	size_runtime = data.size * size_multiplier
	preferred_distance_runtime = data.preferred_distance
	projectile_cooldown_runtime = data.projectile_cooldown * (0.92 if is_elite else 1.0)
	projectile_speed_runtime = data.projectile_speed * (1.05 if is_elite else 1.0)
	projectile_damage_runtime = data.projectile_damage * damage_multiplier


func _update_boss_phase() -> void:
	if not is_boss or _boss_phase >= 2:
		return
	if current_health > max_health_runtime * 0.55:
		return
	_boss_phase = 2
	move_speed_runtime = data.move_speed * 1.22
	preferred_distance_runtime = maxf(data.preferred_distance - 18.0, 180.0)
	projectile_cooldown_runtime = maxf(0.82, data.projectile_cooldown * 0.76)
	projectile_speed_runtime = data.projectile_speed * 1.18
	projectile_damage_runtime = data.projectile_damage * 1.22
	_boss_skill_cooldown_left = 2.3
	boss_skill_triggered.emit("phase_shift", global_position, _boss_phase)


func _resolve_texture() -> Texture2D:
	var path: String = "res://art/sprites/enemy_runner.png"
	match enemy_id:
		"runner":
			path = "res://art/sprites/enemy_runner.png"
		"brute":
			path = "res://art/sprites/enemy_brute.png"
		"shooter":
			path = "res://art/sprites/enemy_shooter.png"
		"boss":
			path = "res://art/sprites/enemy_boss.png"
	if is_elite and not is_boss:
		path = "res://art/sprites/enemy_elite.png"
	return load(path) as Texture2D


func _get_display_color() -> Color:
	if _burn_time_left > 0.0:
		return Color(1.0, 0.7, 0.52, 1.0)
	if is_boss:
		return Color(1.0, 1.0, 1.0, 1.0)
	if is_elite:
		return Color(1.0, 0.94, 0.86, 1.0)
	return Color(1.0, 1.0, 1.0, 1.0)


func _notify_hit_feedback(died_now: bool) -> void:
	var game: Node = get_tree().get_first_node_in_group("game")
	if game == null:
		return
	if game.has_method("on_enemy_hit"):
		game.on_enemy_hit(global_position, enemy_id, is_elite, is_boss, died_now)
