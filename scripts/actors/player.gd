extends CharacterBody2D
class_name Player

const CAMERA_EDGE_MARGIN := 12
const WEAPON_TEXTURE := preload("res://art/sprites/weapon_blaster.png")
const WEAPON_FLASH_TEXTURE := preload("res://art/sprites/weapon_flash.png")
const SENTRY_NODE_SCENE := preload("res://scenes/props/sentry_node.tscn")
const GUARD_BURST_SCENE := preload("res://scenes/effects/guard_burst.tscn")
const SCORCH_ORB_SCENE := preload("res://scenes/weapons/scorch_orb.tscn")
const SLASH_SEQUENCE_EFFECT := preload("res://scripts/effects/slash_sequence_effect.gd")
const BOMBARDMENT_CIRCLE_EFFECT := preload("res://scripts/effects/bombardment_circle_effect.gd")
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
const BODY_SWORD_ATTACK_ANIMATION := "sword_attack"
const BODY_ATTACK_BASE_COOLDOWN := 0.75
const BODY_ATTACK_MIN_SPEED_SCALE := 0.55
const BODY_ATTACK_MAX_SPEED_SCALE := 2.4
const ATTACHMENT_PIVOT_OFFSET := Vector2(0.0, -2.0)

enum AttackPhase { IDLE, WINDUP, RECOVERY }

signal projectile_spawned(projectile: Node2D)
signal effect_spawned(effect: Node2D)
signal health_changed(current_health: float, max_health: float)
signal shot_fired(weapon_name: String)
signal exclusive_skill_used(skill_name: String, world_position: Vector2)
signal exclusive_skill_cooldown_changed(skill_name: String, cooldown_left: float, cooldown_total: float)
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
var critical_chance := 0.0
var critical_damage_multiplier := 1.5
var spell_power := 8.0

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
var _weapon_flash_duration := 0.0
var _weapon_pulse_left := 0.0
var _weapon_flash_color := Color(1.0, 0.92, 0.74, 0.0)
var _dead := false
var _selected_character_id := ""
var _selected_character_name := ""
var _character_armor := 0.0
var _exclusive_skill_definition: Dictionary = {}
var _exclusive_skill_cooldown_left := 0.0
var _exclusive_skill_cooldown_total := 0.0
var _exclusive_skill_display_seconds := -1
var _exclusive_skill_cooldown_multiplier := 1.0
var _exclusive_skill_radius_multiplier := 1.0
var _exclusive_skill_damage_multiplier := 1.0
var _exclusive_skill_damage_taken_multiplier := 1.0
var _exclusive_skill_defense_time_left := 0.0
var _selected_branch_id := ""
var _selected_branch_name := ""
var _branch_damage_taken_multiplier := 1.0
var _branch_armor := 0.0
var _branch_burn_damage := 0.0
var _branch_burn_duration := 0.0
var _branch_poison_damage := 0.0
var _branch_poison_duration := 0.0
var _branch_poison_stacks_per_apply := 1
var _branch_poison_max_stacks := 4
var _branch_status_apply_chance := 1.0
var _branch_status_damage_multiplier := 1.0
var _branch_status_spread_radius := 0.0
var _branch_status_spread_poison_stacks := 0
var _branch_status_burst_damage := 0.0
var _branch_status_burst_radius := 0.0
var _branch_vulnerable_duration := 0.0
var _branch_vulnerable_amount := 0.0
var _branch_burn_applies_vulnerable := false
var _branch_curse_damage := 0.0
var _branch_curse_duration := 0.0
var _branch_curse_stacks_per_apply := 1
var _branch_curse_max_stacks := 4
var _branch_corrosion_amount := 0.0
var _branch_corrosion_duration := 0.0
var _branch_corrosion_stacks_per_apply := 1
var _branch_corrosion_max_stacks := 5
var _branch_control_duration := 0.0
var _branch_control_chance := 0.0
var _branch_guard_shot_interval := 0
var _branch_guard_damage := 0.0
var _branch_guard_radius := 0.0
var _branch_guard_knockback := 0.0
var _branch_close_damage_bonus := 0.0
var _branch_close_damage_radius := 104.0
var _branch_reflect_damage := 0.0
var _branch_reflect_radius := 74.0
var _branch_kill_heal := 0.0
var _branch_low_health_damage_multiplier := 1.0
var _branch_low_health_threshold := 0.35
var _branch_shield_max := 0.0
var _branch_shield := 0.0
var _branch_block_chance := 0.0
var _branch_block_damage_multiplier := 1.0
var _branch_unstoppable_duration := 0.0
var _branch_shield_break_damage := 0.0
var _branch_shield_break_radius := 0.0
var _branch_hammer_slam_interval := 0
var _branch_hammer_slam_damage_multiplier := 0.0
var _branch_hammer_slam_radius_multiplier := 1.0
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
var _branch_animation_source := "legacy"
var _branch_spine_asset_key := ""
var _branch_spine_animation := ""
var _branch_spine_event_track := ""
var _branch_vfx_spine_key := ""
var _branch_hit_frame_progress := 1.0
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
var _branch_weapon_sequences: Dictionary = {}
var _branch_trail_sequences: Dictionary = {}
var _branch_impact_sequences: Dictionary = {}
var _branch_projectile_texture: Texture2D
var _branch_weapon_tint := Color(1.0, 1.0, 1.0, 1.0)
var _branch_flash_tint := Color(1.0, 0.92, 0.74, 0.95)
var _body_direction_key := "right"
var _body_sprite_frames: SpriteFrames
var _attack_phase: int = AttackPhase.IDLE
var _attack_phase_time_left := 0.0
var _attack_direction := Vector2.RIGHT
var _attack_target_position := Vector2.ZERO
var _attack_hit_resolved := false
var _unstoppable_time_left := 0.0

@onready var body_visual: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var hurtbox_shape: CollisionShape2D = $Hurtbox/CollisionShape2D
@onready var attack_point: Node2D = $AttackPoint
@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var weapon_visual: Sprite2D = $WeaponPivot/Weapon
@onready var weapon_trail: Sprite2D = $WeaponPivot/WeaponTrail
@onready var weapon_impact: Sprite2D = $WeaponPivot/WeaponImpact
@onready var slash_hitbox: Area2D = $SlashHitbox
@onready var slash_hitbox_shape: CollisionShape2D = $SlashHitbox/CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	add_to_group("player")
	hurtbox.add_to_group("player_hurtbox")
	hurtbox.set_meta("player_ref", self)
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
	_handle_exclusive_skill_timers(delta)
	_handle_invulnerability(delta)
	_unstoppable_time_left = maxf(_unstoppable_time_left - delta, 0.0)
	_update_weapon_animation(delta)
	_update_camera_shake(delta)


func apply_contact_damage(amount: float, source_position: Vector2) -> void:
	if current_health <= 0.0 or _invulnerability_left > 0.0 or _dead:
		return
	var armor_value: float = _character_armor + _branch_armor
	var resolved_damage: float = maxf(amount * _branch_damage_taken_multiplier * _exclusive_skill_damage_taken_multiplier - armor_value, 1.0)
	var blocked := false
	if _branch_block_chance > 0.0 and randf() <= _branch_block_chance:
		blocked = true
		resolved_damage *= _branch_block_damage_multiplier
		_unstoppable_time_left = maxf(_unstoppable_time_left, _branch_unstoppable_duration)
		if _branch_guard_damage > 0.0 and _branch_guard_radius > 0.0:
			_spawn_guard_burst(0.45, 0.72)
	if max_health > 0.0 and current_health <= max_health * _branch_low_health_threshold:
		resolved_damage *= _branch_low_health_damage_multiplier
	var shield_before: float = _branch_shield
	if _branch_shield > 0.0:
		# 护盾先承伤，破盾时触发反击波，形成“承伤转收益”的肉盾核心。
		var absorbed_damage: float = minf(_branch_shield, resolved_damage)
		_branch_shield = maxf(_branch_shield - absorbed_damage, 0.0)
		resolved_damage -= absorbed_damage
		if shield_before > 0.0 and _branch_shield <= 0.0:
			_trigger_shield_break_counter(source_position)
	current_health = maxf(current_health - resolved_damage, 0.0)
	_invulnerability_left = invulnerability_time
	var knockback_multiplier := 0.18 if blocked or _unstoppable_time_left > 0.0 else 1.0
	velocity += (global_position - source_position).normalized() * 160.0 * knockback_multiplier
	health_changed.emit(current_health, max_health)
	_trigger_feedback("hurt")
	trigger_camera_shake(8.0, 0.16)
	if _branch_reflect_damage > 0.0 and _branch_reflect_radius > 0.0:
		_reflect_damage_nearby(_branch_reflect_damage, _branch_reflect_radius, source_position)
	if _branch_guard_damage > 0.0 and _branch_guard_radius > 0.0:
		_spawn_guard_burst(0.72, 0.86)
	if current_health <= 0.0:
		_dead = true
		_weapon_flash_left = 0.0
		_weapon_pulse_left = 0.0
		_set_slash_hitbox_active(false)
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


func set_character_definition(character: Dictionary, skill: Dictionary) -> void:
	_selected_character_id = String(character.get("id", ""))
	_selected_character_name = String(character.get("name", ""))
	var base_stats: Dictionary = Dictionary(character.get("base_stats", {}))
	max_health = float(base_stats.get("max_health", max_health))
	current_health = max_health
	projectile_damage = float(base_stats.get("projectile_damage", projectile_damage))
	var attack_speed: float = maxf(float(base_stats.get("attack_speed", 1.0)), 0.2)
	projectile_cooldown = BODY_ATTACK_BASE_COOLDOWN / attack_speed
	move_speed = float(base_stats.get("move_speed", move_speed))
	_character_armor = maxf(float(base_stats.get("armor", 0.0)), 0.0)
	critical_chance = clampf(float(base_stats.get("critical_chance", 0.0)), 0.0, 0.65)
	spell_power = float(base_stats.get("spell_power", projectile_damage))
	_exclusive_skill_cooldown_multiplier = maxf(float(base_stats.get("skill_cooldown_multiplier", 1.0)), 0.2)
	_exclusive_skill_radius_multiplier = maxf(float(base_stats.get("skill_radius_multiplier", 1.0)), 0.2)
	_exclusive_skill_definition = skill.duplicate(true)
	_exclusive_skill_cooldown_left = 0.0
	_exclusive_skill_cooldown_total = _exclusive_skill_total_cooldown()
	_exclusive_skill_display_seconds = -1
	_exclusive_skill_defense_time_left = 0.0
	_exclusive_skill_damage_multiplier = 1.0
	_exclusive_skill_damage_taken_multiplier = 1.0
	_projectile_timer = minf(_projectile_timer, projectile_cooldown * 0.3)
	refresh_health_ui()
	_emit_exclusive_skill_cooldown(true)


func set_branch_definition(definition: Dictionary) -> void:
	_selected_branch_id = String(definition.get("id", ""))
	_selected_branch_name = String(definition.get("name", ""))
	_branch_damage_taken_multiplier = float(definition.get("damage_taken_multiplier", 1.0))
	_branch_armor = float(definition.get("armor", 0.0))
	_branch_burn_damage = float(definition.get("burn_damage", 0.0))
	_branch_burn_duration = float(definition.get("burn_duration", 0.0))
	_branch_poison_damage = float(definition.get("poison_damage", 0.0))
	_branch_poison_duration = float(definition.get("poison_duration", 0.0))
	_branch_poison_stacks_per_apply = int(definition.get("poison_stacks_per_apply", 1))
	_branch_poison_max_stacks = int(definition.get("poison_max_stacks", 4))
	_branch_status_apply_chance = clampf(float(definition.get("status_apply_chance", 1.0)), 0.0, 1.0)
	_branch_status_damage_multiplier = maxf(float(definition.get("status_damage_multiplier", 1.0)), 1.0)
	_branch_status_spread_radius = float(definition.get("status_spread_radius", 0.0))
	_branch_status_spread_poison_stacks = int(definition.get("status_spread_poison_stacks", 0))
	_branch_status_burst_damage = float(definition.get("status_burst_damage", 0.0))
	_branch_status_burst_radius = float(definition.get("status_burst_radius", 0.0))
	_branch_vulnerable_duration = float(definition.get("vulnerable_duration", 0.0))
	_branch_vulnerable_amount = float(definition.get("vulnerable_amount", 0.0))
	_branch_burn_applies_vulnerable = bool(definition.get("burn_applies_vulnerable", false))
	_branch_curse_damage = float(definition.get("curse_damage", 0.0))
	_branch_curse_duration = float(definition.get("curse_duration", 0.0))
	_branch_curse_stacks_per_apply = int(definition.get("curse_stacks_per_apply", 1))
	_branch_curse_max_stacks = int(definition.get("curse_max_stacks", 4))
	_branch_corrosion_amount = float(definition.get("corrosion_amount", 0.0))
	_branch_corrosion_duration = float(definition.get("corrosion_duration", 0.0))
	_branch_corrosion_stacks_per_apply = int(definition.get("corrosion_stacks_per_apply", 1))
	_branch_corrosion_max_stacks = int(definition.get("corrosion_max_stacks", 5))
	_branch_control_duration = float(definition.get("control_duration", 0.0))
	_branch_control_chance = clampf(float(definition.get("control_chance", 0.0)), 0.0, 1.0)
	_branch_guard_shot_interval = int(definition.get("guard_shot_interval", 0))
	_branch_guard_damage = float(definition.get("guard_damage", 0.0))
	_branch_guard_radius = float(definition.get("guard_radius", 0.0))
	_branch_guard_knockback = float(definition.get("guard_knockback", 0.0))
	_branch_close_damage_bonus = float(definition.get("close_damage_bonus", 0.0))
	_branch_close_damage_radius = float(definition.get("close_damage_radius", 104.0))
	_branch_reflect_damage = float(definition.get("reflect_damage", 0.0))
	_branch_reflect_radius = float(definition.get("reflect_radius", 74.0))
	_branch_kill_heal = float(definition.get("kill_heal", 0.0))
	_branch_low_health_damage_multiplier = clampf(float(definition.get("low_health_damage_multiplier", 1.0)), 0.35, 1.0)
	_branch_low_health_threshold = clampf(float(definition.get("low_health_threshold", 0.35)), 0.08, 0.75)
	_branch_shield_max = maxf(float(definition.get("shield_max", 0.0)), 0.0)
	_branch_shield = _branch_shield_max
	_branch_block_chance = clampf(float(definition.get("block_chance", 0.0)), 0.0, 0.85)
	_branch_block_damage_multiplier = clampf(float(definition.get("block_damage_multiplier", 1.0)), 0.12, 1.0)
	_branch_unstoppable_duration = maxf(float(definition.get("unstoppable_duration", 0.0)), 0.0)
	_branch_shield_break_damage = maxf(float(definition.get("shield_break_damage", 0.0)), 0.0)
	_branch_shield_break_radius = maxf(float(definition.get("shield_break_radius", 0.0)), 0.0)
	_branch_hammer_slam_interval = int(definition.get("hammer_slam_interval", 0))
	_branch_hammer_slam_damage_multiplier = maxf(float(definition.get("hammer_slam_damage_multiplier", 0.0)), 0.0)
	_branch_hammer_slam_radius_multiplier = maxf(float(definition.get("hammer_slam_radius_multiplier", 1.0)), 1.0)
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
	_branch_animation_source = String(definition.get("animation_source", "legacy"))
	_branch_spine_asset_key = String(definition.get("spine_asset_key", ""))
	_branch_spine_animation = String(definition.get("spine_animation", ""))
	_branch_spine_event_track = String(definition.get("spine_event_track", ""))
	_branch_vfx_spine_key = String(definition.get("vfx_spine_key", ""))
	_branch_hit_frame_progress = clampf(float(definition.get("hit_frame_progress", 1.0)), 0.15, 1.0)
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
	_branch_weapon_sequences = _normalize_sequence_dictionary(definition.get("weapon_sequences", {}), _branch_weapon_frames)
	_branch_trail_sequences = _normalize_sequence_dictionary(definition.get("trail_sequences", {}), {})
	_branch_impact_sequences = _normalize_sequence_dictionary(definition.get("impact_sequences", {}), _branch_flash_frames)
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


func try_use_exclusive_skill() -> bool:
	if _dead or _exclusive_skill_definition.is_empty() or _exclusive_skill_cooldown_left > 0.0:
		return false
	var skill_id: String = String(_exclusive_skill_definition.get("id", ""))
	var used := false
	match skill_id:
		"shadow_sword_array":
			used = _cast_shadow_sword_array()
		"arcane_bombardment":
			used = _cast_arcane_bombardment()
	if not used:
		return false
	_exclusive_skill_cooldown_total = _exclusive_skill_total_cooldown()
	_exclusive_skill_cooldown_left = _exclusive_skill_cooldown_total
	_emit_exclusive_skill_cooldown(true)
	exclusive_skill_used.emit(String(_exclusive_skill_definition.get("name", "")), global_position)
	return true


func _handle_exclusive_skill_timers(delta: float) -> void:
	if _exclusive_skill_cooldown_left > 0.0:
		_exclusive_skill_cooldown_left = maxf(_exclusive_skill_cooldown_left - delta, 0.0)
		_emit_exclusive_skill_cooldown(false)
	if _exclusive_skill_defense_time_left <= 0.0:
		_exclusive_skill_damage_taken_multiplier = 1.0
		return
	_exclusive_skill_defense_time_left = maxf(_exclusive_skill_defense_time_left - delta, 0.0)
	if _exclusive_skill_defense_time_left <= 0.0:
		_exclusive_skill_damage_taken_multiplier = 1.0


func _exclusive_skill_status_text() -> String:
	if _exclusive_skill_definition.is_empty():
		return "未选择"
	var skill_name: String = String(_exclusive_skill_definition.get("name", ""))
	return skill_name


func _exclusive_skill_total_cooldown() -> float:
	if _exclusive_skill_definition.is_empty():
		return 0.0
	return float(_exclusive_skill_definition.get("cooldown", 1.0)) * _exclusive_skill_cooldown_multiplier


func _emit_exclusive_skill_cooldown(force_emit: bool) -> void:
	var skill_name: String = String(_exclusive_skill_definition.get("name", ""))
	var display_seconds := int(ceilf(_exclusive_skill_cooldown_left))
	if not force_emit and display_seconds == _exclusive_skill_display_seconds:
		return
	_exclusive_skill_display_seconds = display_seconds
	exclusive_skill_cooldown_changed.emit(skill_name, _exclusive_skill_cooldown_left, _exclusive_skill_cooldown_total)


func _cast_shadow_sword_array() -> bool:
	var effect: SlashSequenceEffect = SLASH_SEQUENCE_EFFECT.new()
	var duration: float = float(_exclusive_skill_definition.get("duration", 1.2))
	var slash_damage: float = projectile_damage * float(_exclusive_skill_definition.get("damage_scale", 0.7)) * _exclusive_skill_damage_multiplier
	effect.global_position = global_position
	effect.setup(
		self,
		slash_damage,
		float(_exclusive_skill_definition.get("radius", 160.0)) * _exclusive_skill_radius_multiplier,
		int(_exclusive_skill_definition.get("slash_count", 5)),
		duration,
		int(_exclusive_skill_definition.get("max_hit_per_target", 4)),
		float(_exclusive_skill_definition.get("knockback", knockback_force * 0.65)),
		Color(0.86, 0.94, 1.0, 1.0)
	)
	effect_spawned.emit(effect)
	_exclusive_skill_damage_taken_multiplier = clampf(float(_exclusive_skill_definition.get("damage_taken_multiplier", 0.5)), 0.15, 1.0)
	_exclusive_skill_defense_time_left = duration
	trigger_camera_shake(4.4, 0.12)
	return true


func _cast_arcane_bombardment() -> bool:
	var effect: BombardmentCircleEffect = BOMBARDMENT_CIRCLE_EFFECT.new()
	var radius_multiplier := _exclusive_skill_radius_multiplier
	effect.global_position = global_position
	effect.setup(
		self,
		spell_power * float(_exclusive_skill_definition.get("damage_scale", 0.9)) * _exclusive_skill_damage_multiplier,
		float(_exclusive_skill_definition.get("radius", 180.0)) * radius_multiplier,
		float(_exclusive_skill_definition.get("explosion_radius", 45.0)) * radius_multiplier,
		float(_exclusive_skill_definition.get("duration", 4.0)),
		float(_exclusive_skill_definition.get("tick_interval", 0.35)),
		float(_exclusive_skill_definition.get("warning_delay", 0.28)),
		float(_exclusive_skill_definition.get("burn_damage", 0.0)),
		float(_exclusive_skill_definition.get("burn_duration", 0.0)),
		float(_exclusive_skill_definition.get("slow_duration", 0.0)),
		float(_exclusive_skill_definition.get("slow_amount", 1.0)),
		Color(0.56, 0.82, 1.0, 1.0)
	)
	effect_spawned.emit(effect)
	trigger_camera_shake(3.2, 0.08)
	return true


func on_enemy_defeated(world_position: Vector2, status_snapshot: Dictionary, was_elite: bool, was_boss: bool) -> void:
	if _dead:
		return
	if _branch_kill_heal > 0.0:
		var heal_amount: float = _branch_kill_heal
		if was_elite:
			heal_amount *= 1.5
		elif was_boss:
			heal_amount *= 2.5
		current_health = clampf(current_health + heal_amount, 0.0, max_health)
		health_changed.emit(current_health, max_health)
	if _selected_branch_id != "debuff" or status_snapshot.is_empty():
		return
	var total_layers: int = _status_snapshot_layer_count(status_snapshot)
	if total_layers <= 0:
		return
	if _branch_status_burst_damage > 0.0 and _branch_status_burst_radius > 0.0:
		var burst_damage: float = _branch_status_burst_damage * (1.0 + float(total_layers - 1) * 0.18)
		var burst: GuardBurst = GUARD_BURST_SCENE.instantiate() as GuardBurst
		burst.global_position = world_position
		burst.setup(
			burst_damage,
			_branch_status_burst_radius,
			0.18,
			knockback_force * 0.42,
			_branch_weapon_tint.lerp(Color(0.56, 0.94, 0.46, 1.0), 0.45)
		)
		effect_spawned.emit(burst)
		_debug_branch_status_event("detonate", "radius=%.1f layers=%d" % [_branch_status_burst_radius, total_layers])
	if _branch_status_spread_radius <= 0.0:
		return
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy: Enemy = enemy_node as Enemy
		if enemy == null or not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		if enemy.global_position.distance_to(world_position) > _branch_status_spread_radius:
			continue
		_spread_death_statuses(enemy, status_snapshot)
		_debug_branch_status_event("spread", "radius=%.1f stacks=%d" % [_branch_status_spread_radius, _branch_status_spread_poison_stacks])


func _spread_death_statuses(enemy: Enemy, status_snapshot: Dictionary) -> void:
	# 死亡传播保留原异常语义：DOT 传播伤害层，功能异常传播较短持续时间。
	if status_snapshot.has("poison") and _branch_status_spread_poison_stacks > 0:
		enemy.apply_status_effect(
			"poison",
			maxf(_branch_poison_duration, 1.0),
			maxf(_branch_poison_damage, 1.0),
			_branch_status_spread_poison_stacks,
			_branch_poison_max_stacks
		)
	if status_snapshot.has("burn") and _branch_burn_damage > 0.0:
		enemy.apply_status_effect("burn", maxf(_branch_burn_duration * 0.75, 0.8), _branch_burn_damage, 1, 4)
	if status_snapshot.has("curse") and _branch_curse_damage > 0.0:
		enemy.apply_status_effect("curse", maxf(_branch_curse_duration * 0.72, 0.8), _branch_curse_damage, 1, _branch_curse_max_stacks)
	if status_snapshot.has("corrosion") and _branch_corrosion_amount > 0.0:
		enemy.apply_status_effect("corrosion", maxf(_branch_corrosion_duration * 0.72, 0.8), _branch_corrosion_amount, 1, _branch_corrosion_max_stacks)
	if status_snapshot.has("control") and _branch_control_duration > 0.0:
		enemy.apply_status_effect("control", minf(_branch_control_duration, 0.32), 0.0)


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
	if not _selected_character_name.is_empty():
		summary = "人物 %s | 技能 %s | %s" % [_selected_character_name, _exclusive_skill_status_text(), summary]
	if not _selected_branch_name.is_empty():
		summary = "分支 %s | %s" % [_selected_branch_name, summary]
	var branch_mechanic_text := _branch_mechanic_summary()
	if not branch_mechanic_text.is_empty():
		summary += " | 机制 %s" % branch_mechanic_text
	if _branch_armor > 0.0:
		summary += " | 护甲 %.0f" % (_character_armor + _branch_armor)
	elif _character_armor > 0.0:
		summary += " | 护甲 %.0f" % _character_armor
	if _branch_shield_max > 0.0:
		summary += " | 护盾 %.0f/%.0f" % [_branch_shield, _branch_shield_max]
	if _branch_curse_damage > 0.0 or _branch_corrosion_amount > 0.0 or _branch_control_chance > 0.0:
		summary += " | 异常 咒%.1f/蚀%.0f%%/控%.0f%%" % [
			_branch_curse_damage,
			_branch_corrosion_amount * 100.0,
			_branch_control_chance * 100.0
		]
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
	if _attack_phase == AttackPhase.IDLE:
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
	_set_slash_hitbox_active(false)
	if _branch_weapon_type == "melee":
		_start_body_attack_animation(direction)
	body_visual.scale = Vector2(1.03, 0.98)


func _update_attack_state(delta: float) -> void:
	if _attack_phase == AttackPhase.IDLE:
		return
	_attack_phase_time_left = maxf(_attack_phase_time_left - delta, 0.0)
	if _attack_phase == AttackPhase.WINDUP:
		if _attack_hit_resolved:
			return
		if _attack_phase_progress(_branch_windup_time) < _branch_hit_frame_progress and _attack_phase_time_left > 0.0:
			return
		_attack_hit_resolved = true
		_resolve_primary_attack()
		if _branch_weapon_type == "melee":
			_set_slash_hitbox_active(true)
		_attack_phase = AttackPhase.RECOVERY
		_attack_phase_time_left = maxf(_branch_recovery_time, 0.01)
		return
	if _attack_phase == AttackPhase.RECOVERY and _attack_phase_time_left <= 0.0:
		_attack_phase = AttackPhase.IDLE
		_attack_hit_resolved = false
		_set_slash_hitbox_active(false)


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
	var hammer_slam_active := _branch_hammer_slam_interval > 0 and _attack_sequence % _branch_hammer_slam_interval == 0
	if hammer_slam_active:
		# 重锤段不改攻击范式，只在真实近战命中帧强化一次范围压制。
		damage_value *= 1.0 + _branch_hammer_slam_damage_multiplier
		melee_reach *= _branch_hammer_slam_radius_multiplier
		melee_arc_radians = minf(melee_arc_radians * _branch_hammer_slam_radius_multiplier, PI)
	damage_value *= _close_quarters_damage_multiplier()
	var knockback_value: float = knockback_force * (1.32 if overcharge_active else 1.08)
	if hammer_slam_active:
		knockback_value *= 1.38
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
				enemy.take_damage(_roll_primary_damage(damage_value) * _damage_multiplier_against_enemy(enemy), global_position, knockback_value)
				_apply_branch_hit_statuses(enemy)
				enemy_hit = true
				hit_any = true
				break
		if enemy_hit and overcharge_active:
			enemy.velocity += direction * 26.0
	if hit_any:
		trigger_camera_shake(2.0 if not overcharge_active else 2.8, 0.05)
		if hammer_slam_active and _branch_guard_damage > 0.0 and _branch_guard_radius > 0.0:
			_spawn_guard_burst(0.85 + _branch_hammer_slam_damage_multiplier, _branch_hammer_slam_radius_multiplier)


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
	var projectile_damage_value: float = _roll_primary_damage(projectile_damage * (1.45 if overcharge_active else 1.0))
	var projectile_speed_value: float = projectile_speed * _branch_projectile_speed_multiplier * (1.12 if overcharge_active else 1.0)
	var projectile_range_value: float = projectile_range * _branch_projectile_range_multiplier + (32.0 if _has_linebreak_synergy() else 0.0)
	var projectile_pierce_value: int = projectile_pierce + (1 if bonus_pierce else 0)
	projectile.global_position = _attack_point_world_position(direction)
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
	_configure_status_payload(projectile)
	projectile.set_damage_vs_status_multiplier(_branch_status_damage_multiplier)
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
	_configure_status_payload(pulse)
	pulse.set_damage_vs_status_multiplier(_branch_status_damage_multiplier)
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
		"critical_chance":
			critical_chance = clampf(critical_chance + amount, 0.0, 0.65)
		"critical_damage":
			critical_damage_multiplier = clampf(critical_damage_multiplier + amount, 1.1, 3.0)
		"spell_power":
			spell_power = maxf(spell_power + amount, 0.0)
		"character_armor":
			_character_armor = clampf(_character_armor + amount, 0.0, 18.0)
		"exclusive_skill_damage_multiplier":
			_exclusive_skill_damage_multiplier = clampf(_exclusive_skill_damage_multiplier + amount, 0.4, 2.6)
		"exclusive_skill_cooldown_multiplier":
			_exclusive_skill_cooldown_multiplier = clampf(_exclusive_skill_cooldown_multiplier + amount, 0.45, 1.5)
			_exclusive_skill_cooldown_total = _exclusive_skill_total_cooldown()
			_emit_exclusive_skill_cooldown(true)
		"exclusive_skill_radius_multiplier":
			_exclusive_skill_radius_multiplier = clampf(_exclusive_skill_radius_multiplier + amount, 0.35, 2.4)
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
		"branch_armor":
			_branch_armor = clampf(_branch_armor + amount, 0.0, 24.0)
		"branch_burn_damage":
			_branch_burn_damage = maxf(_branch_burn_damage + amount, 0.0)
		"branch_burn_duration":
			_branch_burn_duration = clampf(_branch_burn_duration + amount, 0.0, 12.0)
		"branch_poison_damage":
			_branch_poison_damage = maxf(_branch_poison_damage + amount, 0.0)
		"branch_poison_duration":
			_branch_poison_duration = clampf(_branch_poison_duration + amount, 0.0, 12.0)
		"branch_poison_apply_stacks":
			_branch_poison_stacks_per_apply = clampi(_branch_poison_stacks_per_apply + int(amount), 1, 6)
		"branch_poison_max_stacks":
			_branch_poison_max_stacks = clampi(_branch_poison_max_stacks + int(amount), 1, 12)
		"branch_status_apply_chance":
			_branch_status_apply_chance = clampf(_branch_status_apply_chance + amount, 0.05, 1.0)
		"branch_status_damage_multiplier":
			_branch_status_damage_multiplier = clampf(_branch_status_damage_multiplier + amount, 1.0, 3.0)
		"branch_status_spread_radius":
			_branch_status_spread_radius = clampf(_branch_status_spread_radius + amount, 0.0, 240.0)
		"branch_status_spread_poison_stacks":
			_branch_status_spread_poison_stacks = clampi(_branch_status_spread_poison_stacks + int(amount), 0, 5)
		"branch_status_burst_damage":
			_branch_status_burst_damage = maxf(_branch_status_burst_damage + amount, 0.0)
		"branch_status_burst_radius":
			_branch_status_burst_radius = clampf(_branch_status_burst_radius + amount, 0.0, 220.0)
		"branch_vulnerable_duration":
			_branch_vulnerable_duration = clampf(_branch_vulnerable_duration + amount, 0.0, 10.0)
		"branch_vulnerable_amount":
			_branch_vulnerable_amount = clampf(_branch_vulnerable_amount + amount, 0.0, 1.2)
		"branch_burn_applies_vulnerable":
			_branch_burn_applies_vulnerable = amount > 0.0 or _branch_burn_applies_vulnerable
		"branch_curse_damage":
			_branch_curse_damage = maxf(_branch_curse_damage + amount, 0.0)
		"branch_curse_duration":
			_branch_curse_duration = clampf(_branch_curse_duration + amount, 0.0, 12.0)
		"branch_curse_apply_stacks":
			_branch_curse_stacks_per_apply = clampi(_branch_curse_stacks_per_apply + int(amount), 1, 6)
		"branch_curse_max_stacks":
			_branch_curse_max_stacks = clampi(_branch_curse_max_stacks + int(amount), 1, 10)
		"branch_corrosion_amount":
			_branch_corrosion_amount = clampf(_branch_corrosion_amount + amount, 0.0, 0.35)
		"branch_corrosion_duration":
			_branch_corrosion_duration = clampf(_branch_corrosion_duration + amount, 0.0, 12.0)
		"branch_corrosion_apply_stacks":
			_branch_corrosion_stacks_per_apply = clampi(_branch_corrosion_stacks_per_apply + int(amount), 1, 6)
		"branch_corrosion_max_stacks":
			_branch_corrosion_max_stacks = clampi(_branch_corrosion_max_stacks + int(amount), 1, 12)
		"branch_control_chance":
			_branch_control_chance = clampf(_branch_control_chance + amount, 0.0, 0.75)
		"branch_control_duration":
			_branch_control_duration = clampf(_branch_control_duration + amount, 0.0, 2.0)
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
		"branch_melee_range":
			_branch_attack_range = clampf(_branch_attack_range + amount, 32.0, 220.0)
		"branch_attack_arc":
			_branch_attack_arc = clampf(_branch_attack_arc + amount, 45.0, 180.0)
		"branch_close_damage_bonus":
			_branch_close_damage_bonus = clampf(_branch_close_damage_bonus + amount, 0.0, 0.45)
		"branch_close_damage_radius":
			_branch_close_damage_radius = clampf(_branch_close_damage_radius + amount, 48.0, 220.0)
		"branch_reflect_damage":
			_branch_reflect_damage = maxf(_branch_reflect_damage + amount, 0.0)
		"branch_reflect_radius":
			_branch_reflect_radius = clampf(_branch_reflect_radius + amount, 24.0, 180.0)
		"branch_kill_heal":
			_branch_kill_heal = clampf(_branch_kill_heal + amount, 0.0, 25.0)
		"branch_low_health_damage_multiplier":
			_branch_low_health_damage_multiplier = clampf(_branch_low_health_damage_multiplier * amount, 0.28, 1.0)
		"branch_low_health_threshold":
			_branch_low_health_threshold = clampf(_branch_low_health_threshold + amount, 0.08, 0.75)
		"branch_shield_max":
			_branch_shield_max = clampf(_branch_shield_max + amount, 0.0, 160.0)
			_branch_shield = clampf(_branch_shield + amount, 0.0, _branch_shield_max)
		"branch_block_chance":
			_branch_block_chance = clampf(_branch_block_chance + amount, 0.0, 0.85)
		"branch_block_damage_multiplier":
			_branch_block_damage_multiplier = clampf(_branch_block_damage_multiplier * amount, 0.12, 1.0)
		"branch_unstoppable_duration":
			_branch_unstoppable_duration = clampf(_branch_unstoppable_duration + amount, 0.0, 1.5)
		"branch_shield_break_damage":
			_branch_shield_break_damage = maxf(_branch_shield_break_damage + amount, 0.0)
		"branch_shield_break_radius":
			_branch_shield_break_radius = clampf(_branch_shield_break_radius + amount, 0.0, 220.0)
		"branch_hammer_slam_interval_delta":
			if _branch_hammer_slam_interval <= 0:
				_branch_hammer_slam_interval = 4
			_branch_hammer_slam_interval = clampi(_branch_hammer_slam_interval + int(amount), 2, 10)
		"branch_hammer_slam_damage_multiplier":
			_branch_hammer_slam_damage_multiplier = clampf(_branch_hammer_slam_damage_multiplier + amount, 0.0, 1.4)
		"branch_hammer_slam_radius_multiplier":
			_branch_hammer_slam_radius_multiplier = clampf(_branch_hammer_slam_radius_multiplier + amount, 1.0, 2.1)
		_:
			push_warning("Unknown upgrade effect: %s" % effect_type)


func _configure_status_payload(target: Object) -> void:
	if target == null:
		return
	if target.has_method("clear_status_effects"):
		target.call("clear_status_effects")
	if _branch_burn_damage > 0.0 and _branch_burn_duration > 0.0 and target.has_method("add_status_effect"):
		target.call("add_status_effect", "burn", _branch_burn_duration, _branch_burn_damage, 1, 4, 1.0)
	if _branch_burn_applies_vulnerable and _branch_vulnerable_duration > 0.0 and _branch_vulnerable_amount > 0.0 and target.has_method("add_status_effect"):
		target.call("add_status_effect", "vulnerable", _branch_vulnerable_duration, _branch_vulnerable_amount, 1, 1, 1.0)
	elif _branch_vulnerable_duration > 0.0 and _branch_vulnerable_amount > 0.0 and target.has_method("add_status_effect"):
		target.call("add_status_effect", "vulnerable", _branch_vulnerable_duration, _branch_vulnerable_amount, 1, 1, _branch_status_apply_chance)
	if _branch_poison_damage > 0.0 and _branch_poison_duration > 0.0 and target.has_method("add_status_effect"):
		target.call(
			"add_status_effect",
			"poison",
			_branch_poison_duration,
			_branch_poison_damage,
			_branch_poison_stacks_per_apply,
			_branch_poison_max_stacks,
			_branch_status_apply_chance
		)
	if _branch_curse_damage > 0.0 and _branch_curse_duration > 0.0 and target.has_method("add_status_effect"):
		target.call("add_status_effect", "curse", _branch_curse_duration, _branch_curse_damage, _branch_curse_stacks_per_apply, _branch_curse_max_stacks, _branch_status_apply_chance)
	if _branch_corrosion_amount > 0.0 and _branch_corrosion_duration > 0.0 and target.has_method("add_status_effect"):
		target.call("add_status_effect", "corrosion", _branch_corrosion_duration, _branch_corrosion_amount, _branch_corrosion_stacks_per_apply, _branch_corrosion_max_stacks, _branch_status_apply_chance)
	if _branch_control_duration > 0.0 and _branch_control_chance > 0.0 and target.has_method("add_status_effect"):
		# 控制只作为短窗口压制，概率独立，避免和 DOT 施加率绑定后过强。
		target.call("add_status_effect", "control", _branch_control_duration, 0.0, 1, 1, _branch_control_chance)


func _apply_branch_hit_statuses(enemy: Enemy) -> void:
	if enemy == null:
		return
	if _branch_burn_damage > 0.0 and _branch_burn_duration > 0.0:
		enemy.apply_status_effect("burn", _branch_burn_duration, _branch_burn_damage, 1, 4)
	if _branch_burn_applies_vulnerable and _branch_vulnerable_duration > 0.0 and _branch_vulnerable_amount > 0.0:
		enemy.apply_status_effect("vulnerable", _branch_vulnerable_duration, _branch_vulnerable_amount)
	elif _branch_vulnerable_duration > 0.0 and _branch_vulnerable_amount > 0.0 and randf() <= _branch_status_apply_chance:
		enemy.apply_status_effect("vulnerable", _branch_vulnerable_duration, _branch_vulnerable_amount)
	if _branch_poison_damage > 0.0 and _branch_poison_duration > 0.0 and randf() <= _branch_status_apply_chance:
		enemy.apply_status_effect(
			"poison",
			_branch_poison_duration,
			_branch_poison_damage,
			_branch_poison_stacks_per_apply,
			_branch_poison_max_stacks
		)
	if _branch_curse_damage > 0.0 and _branch_curse_duration > 0.0 and randf() <= _branch_status_apply_chance:
		enemy.apply_status_effect("curse", _branch_curse_duration, _branch_curse_damage, _branch_curse_stacks_per_apply, _branch_curse_max_stacks)
	if _branch_corrosion_amount > 0.0 and _branch_corrosion_duration > 0.0 and randf() <= _branch_status_apply_chance:
		enemy.apply_status_effect("corrosion", _branch_corrosion_duration, _branch_corrosion_amount, _branch_corrosion_stacks_per_apply, _branch_corrosion_max_stacks)
	if _branch_control_duration > 0.0 and _branch_control_chance > 0.0 and randf() <= _branch_control_chance:
		enemy.apply_status_effect("control", _branch_control_duration, 0.0)
	_debug_branch_status_event("apply", "burn=%.1f poison=%.1f curse=%.1f corrosion=%.2f control=%.2f" % [_branch_burn_damage, _branch_poison_damage, _branch_curse_damage, _branch_corrosion_amount, _branch_control_chance])


func _damage_multiplier_against_enemy(enemy: Enemy) -> float:
	if enemy == null:
		return 1.0
	if _branch_status_damage_multiplier > 1.0 and enemy.has_any_status_effect():
		return _branch_status_damage_multiplier
	return 1.0


func _roll_primary_damage(base_damage: float) -> float:
	if critical_chance <= 0.0:
		return base_damage
	if randf() > critical_chance:
		return base_damage
	return base_damage * critical_damage_multiplier


func _close_quarters_damage_multiplier() -> float:
	if _branch_close_damage_bonus <= 0.0:
		return 1.0
	var nearby_enemy_count: int = _count_nearby_enemies(_branch_close_damage_radius)
	return 1.0 + float(mini(nearby_enemy_count, 4)) * _branch_close_damage_bonus


func _count_nearby_enemies(radius: float) -> int:
	var count := 0
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy: Enemy = enemy_node as Enemy
		if enemy == null or not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		if enemy.global_position.distance_to(global_position) <= radius:
			count += 1
	return count


func _reflect_damage_nearby(damage: float, radius: float, source_position: Vector2) -> void:
	var reflected_any := false
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy: Enemy = enemy_node as Enemy
		if enemy == null or not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		if enemy.global_position.distance_to(global_position) > radius:
			continue
		var reflected_damage: float = damage
		if enemy.global_position.distance_to(source_position) <= 24.0:
			reflected_damage *= 1.35
		enemy.take_damage(reflected_damage, global_position, knockback_force * 0.4)
		reflected_any = true
	if reflected_any:
		_debug_branch_status_event("counter", "reflect=%.1f radius=%.1f" % [damage, radius])


func _trigger_shield_break_counter(source_position: Vector2) -> void:
	if _branch_shield_break_damage <= 0.0 or _branch_shield_break_radius <= 0.0:
		return
	# 破盾反击使用现有 GuardBurst 特效，保证导出资源链路稳定，不额外引入场景依赖。
	var burst := GUARD_BURST_SCENE.instantiate()
	burst.global_position = global_position
	burst.setup(
		_branch_shield_break_damage,
		_branch_shield_break_radius,
		0.22,
		maxf(_branch_guard_knockback, 220.0),
		_branch_weapon_tint.lightened(0.18)
	)
	effect_spawned.emit(burst)
	_reflect_damage_nearby(_branch_shield_break_damage * 0.35, _branch_shield_break_radius, source_position)
	_unstoppable_time_left = maxf(_unstoppable_time_left, _branch_unstoppable_duration)
	trigger_camera_shake(4.2, 0.1)
	_debug_branch_status_event("shield_break", "damage=%.1f radius=%.1f" % [_branch_shield_break_damage, _branch_shield_break_radius])


func _status_snapshot_layer_count(status_snapshot: Dictionary) -> int:
	var total_layers := 0
	for raw_status in status_snapshot.keys():
		var status: Dictionary = Dictionary(status_snapshot.get(raw_status, {}))
		total_layers += maxi(int(status.get("stacks", 1)), 1)
	return total_layers


func _debug_branch_status_event(event_name: String, detail: String) -> void:
	print_verbose("[branch][%s][%s] %s" % [_selected_branch_id, event_name, detail])


func _apply_shape() -> void:
	var circle := collision_shape.shape as CircleShape2D
	if circle != null:
		circle.radius = 14.0
	var hurt_circle := hurtbox_shape.shape as CircleShape2D
	if hurt_circle != null:
		hurt_circle.radius = 15.0
	var slash_circle := slash_hitbox_shape.shape as CircleShape2D
	if slash_circle != null:
		slash_circle.radius = 42.0
	body_visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body_visual.centered = true
	body_visual.sprite_frames = _build_body_sprite_frames()
	body_visual.play("right")
	body_visual.stop()
	body_visual.frame = 0
	body_visual.rotation = 0.0
	weapon_pivot.position = ATTACHMENT_PIVOT_OFFSET
	weapon_visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	weapon_visual.centered = true
	weapon_visual.texture = _branch_weapon_frame("idle")
	weapon_visual.scale = Vector2.ONE * _branch_weapon_base_scale
	weapon_trail.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	weapon_trail.centered = true
	weapon_trail.texture = _sequence_frame(_branch_trail_sequences, "release", 0.0, _branch_flash_frame("a"))
	weapon_trail.scale = Vector2.ONE * _branch_flash_base_scale
	weapon_trail.modulate = Color(1.0, 1.0, 1.0, 0.0)
	weapon_impact.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	weapon_impact.centered = true
	weapon_impact.texture = _sequence_frame(_branch_impact_sequences, "release", 0.0, _branch_flash_frame("a"))
	weapon_impact.scale = Vector2.ONE * _branch_flash_base_scale
	weapon_impact.modulate = Color(1.0, 1.0, 1.0, 0.0)
	hurtbox.collision_layer = 4
	hurtbox.collision_mask = 0
	hurtbox.monitoring = true
	hurtbox.monitorable = true
	slash_hitbox.collision_layer = 0
	slash_hitbox.collision_mask = 2
	slash_hitbox.monitorable = false
	_set_slash_hitbox_active(false)
	attack_point.position = _attack_point_local_position(_last_move_direction)
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
	_weapon_flash_duration = _weapon_flash_left
	_weapon_flash_color = _branch_flash_tint
	if overcharge_active:
		_weapon_flash_color = _branch_flash_tint.lightened(0.12)
	body_visual.scale = Vector2(1.04, 0.97)


func _trigger_pulse_fire() -> void:
	_weapon_flash_left = maxf(_weapon_flash_left, 0.11)
	_weapon_flash_duration = _weapon_flash_left
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
	_update_body_animation(direction)
	weapon_pivot.position = ATTACHMENT_PIVOT_OFFSET
	attack_point.position = _attack_point_local_position(direction)
	_update_slash_hitbox_transform(direction)
	var weapon_position := direction * _branch_weapon_length
	var weapon_rotation := direction.angle()
	var weapon_phase_key := "idle"
	var weapon_phase_progress := 0.0
	var weapon_texture: Texture2D = _sequence_frame(_branch_weapon_sequences, weapon_phase_key, weapon_phase_progress, _branch_weapon_frame("idle"))
	var flash_position := direction * _branch_flash_distance
	var flash_rotation := direction.angle()
	match _branch_weapon_type:
		"melee":
			if _attack_phase == AttackPhase.WINDUP:
				var windup_progress := _attack_phase_progress(_branch_windup_time)
				weapon_phase_key = "windup"
				weapon_phase_progress = windup_progress
				weapon_position = direction.rotated(-0.9) * (_branch_weapon_length - 5.0 + windup_progress * 3.0)
				weapon_rotation = direction.angle() - 1.2 + windup_progress * 0.32
			elif _attack_phase == AttackPhase.RECOVERY:
				var recovery_progress := _attack_phase_progress(_branch_recovery_time)
				if recovery_progress < 0.42:
					weapon_phase_key = "release"
					weapon_phase_progress = recovery_progress / 0.42
				else:
					weapon_phase_key = "recover"
					weapon_phase_progress = (recovery_progress - 0.42) / 0.58
				weapon_position = direction.rotated(0.55) * (_branch_weapon_length + 4.0 - recovery_progress * 2.0)
				weapon_rotation = direction.angle() + lerpf(1.08, 0.14, recovery_progress)
			else:
				weapon_phase_key = "idle"
				weapon_phase_progress = 0.0
				weapon_position = direction.rotated(-0.16) * (_branch_weapon_length - 2.0)
				weapon_rotation = direction.angle() + 0.28
			flash_position = direction.rotated(0.38) * _branch_flash_distance
			flash_rotation = direction.angle() + 0.24
		"thrown":
			if _attack_phase == AttackPhase.WINDUP:
				var cast_progress := _attack_phase_progress(_branch_windup_time)
				weapon_phase_key = "windup"
				weapon_phase_progress = cast_progress
				weapon_position = direction.rotated(-0.46) * (_branch_weapon_length - 4.0)
				weapon_rotation = direction.angle() - 0.72 + cast_progress * 0.18
			elif _attack_phase == AttackPhase.RECOVERY:
				var release_progress := _attack_phase_progress(_branch_recovery_time)
				if release_progress < 0.58:
					weapon_phase_key = "release"
					weapon_phase_progress = release_progress / 0.58
				else:
					weapon_phase_key = "recover"
					weapon_phase_progress = (release_progress - 0.58) / 0.42
				weapon_position = direction * (_branch_weapon_length + 3.0 - release_progress)
				weapon_rotation = direction.angle() + lerpf(0.42, 0.08, release_progress)
			else:
				weapon_phase_key = "idle"
				weapon_phase_progress = 0.0
				weapon_position = direction.rotated(0.18) * _branch_weapon_length
				weapon_rotation = direction.angle() + 0.34
			flash_position = direction * _branch_flash_distance
			flash_rotation = direction.angle()
		_:
			if _attack_phase == AttackPhase.WINDUP:
				var charge_progress := _attack_phase_progress(_branch_windup_time)
				weapon_phase_key = "windup"
				weapon_phase_progress = charge_progress
				weapon_position = direction * (_branch_weapon_length - 4.0)
				weapon_rotation = direction.angle() - 0.18 + charge_progress * 0.08
			elif _attack_phase == AttackPhase.RECOVERY:
				var release_snap_progress := _attack_phase_progress(_branch_recovery_time)
				if release_snap_progress < 0.62:
					weapon_phase_key = "release"
					weapon_phase_progress = release_snap_progress / 0.62
				else:
					weapon_phase_key = "recover"
					weapon_phase_progress = (release_snap_progress - 0.62) / 0.38
				weapon_position = direction * (_branch_weapon_length + 4.0 - release_snap_progress * 2.0)
				weapon_rotation = direction.angle() + 0.08
			else:
				weapon_phase_key = "idle"
				weapon_phase_progress = 0.0
				weapon_position = direction * _branch_weapon_length
				weapon_rotation = direction.angle() + 0.12
			flash_position = direction * _branch_flash_distance
			flash_rotation = direction.angle()
	weapon_texture = _sequence_frame(_branch_weapon_sequences, weapon_phase_key, weapon_phase_progress, _branch_weapon_frame(weapon_phase_key))
	weapon_visual.texture = weapon_texture
	weapon_visual.position = weapon_position - direction * _weapon_recoil_strength
	weapon_visual.rotation = weapon_rotation
	weapon_visual.scale = Vector2.ONE * _branch_weapon_base_scale * (1.0 + _weapon_pulse_left * 0.45)

	var trail_texture: Texture2D = _sequence_frame(_branch_trail_sequences, weapon_phase_key, weapon_phase_progress, null)
	weapon_trail.position = flash_position
	weapon_trail.rotation = flash_rotation
	weapon_trail.scale = Vector2.ONE * _branch_flash_base_scale * (0.88 + _weapon_pulse_left * 0.3)
	if trail_texture != null and weapon_phase_key != "idle":
		var trail_alpha := _trail_alpha_for_phase(weapon_phase_key, weapon_phase_progress)
		weapon_trail.texture = trail_texture
		weapon_trail.modulate = Color(_branch_flash_tint.r, _branch_flash_tint.g, _branch_flash_tint.b, trail_alpha)
	else:
		weapon_trail.modulate = Color(1.0, 1.0, 1.0, 0.0)

	weapon_impact.position = flash_position + direction * 4.0
	weapon_impact.rotation = flash_rotation
	if _weapon_flash_left > 0.0:
		var flash_progress := 1.0 - (_weapon_flash_left / maxf(_weapon_flash_duration, 0.01))
		var impact_texture: Texture2D = _sequence_frame(_branch_impact_sequences, "release", flash_progress, _branch_flash_frame("a"))
		var flash_alpha: float = clampf(1.0 - flash_progress, 0.0, 1.0)
		weapon_impact.texture = impact_texture
		weapon_impact.modulate = Color(_weapon_flash_color.r, _weapon_flash_color.g, _weapon_flash_color.b, flash_alpha)
		weapon_impact.scale = Vector2.ONE * _branch_flash_base_scale * (0.95 + flash_alpha * 0.55)
	else:
		weapon_impact.texture = _sequence_frame(_branch_impact_sequences, "release", 0.0, _branch_flash_frame("a"))
		weapon_impact.modulate = Color(1.0, 1.0, 1.0, 0.0)
		weapon_impact.scale = Vector2.ONE * _branch_flash_base_scale


func _apply_branch_visual_style() -> void:
	if weapon_visual == null or weapon_trail == null or weapon_impact == null:
		return
	weapon_pivot.position = ATTACHMENT_PIVOT_OFFSET
	attack_point.position = _attack_point_local_position(_last_move_direction)
	_update_slash_hitbox_transform(_last_move_direction)
	weapon_visual.texture = _sequence_frame(_branch_weapon_sequences, "idle", 0.0, _branch_weapon_frame("idle"))
	weapon_visual.scale = Vector2.ONE * _branch_weapon_base_scale
	weapon_visual.modulate = _branch_weapon_tint
	weapon_trail.texture = _sequence_frame(_branch_trail_sequences, "release", 0.0, _branch_flash_frame("a"))
	weapon_trail.scale = Vector2.ONE * _branch_flash_base_scale
	weapon_trail.modulate = Color(1.0, 1.0, 1.0, 0.0)
	weapon_impact.texture = _sequence_frame(_branch_impact_sequences, "release", 0.0, _branch_flash_frame("a"))
	weapon_impact.scale = Vector2.ONE * _branch_flash_base_scale
	weapon_impact.modulate = Color(1.0, 1.0, 1.0, 0.0)


func _build_body_sprite_frames() -> SpriteFrames:
	if _body_sprite_frames != null:
		return _body_sprite_frames
	if body_visual != null and body_visual.sprite_frames != null:
		_body_sprite_frames = body_visual.sprite_frames
		return _body_sprite_frames
	push_warning("Player AnimatedSprite2D is missing SpriteFrames resource.")
	_body_sprite_frames = SpriteFrames.new()
	return _body_sprite_frames


func _set_body_animation(animation_key: String, frame_index: int, flip_h: bool) -> void:
	if body_visual == null or body_visual.sprite_frames == null:
		return
	if not body_visual.sprite_frames.has_animation(animation_key):
		return
	if body_visual.animation != animation_key:
		body_visual.play(animation_key)
		body_visual.stop()
	body_visual.speed_scale = 1.0
	body_visual.flip_h = flip_h
	body_visual.frame = clampi(frame_index, 0, body_visual.sprite_frames.get_frame_count(animation_key) - 1)


func _update_body_animation(direction: Vector2) -> void:
	if _branch_weapon_type == "melee" and _attack_phase != AttackPhase.IDLE:
		var attack_direction: Vector2 = direction
		if attack_direction == Vector2.ZERO:
			attack_direction = _last_move_direction
		_sync_body_attack_animation(attack_direction)
		return
	_update_body_direction_sprite(direction)


func _start_body_attack_animation(direction: Vector2) -> void:
	if not _can_play_body_attack_animation():
		return
	# 攻击动画交给 Player 下的 AnimatedSprite2D 播放，脚本只同步朝向和攻速倍率。
	body_visual.flip_h = direction.x < -0.08
	body_visual.speed_scale = _body_attack_playback_scale()
	body_visual.frame = 0
	body_visual.frame_progress = 0.0
	body_visual.play(BODY_SWORD_ATTACK_ANIMATION)


func _sync_body_attack_animation(direction: Vector2) -> void:
	if not _can_play_body_attack_animation():
		return
	body_visual.flip_h = direction.x < -0.08
	body_visual.speed_scale = _body_attack_playback_scale()
	if body_visual.animation != BODY_SWORD_ATTACK_ANIMATION:
		_start_body_attack_animation(direction)


func _can_play_body_attack_animation() -> bool:
	if body_visual == null or body_visual.sprite_frames == null:
		return false
	if not body_visual.sprite_frames.has_animation(BODY_SWORD_ATTACK_ANIMATION):
		return false
	return body_visual.sprite_frames.get_frame_count(BODY_SWORD_ATTACK_ANIMATION) > 0


func _body_attack_playback_scale() -> float:
	var attack_speed_scale: float = BODY_ATTACK_BASE_COOLDOWN / maxf(projectile_cooldown, 0.05)
	var phase_duration: float = maxf(_branch_windup_time + _branch_recovery_time, 0.05)
	var clip_duration: float = _body_attack_clip_duration()
	var phase_fit_scale: float = clip_duration / phase_duration
	return clampf(phase_fit_scale * attack_speed_scale, BODY_ATTACK_MIN_SPEED_SCALE, BODY_ATTACK_MAX_SPEED_SCALE)


func _body_attack_clip_duration() -> float:
	if not _can_play_body_attack_animation():
		return maxf(_branch_windup_time + _branch_recovery_time, 0.05)
	var frame_count: int = body_visual.sprite_frames.get_frame_count(BODY_SWORD_ATTACK_ANIMATION)
	var animation_speed: float = maxf(body_visual.sprite_frames.get_animation_speed(BODY_SWORD_ATTACK_ANIMATION), 1.0)
	return float(frame_count) / animation_speed


func _attack_point_local_position(direction: Vector2) -> Vector2:
	var resolved_direction: Vector2 = direction.normalized()
	if resolved_direction == Vector2.ZERO:
		resolved_direction = _last_move_direction
	if resolved_direction == Vector2.ZERO:
		resolved_direction = Vector2.RIGHT
	return ATTACHMENT_PIVOT_OFFSET + resolved_direction * _branch_muzzle_distance


func _attack_point_world_position(direction: Vector2) -> Vector2:
	return global_position + _attack_point_local_position(direction)


func _update_slash_hitbox_transform(direction: Vector2) -> void:
	var resolved_direction: Vector2 = direction.normalized()
	if resolved_direction == Vector2.ZERO:
		resolved_direction = _last_move_direction
	if resolved_direction == Vector2.ZERO:
		resolved_direction = Vector2.RIGHT
	var slash_circle := slash_hitbox_shape.shape as CircleShape2D
	if slash_circle != null:
		slash_circle.radius = maxf(_current_melee_reach() * 0.58, 24.0)
	slash_hitbox.position = ATTACHMENT_PIVOT_OFFSET + resolved_direction * maxf(_current_melee_reach() * 0.46, 16.0)
	slash_hitbox.rotation = resolved_direction.angle()


func _set_slash_hitbox_active(active: bool) -> void:
	if slash_hitbox == null or slash_hitbox_shape == null:
		return
	slash_hitbox.monitoring = active
	slash_hitbox.monitorable = active
	slash_hitbox_shape.set_deferred("disabled", not active)


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


func _normalize_sequence_dictionary(raw_sequences: Variant, fallback_frames: Dictionary) -> Dictionary:
	var sequences: Dictionary = {}
	if typeof(raw_sequences) == TYPE_DICTIONARY:
		for key in raw_sequences.keys():
			var textures := Array(raw_sequences[key])
			var filtered: Array[Texture2D] = []
			for raw_texture in textures:
				var texture: Texture2D = raw_texture as Texture2D
				if texture != null:
					filtered.append(texture)
			if not filtered.is_empty():
				sequences[String(key)] = filtered
	for fallback_key in fallback_frames.keys():
		var key: String = String(fallback_key)
		if sequences.has(key):
			continue
		var fallback_texture: Texture2D = fallback_frames[key] as Texture2D
		if fallback_texture != null:
			sequences[key] = [fallback_texture]
	if not sequences.has("release"):
		var fallback_flash: Texture2D = _branch_flash_frame("a")
		if fallback_flash != null:
			sequences["release"] = [fallback_flash]
	return sequences


func _sequence_frame(sequence_map: Dictionary, phase_key: String, progress: float, fallback: Texture2D) -> Texture2D:
	var raw_frames := Array(sequence_map.get(phase_key, []))
	if raw_frames.is_empty():
		return fallback
	var clamped_progress: float = clampf(progress, 0.0, 1.0)
	var frame_index := int(floor(clamped_progress * float(raw_frames.size())))
	frame_index = clampi(frame_index, 0, raw_frames.size() - 1)
	var texture: Texture2D = raw_frames[frame_index] as Texture2D
	if texture != null:
		return texture
	return fallback


func _trail_alpha_for_phase(phase_key: String, progress: float) -> float:
	match phase_key:
		"windup":
			return lerpf(0.18, 0.52, progress)
		"release":
			return lerpf(0.88, 0.56, progress)
		"recover":
			return lerpf(0.42, 0.0, progress)
		_:
			return 0.0


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
		return "震荡护环/%d射 + 反伤%.0f + 护盾%.0f" % [_branch_guard_shot_interval, _branch_reflect_damage, _branch_shield_max]
	if _branch_scorch_orb_shot_interval > 0:
		return "蚀火法球/%d射 + 咒蚀传播" % _branch_scorch_orb_shot_interval
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
	orb.global_position = _attack_point_world_position(direction)
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
	sentry.global_position = _attack_point_world_position(direction) + direction * 2.0
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
	if not force and _attack_phase != AttackPhase.IDLE:
		# 攻击期间 AnimatedSprite2D 由 sword_attack 播放控制，避免移动方向帧每帧打断动画。
		return
	var key: String = _direction_to_sprite_key(direction)
	if not force and key == _body_direction_key and body_visual.animation == key:
		return
	_body_direction_key = key
	_set_body_animation(key, 0, false)
