extends CharacterBody2D
class_name Player

const CAMERA_EDGE_MARGIN := 12
const WEAPON_TEXTURE := preload("res://art/sprites/weapon_blaster.png")
const WEAPON_FLASH_TEXTURE := preload("res://art/sprites/weapon_flash.png")
const SENTRY_NODE_SCENE := preload("res://scenes/props/sentry_node.tscn")
const GUARD_BURST_SCENE := preload("res://scenes/effects/guard_burst.tscn")
const SCORCH_ORB_SCENE := preload("res://scenes/weapons/scorch_orb.tscn")
const WEAPON_BASE_SCALE := 0.68
const WEAPON_FLASH_BASE_SCALE := 0.72
const DEFAULT_WEAPON_FRAMES := {
	"idle": WEAPON_TEXTURE,
	"windup": WEAPON_TEXTURE,
	"release": WEAPON_TEXTURE,
	"recover": WEAPON_TEXTURE
}
const DEFAULT_FLASH_FRAMES := {
	"a": WEAPON_FLASH_TEXTURE,
	"b": WEAPON_FLASH_TEXTURE
}
const PLAYER_DIRECTION_TEXTURES: Dictionary[String, Texture2D] = {
	"down": preload("res://art/sprites/player_dirs/player_down.png"),
	"down_right": preload("res://art/sprites/player_dirs/player_down_right.png"),
	"right": preload("res://art/sprites/player_dirs/player_right.png"),
	"up_right": preload("res://art/sprites/player_dirs/player_up_right.png"),
	"up": preload("res://art/sprites/player_dirs/player_up.png"),
	"up_left": preload("res://art/sprites/player_dirs/player_up_left.png"),
	"left": preload("res://art/sprites/player_dirs/player_left.png"),
	"down_left": preload("res://art/sprites/player_dirs/player_down_left.png")
}

enum AttackPhase { IDLE, WINDUP, RECOVERY }

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
var _branch_guard_shot_interval := 0
var _branch_guard_damage := 0.0
var _branch_guard_radius := 0.0
var _branch_guard_knockback := 0.0
var _branch_scorch_orb_shot_interval := 0
var _branch_scorch_orb_damage := 0.0
var _branch_scorch_orb_speed := 0.0
var _branch_scorch_orb_range := 0.0
var _branch_scorch_field_radius := 0.0
var _branch_scorch_field_duration := 0.0
var _branch_scorch_field_tick_damage := 0.0
var _branch_scorch_field_tick_interval := 0.5
var _branch_scorch_slow_duration := 0.0
var _branch_scorch_slow_amount := 1.0
var _branch_sentry_shot_interval := 0
var _branch_sentry_lifetime := 8.0
var _branch_sentry_fire_interval := 0.78
var _branch_sentry_damage_multiplier := 0.42
var _branch_sentry_range := 340.0
var _branch_sentry_pulse_damage := 0.0
var _branch_sentry_pulse_radius := 0.0
var _branch_sentry_pulse_interval := 0.0
var _branch_weapon_type := "ranged"
var _branch_attack_shape := "bolt"
var _branch_attack_range := 0.0
var _branch_attack_arc := 0.0
var _branch_windup_time := 0.12
var _branch_recovery_time := 0.1
var _branch_animation_key := "default"
var _branch_weapon_length := 14.0
var _branch_muzzle_distance := 21.0
var _branch_flash_distance := 21.0
var _branch_weapon_base_scale := WEAPON_BASE_SCALE
var _branch_flash_base_scale := WEAPON_FLASH_BASE_SCALE
var _branch_projectile_scale := 0.62
var _branch_projectile_spin := 0.0
var _branch_projectile_speed_multiplier := 1.0
var _branch_projectile_range_multiplier := 1.0
var _branch_weapon_frames: Dictionary = DEFAULT_WEAPON_FRAMES.duplicate(true)
var _branch_flash_frames: Dictionary = DEFAULT_FLASH_FRAMES.duplicate(true)
var _branch_projectile_texture: Texture2D
var _branch_weapon_tint := Color(1.0, 1.0, 1.0, 1.0)
var _branch_flash_tint := Color(1.0, 0.92, 0.74, 0.95)
var _body_direction_key := "right"
var _attack_phase: int = AttackPhase.IDLE
var _attack_phase_time_left := 0.0
var _attack_direction := Vector2.RIGHT
var _attack_target_position := Vector2.ZERO
var _attack_hit_resolved := false

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
	if _branch_guard_damage > 0.0 and _branch_guard_radius > 0.0:
		_spawn_guard_burst(0.72, 0.86)
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
	_branch_guard_shot_interval = int(definition.get("guard_shot_interval", 0))
	_branch_guard_damage = float(definition.get("guard_damage", 0.0))
	_branch_guard_radius = float(definition.get("guard_radius", 0.0))
	_branch_guard_knockback = float(definition.get("guard_knockback", 0.0))
	_branch_scorch_orb_shot_interval = int(definition.get("scorch_orb_shot_interval", 0))
	_branch_scorch_orb_damage = float(definition.get("scorch_orb_damage", 0.0))
	_branch_scorch_orb_speed = float(definition.get("scorch_orb_speed", 0.0))
	_branch_scorch_orb_range = float(definition.get("scorch_orb_range", 0.0))
	_branch_scorch_field_radius = float(definition.get("scorch_field_radius", 0.0))
	_branch_scorch_field_duration = float(definition.get("scorch_field_duration", 0.0))
	_branch_scorch_field_tick_damage = float(definition.get("scorch_field_tick_damage", 0.0))
	_branch_scorch_field_tick_interval = float(definition.get("scorch_field_tick_interval", 0.5))
	_branch_scorch_slow_duration = float(definition.get("scorch_slow_duration", 0.0))
	_branch_scorch_slow_amount = float(definition.get("scorch_slow_amount", 1.0))
	_branch_sentry_shot_interval = int(definition.get("sentry_shot_interval", 0))
	_branch_sentry_lifetime = float(definition.get("sentry_lifetime", 8.0))
	_branch_sentry_fire_interval = float(definition.get("sentry_fire_interval", 0.78))
	_branch_sentry_damage_multiplier = float(definition.get("sentry_damage_multiplier", 0.42))
	_branch_sentry_range = float(definition.get("sentry_range", 340.0))
	_branch_sentry_pulse_damage = float(definition.get("sentry_pulse_damage", 0.0))
	_branch_sentry_pulse_radius = float(definition.get("sentry_pulse_radius", 0.0))
	_branch_sentry_pulse_interval = float(definition.get("sentry_pulse_interval", 0.0))
	_branch_weapon_type = String(definition.get("weapon_type", "ranged"))
	_branch_attack_shape = String(definition.get("attack_shape", "bolt"))
	_branch_attack_range = float(definition.get("attack_range", 0.0))
	_branch_attack_arc = float(definition.get("attack_arc", 0.0))
	_branch_windup_time = float(definition.get("windup_time", 0.12))
	_branch_recovery_time = float(definition.get("recovery_time", 0.1))
	_branch_animation_key = String(definition.get("animation_key", "default"))
	_branch_weapon_length = float(definition.get("weapon_length", 14.0))
	_branch_muzzle_distance = float(definition.get("muzzle_distance", 21.0))
	_branch_flash_distance = float(definition.get("flash_distance", 21.0))
	_branch_weapon_base_scale = float(definition.get("weapon_base_scale", WEAPON_BASE_SCALE))
	_branch_flash_base_scale = float(definition.get("flash_base_scale", WEAPON_FLASH_BASE_SCALE))
	_branch_projectile_scale = float(definition.get("projectile_scale", 0.62))
	_branch_projectile_spin = float(definition.get("projectile_spin", 0.0))
	_branch_projectile_speed_multiplier = float(definition.get("projectile_speed_multiplier", 1.0))
	_branch_projectile_range_multiplier = float(definition.get("projectile_range_multiplier", 1.0))
	var weapon_frames: Dictionary = definition.get("weapon_frames", DEFAULT_WEAPON_FRAMES)
	var flash_frames: Dictionary = definition.get("flash_frames", DEFAULT_FLASH_FRAMES)
	_branch_weapon_frames = weapon_frames.duplicate(true)
	_branch_flash_frames = flash_frames.duplicate(true)
	_branch_projectile_texture = definition.get("projectile_texture", null) as Texture2D
	_branch_weapon_tint = definition.get("weapon_tint", Color(1.0, 1.0, 1.0, 1.0)) as Color
	_branch_flash_tint = definition.get("flash_color", Color(1.0, 0.92, 0.74, 0.95)) as Color
	_attack_phase = AttackPhase.IDLE
	_attack_phase_time_left = 0.0
	_attack_hit_resolved = false
	_attack_direction = _last_move_direction
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
	var branch_mechanic_text := _branch_mechanic_summary()
	if not branch_mechanic_text.is_empty():
		summary += " | 机制 %s" % branch_mechanic_text
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
	_update_body_direction_sprite(_last_move_direction)


func _handle_attack(delta: float) -> void:
	if _dead:
		return
	if _branch_weapon_type != "melee" and projectile_scene == null:
		return
	_projectile_timer = maxf(_projectile_timer - delta, 0.0)
	_update_attack_state(delta)
	if _attack_phase != AttackPhase.IDLE:
		return
	if _projectile_timer > 0.0:
		return

	var targets := _find_targets()
	if targets.is_empty():
		return

	var target: Node2D = _pick_primary_attack_target(targets)
	if target == null:
		return
	_start_primary_attack(target.global_position)


func _pick_primary_attack_target(targets: Array[Node2D]) -> Node2D:
	if targets.is_empty():
		return null
	if _branch_weapon_type != "melee":
		return targets[0]
	var melee_reach: float = _current_melee_reach() + 20.0
	for target in targets:
		if global_position.distance_to(target.global_position) <= melee_reach:
			return target
	return null


func _start_primary_attack(target_position: Vector2) -> void:
	var direction: Vector2 = (target_position - global_position).normalized()
	if direction == Vector2.ZERO:
		direction = _last_move_direction
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	_projectile_timer = projectile_cooldown
	_attack_direction = direction
	_attack_target_position = target_position
	_attack_phase = AttackPhase.WINDUP
	_attack_phase_time_left = maxf(_branch_windup_time, 0.01)
	_attack_hit_resolved = false
	_aim_direction = direction
	body_visual.scale = Vector2(1.03, 0.98)


func _update_attack_state(delta: float) -> void:
	if _attack_phase == AttackPhase.IDLE:
		return
	_attack_phase_time_left = maxf(_attack_phase_time_left - delta, 0.0)
	if _attack_phase == AttackPhase.WINDUP:
		if _attack_hit_resolved or _attack_phase_time_left > 0.0:
			return
		_attack_hit_resolved = true
		_resolve_primary_attack()
		_attack_phase = AttackPhase.RECOVERY
		_attack_phase_time_left = maxf(_branch_recovery_time, 0.01)
		return
	if _attack_phase == AttackPhase.RECOVERY and _attack_phase_time_left <= 0.0:
		_attack_phase = AttackPhase.IDLE
		_attack_hit_resolved = false


func _resolve_primary_attack() -> void:
	_attack_sequence += 1
	var shot_count: int = max(projectile_count + _get_bonus_projectile_count(), 1)
	var overcharge_active: bool = _has_overcharge_synergy() and _attack_sequence % 4 == 0
	_trigger_weapon_fire(_attack_direction, overcharge_active)
	match _branch_weapon_type:
		"melee":
			_perform_melee_attack(shot_count, overcharge_active)
		"thrown":
			_fire_primary_projectiles(shot_count, overcharge_active, 0.92)
		_:
			_fire_primary_projectiles(shot_count, overcharge_active, 0.78)
	if _branch_guard_shot_interval > 0 and _attack_sequence % _branch_guard_shot_interval == 0:
		_spawn_guard_burst()
	if _branch_scorch_orb_shot_interval > 0 and _attack_sequence % _branch_scorch_orb_shot_interval == 0:
		_spawn_scorch_orb(_attack_direction)
	if _branch_sentry_shot_interval > 0 and _attack_sequence % _branch_sentry_shot_interval == 0:
		_spawn_branch_sentry()
	if overcharge_active:
		trigger_camera_shake(3.0, 0.07)
	var shot_name := "projectile"
	if _branch_weapon_type == "melee":
		shot_name = "melee"
	elif _branch_weapon_type == "thrown":
		shot_name = "spell"
	else:
		shot_name = "command"
	shot_fired.emit(shot_name)


func _perform_melee_attack(shot_count: int, overcharge_active: bool) -> void:
	var direction: Vector2 = _attack_direction.normalized()
	if direction == Vector2.ZERO:
		direction = _last_move_direction
	var slash_count: int = max(shot_count, 1)
	var center_index: float = float(slash_count - 1) * 0.5
	var melee_reach: float = _current_melee_reach()
	var melee_arc_radians: float = deg_to_rad(_current_melee_arc())
	var damage_value: float = projectile_damage * (1.45 if overcharge_active else 1.0)
	var knockback_value: float = knockback_force * (1.32 if overcharge_active else 1.08)
	var hit_any := false
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy: Enemy = enemy_node as Enemy
		if enemy == null or not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		var to_enemy: Vector2 = enemy.global_position - global_position
		if to_enemy == Vector2.ZERO or to_enemy.length() > melee_reach:
			continue
		var enemy_direction: Vector2 = to_enemy.normalized()
		var enemy_hit := false
		for slash_index in range(slash_count):
			var slash_offset: float = (float(slash_index) - center_index) * 0.16
			var slash_direction: Vector2 = direction.rotated(slash_offset)
			if absf(slash_direction.angle_to(enemy_direction)) <= melee_arc_radians * 0.5:
				enemy.take_damage(damage_value, global_position, knockback_value)
				if _branch_burn_damage > 0.0 and _branch_burn_duration > 0.0:
					enemy.apply_status_effect("burn", _branch_burn_duration, _branch_burn_damage)
				enemy_hit = true
				hit_any = true
				break
		if enemy_hit and overcharge_active:
			enemy.velocity += direction * 26.0
	if hit_any:
		trigger_camera_shake(2.0 if not overcharge_active else 2.8, 0.05)


func _fire_primary_projectiles(shot_count: int, overcharge_active: bool, spread_scale: float) -> void:
	for shot_index in range(shot_count):
		var spread_offset: float = _get_spread_offset(shot_index, shot_count) * spread_scale
		var direction: Vector2 = _attack_direction.rotated(spread_offset)
		_spawn_primary_projectile(direction, overcharge_active, shot_index == shot_count - 1 and _has_linebreak_synergy())


func _spawn_primary_projectile(direction: Vector2, overcharge_active: bool, bonus_pierce: bool) -> void:
	if projectile_scene == null:
		return
	var projectile: PlayerProjectile = projectile_scene.instantiate() as PlayerProjectile
	if projectile == null:
		return
	var projectile_damage_value: float = projectile_damage * (1.45 if overcharge_active else 1.0)
	var projectile_speed_value: float = projectile_speed * _branch_projectile_speed_multiplier * (1.12 if overcharge_active else 1.0)
	var projectile_range_value: float = projectile_range * _branch_projectile_range_multiplier + (32.0 if _has_linebreak_synergy() else 0.0)
	var projectile_pierce_value: int = projectile_pierce + (1 if bonus_pierce else 0)
	projectile.global_position = global_position + direction.normalized() * _branch_muzzle_distance
	projectile.setup(
		projectile_damage_value,
		direction,
		projectile_speed_value,
		projectile_range_value,
		projectile_pierce_value,
		knockback_force * (1.3 if overcharge_active else 1.0),
		_current_projectile_tint(overcharge_active),
		_branch_projectile_texture,
		_branch_projectile_scale,
		_branch_projectile_spin
	)
	if _branch_burn_damage > 0.0 and _branch_burn_duration > 0.0:
		projectile.set_status_effect("burn", _branch_burn_duration, _branch_burn_damage)
	projectile_spawned.emit(projectile)


func _current_melee_reach() -> float:
	return _branch_attack_range + maxf(projectile_range - 420.0, 0.0) * 0.18 + float(projectile_pierce) * 7.0


func _current_melee_arc() -> float:
	return _branch_attack_arc + float(projectile_pierce) * 8.0


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
		"branch_damage_taken_multiplier":
			_branch_damage_taken_multiplier = clampf(_branch_damage_taken_multiplier * amount, 0.4, 1.35)
		"branch_burn_damage":
			_branch_burn_damage = maxf(_branch_burn_damage + amount, 0.0)
		"branch_burn_duration":
			_branch_burn_duration = clampf(_branch_burn_duration + amount, 0.0, 12.0)
		"guard_burst_damage":
			_branch_guard_damage = maxf(_branch_guard_damage + amount, 0.0)
		"guard_burst_radius":
			_branch_guard_radius = clampf(_branch_guard_radius + amount, 24.0, 240.0)
		"guard_shot_interval_delta":
			if _branch_guard_shot_interval <= 0:
				_branch_guard_shot_interval = 5
			_branch_guard_shot_interval = clampi(_branch_guard_shot_interval + int(amount), 2, 12)
		"scorch_orb_interval_delta":
			if _branch_scorch_orb_shot_interval <= 0:
				_branch_scorch_orb_shot_interval = 5
			_branch_scorch_orb_shot_interval = clampi(_branch_scorch_orb_shot_interval + int(amount), 2, 12)
		"scorch_field_radius":
			_branch_scorch_field_radius = clampf(_branch_scorch_field_radius + amount, 32.0, 240.0)
		"scorch_field_duration":
			_branch_scorch_field_duration = clampf(_branch_scorch_field_duration + amount, 0.4, 12.0)
		"scorch_field_tick_damage":
			_branch_scorch_field_tick_damage = maxf(_branch_scorch_field_tick_damage + amount, 0.0)
		"sentry_shot_interval_delta":
			if _branch_sentry_shot_interval <= 0:
				_branch_sentry_shot_interval = 6
			_branch_sentry_shot_interval = clampi(_branch_sentry_shot_interval + int(amount), 2, 14)
		"sentry_damage_multiplier":
			_branch_sentry_damage_multiplier = clampf(_branch_sentry_damage_multiplier + amount, 0.2, 1.8)
		"sentry_lifetime":
			_branch_sentry_lifetime = clampf(_branch_sentry_lifetime + amount, 2.0, 22.0)
		"sentry_fire_interval":
			_branch_sentry_fire_interval = clampf(_branch_sentry_fire_interval + amount, 0.25, 2.0)
		"sentry_range":
			_branch_sentry_range = clampf(_branch_sentry_range + amount, 140.0, 680.0)
		"sentry_pulse_damage":
			_branch_sentry_pulse_damage = maxf(_branch_sentry_pulse_damage + amount, 0.0)
		"sentry_pulse_radius":
			_branch_sentry_pulse_radius = clampf(_branch_sentry_pulse_radius + amount, 18.0, 220.0)
		"sentry_pulse_interval":
			_branch_sentry_pulse_interval = clampf(_branch_sentry_pulse_interval + amount, 0.25, 3.0)
		_:
			push_warning("Unknown upgrade effect: %s" % effect_type)


func _apply_shape() -> void:
	var circle := collision_shape.shape as CircleShape2D
	if circle != null:
		circle.radius = 14.0
	body_visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body_visual.centered = true
	body_visual.texture = PLAYER_DIRECTION_TEXTURES["right"] as Texture2D
	body_visual.rotation = 0.0
	weapon_visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	weapon_visual.centered = true
	weapon_visual.texture = _branch_weapon_frame("idle")
	weapon_visual.scale = Vector2.ONE * _branch_weapon_base_scale
	weapon_flash.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	weapon_flash.centered = true
	weapon_flash.texture = _branch_flash_frame("a")
	weapon_flash.scale = Vector2.ONE * _branch_flash_base_scale
	weapon_flash.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_update_body_direction_sprite(_last_move_direction, true)
	_apply_branch_visual_style()


func _configure_camera() -> void:
	camera.limit_smoothed = true
	camera.limit_left = int(-arena_half_size.x) + CAMERA_EDGE_MARGIN
	camera.limit_right = int(arena_half_size.x) - CAMERA_EDGE_MARGIN
	camera.limit_top = int(-arena_half_size.y) + CAMERA_EDGE_MARGIN
	camera.limit_bottom = int(arena_half_size.y) - CAMERA_EDGE_MARGIN


func _trigger_weapon_fire(direction: Vector2, overcharge_active: bool) -> void:
	_aim_direction = direction
	match _branch_weapon_type:
		"melee":
			_weapon_recoil_strength = 1.9 if overcharge_active else 1.2
			_weapon_flash_left = 0.14 if overcharge_active else 0.11
			_weapon_pulse_left = maxf(_weapon_pulse_left, 0.12)
		"thrown":
			_weapon_recoil_strength = 3.8 if overcharge_active else 2.9
			_weapon_flash_left = 0.12 if overcharge_active else 0.1
			_weapon_pulse_left = maxf(_weapon_pulse_left, 0.08)
		_:
			_weapon_recoil_strength = 4.8 if overcharge_active else 3.9
			_weapon_flash_left = 0.1 if overcharge_active else 0.08
			_weapon_pulse_left = maxf(_weapon_pulse_left, 0.08)
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
	if _attack_phase != AttackPhase.IDLE:
		direction = _attack_direction.normalized()
	if direction == Vector2.ZERO:
		direction = _last_move_direction
	var vertical_offset := Vector2(0.0, -2.0)
	var weapon_position := direction * _branch_weapon_length + vertical_offset
	var weapon_rotation := direction.angle()
	var weapon_texture: Texture2D = _branch_weapon_frame("idle")
	var flash_position := direction * _branch_flash_distance
	var flash_rotation := direction.angle()
	match _branch_weapon_type:
		"melee":
			if _attack_phase == AttackPhase.WINDUP:
				var windup_progress := _attack_phase_progress(_branch_windup_time)
				weapon_texture = _branch_weapon_frame("windup")
				weapon_position = direction.rotated(-0.9) * (_branch_weapon_length - 5.0 + windup_progress * 3.0) + vertical_offset
				weapon_rotation = direction.angle() - 1.2 + windup_progress * 0.32
			elif _attack_phase == AttackPhase.RECOVERY:
				var recovery_progress := _attack_phase_progress(_branch_recovery_time)
				weapon_texture = _branch_weapon_frame("release") if recovery_progress < 0.42 else _branch_weapon_frame("recover")
				weapon_position = direction.rotated(0.55) * (_branch_weapon_length + 4.0 - recovery_progress * 2.0) + vertical_offset
				weapon_rotation = direction.angle() + lerpf(1.08, 0.14, recovery_progress)
			else:
				weapon_texture = _branch_weapon_frame("idle")
				weapon_position = direction.rotated(-0.16) * (_branch_weapon_length - 2.0) + vertical_offset
				weapon_rotation = direction.angle() + 0.28
			flash_position = direction.rotated(0.38) * _branch_flash_distance
			flash_rotation = direction.angle() + 0.24
		"thrown":
			if _attack_phase == AttackPhase.WINDUP:
				var cast_progress := _attack_phase_progress(_branch_windup_time)
				weapon_texture = _branch_weapon_frame("windup")
				weapon_position = direction.rotated(-0.46) * (_branch_weapon_length - 4.0) + vertical_offset
				weapon_rotation = direction.angle() - 0.72 + cast_progress * 0.18
			elif _attack_phase == AttackPhase.RECOVERY:
				var release_progress := _attack_phase_progress(_branch_recovery_time)
				weapon_texture = _branch_weapon_frame("release") if release_progress < 0.58 else _branch_weapon_frame("recover")
				weapon_position = direction * (_branch_weapon_length + 3.0 - release_progress) + vertical_offset
				weapon_rotation = direction.angle() + lerpf(0.42, 0.08, release_progress)
			else:
				weapon_texture = _branch_weapon_frame("idle")
				weapon_position = direction.rotated(0.18) * _branch_weapon_length + vertical_offset
				weapon_rotation = direction.angle() + 0.34
			flash_position = direction * _branch_flash_distance
			flash_rotation = direction.angle()
		_:
			if _attack_phase == AttackPhase.WINDUP:
				var charge_progress := _attack_phase_progress(_branch_windup_time)
				weapon_texture = _branch_weapon_frame("windup")
				weapon_position = direction * (_branch_weapon_length - 4.0) + vertical_offset
				weapon_rotation = direction.angle() - 0.18 + charge_progress * 0.08
			elif _attack_phase == AttackPhase.RECOVERY:
				var release_snap_progress := _attack_phase_progress(_branch_recovery_time)
				weapon_texture = _branch_weapon_frame("release") if release_snap_progress < 0.62 else _branch_weapon_frame("recover")
				weapon_position = direction * (_branch_weapon_length + 4.0 - release_snap_progress * 2.0) + vertical_offset
				weapon_rotation = direction.angle() + 0.08
			else:
				weapon_texture = _branch_weapon_frame("idle")
				weapon_position = direction * _branch_weapon_length + vertical_offset
				weapon_rotation = direction.angle() + 0.12
			flash_position = direction * _branch_flash_distance
			flash_rotation = direction.angle()
	weapon_visual.texture = weapon_texture
	weapon_visual.position = weapon_position - direction * _weapon_recoil_strength
	weapon_visual.rotation = weapon_rotation
	weapon_visual.scale = Vector2.ONE * _branch_weapon_base_scale * (1.0 + _weapon_pulse_left * 0.45)

	weapon_flash.position = flash_position
	weapon_flash.rotation = flash_rotation
	if _weapon_flash_left > 0.0:
		var flash_ratio: float = _weapon_flash_left / 0.14
		weapon_flash.texture = _branch_flash_frame("a") if flash_ratio > 0.52 else _branch_flash_frame("b")
		weapon_flash.modulate = Color(_weapon_flash_color.r, _weapon_flash_color.g, _weapon_flash_color.b, minf(flash_ratio, 1.0))
		weapon_flash.scale = Vector2.ONE * _branch_flash_base_scale * (0.9 + flash_ratio * 0.45)
	else:
		weapon_flash.texture = _branch_flash_frame("a")
		weapon_flash.modulate = Color(1.0, 1.0, 1.0, 0.0)
		weapon_flash.scale = Vector2.ONE * _branch_flash_base_scale


func _apply_branch_visual_style() -> void:
	if weapon_visual == null or weapon_flash == null:
		return
	weapon_visual.texture = _branch_weapon_frame("idle")
	weapon_visual.scale = Vector2.ONE * _branch_weapon_base_scale
	weapon_visual.modulate = _branch_weapon_tint
	weapon_flash.texture = _branch_flash_frame("a")
	weapon_flash.scale = Vector2.ONE * _branch_flash_base_scale


func _branch_weapon_frame(frame_key: String) -> Texture2D:
	var texture: Texture2D = _branch_weapon_frames.get(frame_key, null) as Texture2D
	if texture != null:
		return texture
	return WEAPON_TEXTURE


func _branch_flash_frame(frame_key: String) -> Texture2D:
	var texture: Texture2D = _branch_flash_frames.get(frame_key, null) as Texture2D
	if texture != null:
		return texture
	return WEAPON_FLASH_TEXTURE


func _attack_phase_progress(total_time: float) -> float:
	if total_time <= 0.0:
		return 1.0
	return clampf(1.0 - _attack_phase_time_left / total_time, 0.0, 1.0)


func _current_projectile_tint(overcharge_active: bool) -> Color:
	if overcharge_active:
		return _branch_weapon_tint.lightened(0.18)
	return _branch_weapon_tint


func _branch_mechanic_summary() -> String:
	if _branch_guard_shot_interval > 0:
		return "震荡护环/%d射" % _branch_guard_shot_interval
	if _branch_scorch_orb_shot_interval > 0:
		return "蚀火法球/%d射" % _branch_scorch_orb_shot_interval
	if _branch_sentry_shot_interval > 0:
		return "哨戒节点/%d射" % _branch_sentry_shot_interval
	return ""


func _spawn_guard_burst(damage_scale: float = 1.0, radius_scale: float = 1.0) -> void:
	if _branch_guard_damage <= 0.0 or _branch_guard_radius <= 0.0:
		return
	var burst := GUARD_BURST_SCENE.instantiate()
	burst.global_position = global_position
	burst.setup(
		_branch_guard_damage * damage_scale,
		_branch_guard_radius * radius_scale,
		0.2,
		maxf(_branch_guard_knockback, 180.0),
		_branch_weapon_tint
	)
	effect_spawned.emit(burst)
	trigger_camera_shake(1.8, 0.05)


func _spawn_scorch_orb(direction: Vector2) -> void:
	if _branch_scorch_orb_damage <= 0.0 or _branch_scorch_field_radius <= 0.0:
		return
	if direction == Vector2.ZERO:
		direction = _last_move_direction
	var orb := SCORCH_ORB_SCENE.instantiate()
	orb.global_position = global_position
	orb.setup(
		direction,
		_branch_scorch_orb_speed,
		_branch_scorch_orb_range,
		_branch_scorch_orb_damage,
		knockback_force * 0.55,
		_branch_scorch_field_radius,
		_branch_scorch_field_duration,
		_branch_scorch_field_tick_interval,
		_branch_scorch_field_tick_damage,
		maxf(_branch_burn_duration, 0.8),
		maxf(_branch_burn_damage, 1.0),
		_branch_scorch_slow_duration,
		_branch_scorch_slow_amount,
		_branch_weapon_tint.lerp(Color(1.0, 0.36, 0.18, 1.0), 0.55)
	)
	projectile_spawned.emit(orb)
	trigger_camera_shake(1.4, 0.04)


func _spawn_branch_sentry() -> void:
	var sentry: SentryNode = SENTRY_NODE_SCENE.instantiate() as SentryNode
	var direction: Vector2 = _aim_direction.normalized()
	if direction == Vector2.ZERO:
		direction = _last_move_direction
	sentry.global_position = global_position + direction * 26.0
	sentry.setup(
		_branch_sentry_lifetime,
		_branch_sentry_fire_interval,
		maxf(projectile_damage * _branch_sentry_damage_multiplier, 8.0),
		_branch_sentry_range,
		_branch_weapon_tint,
		_branch_sentry_pulse_damage,
		_branch_sentry_pulse_radius,
		_branch_sentry_pulse_interval
	)
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


func _direction_to_sprite_key(direction: Vector2) -> String:
	if direction == Vector2.ZERO:
		return _body_direction_key
	var normalized_angle: float = wrapf(direction.angle(), 0.0, TAU)
	var octant: int = int(floor((normalized_angle + PI / 8.0) / (PI / 4.0))) % 8
	match octant:
		0:
			return "right"
		1:
			return "down_right"
		2:
			return "down"
		3:
			return "down_left"
		4:
			return "left"
		5:
			return "up_left"
		6:
			return "up"
		_:
			return "up_right"


func _update_body_direction_sprite(direction: Vector2, force: bool = false) -> void:
	var key: String = _direction_to_sprite_key(direction)
	if not force and key == _body_direction_key:
		return
	_body_direction_key = key
	var texture: Texture2D = PLAYER_DIRECTION_TEXTURES.get(key, null) as Texture2D
	if texture != null:
		body_visual.texture = texture
