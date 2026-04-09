extends CharacterBody2D
class_name Player

const CAMERA_EDGE_MARGIN := 12
const EIGHT_WAY_STEP := PI / 4.0
const WEAPON_TEXTURE := preload("res://art/sprites/weapon_blaster.png")
const WEAPON_FLASH_TEXTURE := preload("res://art/sprites/weapon_flash.png")
const SENTRY_NODE_SCENE := preload("res://scenes/props/sentry_node.tscn")

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
var _attack_sequence := 0
var _upgrade_levels: Dictionary = {}
var _aim_direction := Vector2.RIGHT
var _weapon_recoil_strength := 0.0
var _weapon_flash_left := 0.0
var _weapon_pulse_left := 0.0
var _weapon_flash_color := Color(1.0, 0.92, 0.74, 0.0)
var _dead := false
var _selected_branch_id := ""
var _selected_branch_name := ""
var _branch_damage_taken_multiplier := 1.0
var _branch_burn_damage := 0.0
var _branch_burn_duration := 0.0
var _branch_sentry_shot_interval := 0
var _branch_weapon_tint := Color(1.0, 1.0, 1.0, 1.0)
var _branch_flash_tint := Color(1.0, 0.92, 0.74, 0.95)

@onready var body_visual: Sprite2D = $Body
@onready var weapon_visual: Sprite2D = $Weapon
@onready var weapon_flash: Sprite2D = $WeaponFlash
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
	_configure_camera()
	health_changed.emit(current_health, max_health)


func _physics_process(delta: float) -> void:
	if _dead:
		velocity = Vector2.ZERO
		_update_weapon_animation(delta)
		_update_camera_shake(delta)
		return
	_handle_movement(delta)
	_handle_attack(delta)
	_handle_pulse(delta)
	_handle_invulnerability(delta)
	_update_weapon_animation(delta)
	_update_camera_shake(delta)


func apply_contact_damage(amount: float, source_position: Vector2) -> void:
	if current_health <= 0.0 or _invulnerability_left > 0.0 or _dead:
		return
	current_health = maxf(current_health - amount * _branch_damage_taken_multiplier, 0.0)
	_invulnerability_left = invulnerability_time
	velocity += (global_position - source_position).normalized() * 160.0
	health_changed.emit(current_health, max_health)
	_trigger_feedback("hurt")
	trigger_camera_shake(8.0, 0.16)
	if current_health <= 0.0:
		_dead = true
		_weapon_flash_left = 0.0
		_weapon_pulse_left = 0.0
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


func set_branch_definition(definition: Dictionary) -> void:
	_selected_branch_id = String(definition.get("id", ""))
	_selected_branch_name = String(definition.get("name", ""))
	_branch_damage_taken_multiplier = float(definition.get("damage_taken_multiplier", 1.0))
	_branch_burn_damage = float(definition.get("burn_damage", 0.0))
	_branch_burn_duration = float(definition.get("burn_duration", 0.0))
	_branch_sentry_shot_interval = int(definition.get("sentry_shot_interval", 0))
	_branch_weapon_tint = definition.get("weapon_tint", Color(1.0, 1.0, 1.0, 1.0)) as Color
	_branch_flash_tint = definition.get("flash_color", Color(1.0, 0.92, 0.74, 0.95)) as Color
	for effect in Array(definition.get("starting_effects", [])):
		_apply_effect(String(effect.get("type", "")), float(effect.get("amount", 0.0)))
	_apply_branch_visual_style()
	refresh_health_ui()


func sync_upgrade_levels(levels: Dictionary) -> void:
	_upgrade_levels = levels.duplicate(true)


func is_alive() -> bool:
	return not _dead


func get_selected_branch_name() -> String:
	return _selected_branch_name


func refresh_health_ui() -> void:
	health_changed.emit(current_health, max_health)


func get_build_summary() -> String:
	var pulse_text := "未解锁"
	if pulse_enabled:
		pulse_text = "伤害 %.0f / 冷却 %.1fs" % [pulse_damage, pulse_cooldown]
	var summary := "主武器 %d 发 | %.1fs 冷却 | %.0f 伤害 | 穿透 %d | 脉冲 %s" % [
		projectile_count,
		projectile_cooldown,
		projectile_damage,
		projectile_pierce,
		pulse_text
	]
	if not _selected_branch_name.is_empty():
		summary = "分支 %s | %s" % [_selected_branch_name, summary]
	var synergy_names: Array[String] = _get_active_synergy_names()
	if not synergy_names.is_empty():
		summary += " | 联动 %s" % " / ".join(synergy_names)
	return summary


func _handle_movement(delta: float) -> void:
	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_direction.length() > 0.0:
		_last_move_direction = input_direction.normalized()
		if _weapon_flash_left <= 0.0:
			_aim_direction = _last_move_direction
		velocity = velocity.move_toward(_last_move_direction * move_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()
	global_position = Vector2(
		clampf(global_position.x, -arena_half_size.x, arena_half_size.x),
		clampf(global_position.y, -arena_half_size.y, arena_half_size.y)
	)
	body_visual.rotation = snappedf(_last_move_direction.angle() + PI * 0.5, EIGHT_WAY_STEP)


func _handle_attack(delta: float) -> void:
	if projectile_scene == null or _dead:
		return
	_projectile_timer -= delta
	if _projectile_timer > 0.0:
		return

	var targets := _find_targets()
	if targets.is_empty():
		return

	_projectile_timer = projectile_cooldown
	_attack_sequence += 1
	var shot_count: int = projectile_count + _get_bonus_projectile_count()
	var overcharge_active: bool = _has_overcharge_synergy() and _attack_sequence % 4 == 0
	_trigger_weapon_fire((targets[0].global_position - global_position).normalized(), overcharge_active)
	for shot_index in range(shot_count):
		var target: Node2D = targets[shot_index % targets.size()]
		var base_direction: Vector2 = (target.global_position - global_position).normalized()
		var spread_offset: float = _get_spread_offset(shot_index, shot_count)
		var direction: Vector2 = base_direction.rotated(spread_offset)
		var projectile: PlayerProjectile = projectile_scene.instantiate() as PlayerProjectile
		projectile.global_position = global_position
		var projectile_damage_value: float = projectile_damage * (1.45 if overcharge_active else 1.0)
		var projectile_speed_value: float = projectile_speed * (1.12 if overcharge_active else 1.0)
		var projectile_range_value: float = projectile_range + (32.0 if _has_linebreak_synergy() else 0.0)
		var projectile_pierce_value: int = projectile_pierce
		if _has_linebreak_synergy() and shot_index == shot_count - 1:
			projectile_pierce_value += 1
		projectile.setup(
			projectile_damage_value,
			direction,
			projectile_speed_value,
			projectile_range_value,
			projectile_pierce_value,
			knockback_force * (1.3 if overcharge_active else 1.0),
			_current_projectile_tint(overcharge_active)
		)
		if _branch_burn_damage > 0.0 and _branch_burn_duration > 0.0:
			projectile.set_status_effect("burn", _branch_burn_duration, _branch_burn_damage)
		projectile_spawned.emit(projectile)
	if _branch_sentry_shot_interval > 0 and _attack_sequence % _branch_sentry_shot_interval == 0:
		_spawn_branch_sentry()
	if overcharge_active:
		trigger_camera_shake(3.0, 0.07)
	shot_fired.emit("projectile")


func _handle_pulse(delta: float) -> void:
	if not pulse_enabled or pulse_scene == null or _dead:
		return
	_pulse_timer -= delta
	if _pulse_timer > 0.0:
		return

	_pulse_timer = pulse_cooldown
	var pulse: PulseWave = pulse_scene.instantiate() as PulseWave
	pulse.global_position = global_position
	var pulse_damage_value: float = pulse_damage * (1.18 if _has_pulse_feedback_synergy() else 1.0)
	pulse.setup(pulse_damage_value, pulse_radius, 0.35, pulse_knockback)
	if _branch_burn_damage > 0.0 and _branch_burn_duration > 0.0:
		pulse.set_status_effect("burn", _branch_burn_duration * 0.85, maxf(_branch_burn_damage - 1.0, 1.0))
	effect_spawned.emit(pulse)
	_trigger_pulse_fire()
	if _has_pulse_feedback_synergy():
		_projectile_timer = minf(_projectile_timer, 0.12)
		trigger_camera_shake(2.4, 0.05)
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
			current_health = clampf(current_health + amount, 1.0, max_health)
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
	weapon_visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	weapon_visual.centered = true
	weapon_visual.texture = WEAPON_TEXTURE
	weapon_flash.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	weapon_flash.centered = true
	weapon_flash.texture = WEAPON_FLASH_TEXTURE
	weapon_flash.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_apply_branch_visual_style()


func _configure_camera() -> void:
	camera.limit_smoothed = true
	camera.limit_left = int(-arena_half_size.x) + CAMERA_EDGE_MARGIN
	camera.limit_right = int(arena_half_size.x) - CAMERA_EDGE_MARGIN
	camera.limit_top = int(-arena_half_size.y) + CAMERA_EDGE_MARGIN
	camera.limit_bottom = int(arena_half_size.y) - CAMERA_EDGE_MARGIN


func _trigger_weapon_fire(direction: Vector2, overcharge_active: bool) -> void:
	_aim_direction = direction
	_weapon_recoil_strength = 5.4 if overcharge_active else 4.2
	_weapon_flash_left = 0.09 if overcharge_active else 0.07
	_weapon_flash_color = _branch_flash_tint
	if overcharge_active:
		_weapon_flash_color = _branch_flash_tint.lightened(0.12)
	body_visual.scale = Vector2(1.04, 0.97)


func _trigger_pulse_fire() -> void:
	_weapon_flash_left = maxf(_weapon_flash_left, 0.11)
	_weapon_pulse_left = 0.18
	_weapon_flash_color = _branch_flash_tint.lerp(Color(0.48, 0.9, 1.0, 0.88), 0.5)
	body_visual.scale = Vector2(1.06, 0.95)


func _update_weapon_animation(delta: float) -> void:
	_weapon_recoil_strength = lerpf(_weapon_recoil_strength, 0.0, minf(delta * 16.0, 1.0))
	_weapon_flash_left = maxf(_weapon_flash_left - delta, 0.0)
	_weapon_pulse_left = maxf(_weapon_pulse_left - delta, 0.0)
	body_visual.scale = body_visual.scale.lerp(Vector2.ONE, minf(delta * 10.0, 1.0))

	var direction: Vector2 = _aim_direction.normalized()
	if direction == Vector2.ZERO:
		direction = _last_move_direction
	var base_offset: Vector2 = direction * 15.0 + Vector2(0.0, -2.0)
	var recoil_offset: Vector2 = -direction * _weapon_recoil_strength
	weapon_visual.position = base_offset + recoil_offset
	weapon_visual.rotation = direction.angle()
	weapon_visual.scale = Vector2.ONE * (1.0 + _weapon_pulse_left * 0.45)

	weapon_flash.position = direction * 25.0
	weapon_flash.rotation = direction.angle()
	if _weapon_flash_left > 0.0:
		var flash_ratio: float = _weapon_flash_left / 0.11
		weapon_flash.modulate = Color(_weapon_flash_color.r, _weapon_flash_color.g, _weapon_flash_color.b, minf(flash_ratio, 1.0))
		weapon_flash.scale = Vector2.ONE * (0.9 + flash_ratio * 0.45)
	else:
		weapon_flash.modulate = Color(1.0, 1.0, 1.0, 0.0)


func _apply_branch_visual_style() -> void:
	if weapon_visual == null or weapon_flash == null:
		return
	weapon_visual.modulate = _branch_weapon_tint


func _current_projectile_tint(overcharge_active: bool) -> Color:
	if overcharge_active:
		return _branch_weapon_tint.lightened(0.18)
	return _branch_weapon_tint


func _spawn_branch_sentry() -> void:
	var sentry: SentryNode = SENTRY_NODE_SCENE.instantiate() as SentryNode
	var direction: Vector2 = _aim_direction.normalized()
	if direction == Vector2.ZERO:
		direction = _last_move_direction
	sentry.global_position = global_position + direction * 26.0
	sentry.setup(8.0, 0.78, maxf(projectile_damage * 0.42, 8.0), 340.0, _branch_weapon_tint)
	effect_spawned.emit(sentry)
	trigger_camera_shake(1.3, 0.04)


func _get_upgrade_level(upgrade_id: String) -> int:
	return int(_upgrade_levels.get(upgrade_id, 0))


func _has_overcharge_synergy() -> bool:
	return _get_upgrade_level("power_shot") >= 2 and _get_upgrade_level("rapid_fire") >= 2


func _has_linebreak_synergy() -> bool:
	return _get_upgrade_level("split_round") >= 2 and _get_upgrade_level("piercing_round") >= 1


func _has_pulse_feedback_synergy() -> bool:
	return pulse_enabled and _get_upgrade_level("pulse_core") >= 2 and _get_upgrade_level("pulse_drive") >= 1


func _get_bonus_projectile_count() -> int:
	return 1 if _has_linebreak_synergy() else 0


func _get_spread_offset(shot_index: int, shot_count: int) -> float:
	if shot_count <= 1:
		return 0.0
	var center_index: float = float(shot_count - 1) * 0.5
	var base_step: float = 0.11
	if _has_linebreak_synergy():
		base_step = 0.145
	return (float(shot_index) - center_index) * base_step


func _get_active_synergy_names() -> Array[String]:
	var names: Array[String] = []
	if _has_overcharge_synergy():
		names.append("过载连射")
	if _has_linebreak_synergy():
		names.append("裂穿扩散")
	if _has_pulse_feedback_synergy():
		names.append("脉冲回流")
	return names


func _trigger_feedback(feedback_name: String) -> void:
	var game: Node = get_tree().get_first_node_in_group("game")
	if game != null and game.has_method("on_player_feedback"):
		game.on_player_feedback(feedback_name, global_position)
