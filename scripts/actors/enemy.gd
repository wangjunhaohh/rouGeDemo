extends CharacterBody2D
class_name Enemy

signal defeated(world_position: Vector2, experience_reward: int, enemy_id: String, was_elite: bool, was_boss: bool)
signal projectile_spawned(projectile: Node2D)

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
	_setup_runtime_stats()
	_apply_data()


func _physics_process(delta: float) -> void:
	if data == null or player == null or not is_instance_valid(player):
		return

	var to_player := player.global_position - global_position
	var distance := to_player.length()
	var direction := Vector2.ZERO

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

	velocity = velocity.move_toward(direction * move_speed_runtime, move_speed_runtime * 8.0 * delta)
	move_and_slide()
	_handle_contact_damage(distance, delta)
	_handle_flash(delta)


func take_damage(amount: float, source_position: Vector2, knockback_force: float) -> void:
	if current_health <= 0.0:
		return
	current_health -= amount
	_flash_left = 0.08
	velocity += (global_position - source_position).normalized() * knockback_force
	_notify_hit_feedback(current_health <= 0.0)
	if current_health <= 0.0:
		defeated.emit(global_position, experience_reward_runtime, enemy_id, is_elite, is_boss)
		queue_free()


func _handle_shooting(to_player: Vector2, distance: float, delta: float) -> void:
	if projectile_scene == null:
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


func _handle_contact_damage(distance: float, delta: float) -> void:
	_contact_cooldown_left = maxf(_contact_cooldown_left - delta, 0.0)
	if distance > size_runtime + 18.0 or _contact_cooldown_left > 0.0:
		return
	_contact_cooldown_left = 0.9
	player.apply_contact_damage(touch_damage_runtime, global_position)


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
