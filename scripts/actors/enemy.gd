extends CharacterBody2D
class_name Enemy

signal defeated(world_position: Vector2, experience_reward: int, enemy_id: String, was_elite: bool, was_boss: bool, status_snapshot: Dictionary)
signal projectile_spawned(projectile: Node2D)
signal boss_skill_triggered(skill_name: String, world_position: Vector2, phase: int)

const STATUS_CONFIGS := {
	"burn": {
		"tick_interval": 0.42,
		"initial_tick": 0.18,
		"default_stacks": 1,
		"default_max_stacks": 4
	},
	"poison": {
		"tick_interval": 0.5,
		"initial_tick": 0.22,
		"default_stacks": 1,
		"default_max_stacks": 4,
		"detonate_threshold": 4
	},
	"slow": {
		"tick_interval": 0.0,
		"initial_tick": 0.0,
		"default_stacks": 1,
		"default_max_stacks": 1
	},
	"vulnerable": {
		"tick_interval": 0.0,
		"initial_tick": 0.0,
		"default_stacks": 1,
		"default_max_stacks": 1
	},
	"curse": {
		"tick_interval": 0.72,
		"initial_tick": 0.26,
		"default_stacks": 1,
		"default_max_stacks": 4
	},
	"corrosion": {
		"tick_interval": 0.0,
		"initial_tick": 0.0,
		"default_stacks": 1,
		"default_max_stacks": 5
	},
	"control": {
		"tick_interval": 0.0,
		"initial_tick": 0.0,
		"default_stacks": 1,
		"default_max_stacks": 1
	}
}

const STATUS_VISUALS := {
	"burn": {"label": "燃", "color": Color(1.0, 0.52, 0.22, 1.0)},
	"poison": {"label": "毒", "color": Color(0.45, 0.95, 0.36, 1.0)},
	"slow": {"label": "缓", "color": Color(0.56, 0.82, 1.0, 1.0)},
	"vulnerable": {"label": "脆", "color": Color(1.0, 0.78, 0.34, 1.0)},
	"curse": {"label": "咒", "color": Color(0.72, 0.4, 1.0, 1.0)},
	"corrosion": {"label": "蚀", "color": Color(0.36, 1.0, 0.66, 1.0)},
	"control": {"label": "控", "color": Color(0.68, 0.92, 1.0, 1.0)}
}

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
var _statuses: Dictionary = {}
var _slow_multiplier := 1.0
var _status_label: Label
var _status_marker_root: Node2D
var _last_status_visual_signature := ""

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
	_statuses.clear()
	_slow_multiplier = 1.0
	_setup_runtime_stats()
	_apply_data()


func _physics_process(delta: float) -> void:
	if data == null or player == null or not is_instance_valid(player):
		return

	_handle_status_effects(delta)
	_update_status_visuals()
	if current_health <= 0.0:
		return

	var to_player := player.global_position - global_position
	var distance := to_player.length()
	var direction := Vector2.ZERO
	var controlled := _is_status_active("control")

	if controlled:
		direction = Vector2.ZERO
	elif is_boss:
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
	speed_multiplier *= _slow_multiplier
	if controlled:
		speed_multiplier = 0.0
	velocity = velocity.move_toward(direction * move_speed_runtime * speed_multiplier, move_speed_runtime * 8.0 * speed_multiplier * delta)
	move_and_slide()
	_handle_contact_damage(distance, delta)
	_handle_flash(delta)


func take_damage(amount: float, source_position: Vector2, knockback_force: float) -> void:
	_apply_damage(amount, source_position, knockback_force, true)


func apply_status_effect(status_type: String, duration: float, value: float, stacks: int = 1, max_stacks: int = -1) -> void:
	if not STATUS_CONFIGS.has(status_type):
		return
	# Boss 对硬控保留短抗性，避免异常流完全跳过首领技能循环。
	if status_type == "control" and is_boss:
		duration *= 0.35
	var config = STATUS_CONFIGS[status_type]
	var status: Dictionary = _get_status_entry(status_type)
	status["time_left"] = maxf(float(status.get("time_left", 0.0)), duration)
	status["value"] = _merged_status_value(status_type, float(status.get("value", 0.0)), value)
	status["tick_interval"] = float(config.get("tick_interval", 0.0))
	if float(status.get("tick_interval", 0.0)) > 0.0:
		var current_tick_left: float = float(status.get("tick_left", 0.0))
		var initial_tick: float = float(config.get("initial_tick", 0.0))
		status["tick_left"] = minf(current_tick_left, initial_tick) if current_tick_left > 0.0 else initial_tick
	var resolved_max_stacks: int = max_stacks
	if resolved_max_stacks <= 0:
		resolved_max_stacks = int(status.get("max_stacks", int(config.get("default_max_stacks", 1))))
	status["max_stacks"] = maxi(resolved_max_stacks, 1)
	var stack_delta: int = maxi(stacks, int(config.get("default_stacks", 1)))
	var current_stacks: int = int(status.get("stacks", 0))
	current_stacks = clampi(current_stacks + stack_delta, 1, int(status.get("max_stacks", 1)))
	status["stacks"] = current_stacks
	_statuses[status_type] = status
	_flash_left = maxf(_flash_left, 0.05)
	_debug_status_event("apply", "%s stacks=%d duration=%.2f value=%.2f" % [status_type, current_stacks, duration, value])


func has_status(status_type: String) -> bool:
	return _is_status_active(status_type)


func has_any_status_effect() -> bool:
	for status_type in _statuses.keys():
		if _is_status_active(String(status_type)):
			return true
	return false


func get_status_stack_count(status_type: String) -> int:
	if not _is_status_active(status_type):
		return 0
	var status: Dictionary = Dictionary(_statuses.get(status_type, {}))
	return int(status.get("stacks", 0))


func get_status_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	for raw_status_type in _statuses.keys():
		var status_type: String = String(raw_status_type)
		if not _is_status_active(status_type):
			continue
		snapshot[status_type] = Dictionary(_statuses.get(status_type, {})).duplicate(true)
	return snapshot


func get_total_status_layers() -> int:
	var total_layers := 0
	for raw_status_type in _statuses.keys():
		var status_type: String = String(raw_status_type)
		if not _is_status_active(status_type):
			continue
		var status: Dictionary = Dictionary(_statuses.get(status_type, {}))
		total_layers += maxi(int(status.get("stacks", 1)), 1)
	return total_layers


func _apply_damage(amount: float, source_position: Vector2, knockback_force: float, notify_feedback: bool) -> void:
	if current_health <= 0.0:
		return
	var resolved_damage: float = amount
	if _is_status_active("vulnerable"):
		var vulnerable: Dictionary = Dictionary(_statuses.get("vulnerable", {}))
		resolved_damage *= 1.0 + maxf(float(vulnerable.get("value", 0.0)), 0.0)
	if _is_status_active("corrosion"):
		var corrosion: Dictionary = Dictionary(_statuses.get("corrosion", {}))
		var corrosion_layers: int = maxi(int(corrosion.get("stacks", 1)), 1)
		resolved_damage *= 1.0 + maxf(float(corrosion.get("value", 0.0)), 0.0) * float(corrosion_layers)
	if notify_feedback and _is_status_active("curse"):
		var curse: Dictionary = Dictionary(_statuses.get("curse", {}))
		var curse_layers: int = maxi(int(curse.get("stacks", 1)), 1)
		# 诅咒是“标记兑现”：直接命中时追加暗蚀伤害，DOT 自身不会递归触发。
		resolved_damage += maxf(float(curse.get("value", 0.0)), 0.0) * float(curse_layers) * 0.45
	current_health -= resolved_damage
	_flash_left = 0.08
	velocity += (global_position - source_position).normalized() * knockback_force
	if notify_feedback:
		_notify_hit_feedback(current_health <= 0.0)
	if current_health <= 0.0:
		defeated.emit(global_position, experience_reward_runtime, enemy_id, is_elite, is_boss, get_status_snapshot())
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
	if _is_status_active("control") or distance > size_runtime + 18.0 or _contact_cooldown_left > 0.0:
		return
	_contact_cooldown_left = 0.9
	player.apply_contact_damage(touch_damage_runtime, global_position)


func _handle_status_effects(delta: float) -> void:
	_slow_multiplier = 1.0
	for raw_status_type in _statuses.keys():
		var status_type: String = String(raw_status_type)
		var status: Dictionary = Dictionary(_statuses.get(status_type, {}))
		var time_left: float = float(status.get("time_left", 0.0))
		if time_left <= 0.0:
			continue
		time_left = maxf(time_left - delta, 0.0)
		status["time_left"] = time_left
		if status_type == "slow":
			if time_left > 0.0:
				_slow_multiplier = minf(_slow_multiplier, clampf(float(status.get("value", 1.0)), 0.25, 1.0))
			else:
				status["stacks"] = 0
				status["value"] = 1.0
			_statuses[status_type] = status
			continue
		var tick_interval: float = float(status.get("tick_interval", 0.0))
		if tick_interval > 0.0 and time_left > 0.0:
			var tick_left: float = maxf(float(status.get("tick_left", tick_interval)) - delta, 0.0)
			status["tick_left"] = tick_left
			if tick_left <= 0.0:
				status["tick_left"] = tick_interval
				status = _apply_status_tick(status_type, status)
		if time_left <= 0.0:
			status["stacks"] = 0
		_statuses[status_type] = status


func _apply_status_tick(status_type: String, status: Dictionary) -> Dictionary:
	match status_type:
		"burn":
			var burn_stacks: int = maxi(int(status.get("stacks", 1)), 1)
			var burn_damage: float = float(status.get("value", 0.0)) * (1.0 + float(burn_stacks - 1) * 0.18)
			_apply_damage(burn_damage, global_position, 0.0, false)
			_debug_status_event("tick", "burn damage=%.2f stacks=%d" % [burn_damage, burn_stacks])
		"poison":
			var poison_stacks: int = maxi(int(status.get("stacks", 1)), 1)
			var poison_damage: float = float(status.get("value", 0.0)) * (1.0 + float(poison_stacks - 1) * 0.45)
			_apply_damage(poison_damage, global_position, 0.0, false)
			_debug_status_event("tick", "poison damage=%.2f stacks=%d" % [poison_damage, poison_stacks])
			var detonate_threshold: int = int(status.get("detonate_threshold", STATUS_CONFIGS["poison"]["detonate_threshold"]))
			if poison_stacks >= detonate_threshold:
				var detonation_damage: float = float(status.get("value", 0.0)) * (0.85 + float(poison_stacks) * 0.25)
				_apply_damage(detonation_damage, global_position, 0.0, false)
				status["stacks"] = maxi(poison_stacks - 2, 1)
				_debug_status_event("detonate", "poison bonus=%.2f remaining_stacks=%d" % [detonation_damage, int(status.get("stacks", 1))])
		"curse":
			var curse_stacks: int = maxi(int(status.get("stacks", 1)), 1)
			var curse_damage: float = float(status.get("value", 0.0)) * (0.85 + float(curse_stacks - 1) * 0.32)
			if _is_status_active("control") or _is_status_active("corrosion"):
				curse_damage *= 1.28
			_apply_damage(curse_damage, global_position, 0.0, false)
			_debug_status_event("tick", "curse damage=%.2f stacks=%d" % [curse_damage, curse_stacks])
	return status


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
	_ensure_status_visual_nodes()
	_update_status_visuals()


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
	var path: String = "res://art/sprites/enemy_slime.png"
	match enemy_id:
		"slime":
			path = "res://art/sprites/enemy_slime.png"
		"bat":
			path = "res://art/sprites/enemy_bat.png"
		"skeleton":
			path = "res://art/sprites/enemy_skeleton.png"
		"goblin":
			path = "res://art/sprites/enemy_goblin.png"
		"mushroom":
			path = "res://art/sprites/enemy_mushroom.png"
		"ghost":
			path = "res://art/sprites/enemy_ghost.png"
		"imp":
			path = "res://art/sprites/enemy_imp.png"
		"demon":
			path = "res://art/sprites/enemy_demon.png"
		"boss":
			path = "res://art/sprites/enemy_boss.png"
	if is_elite and not is_boss:
		path = "res://art/sprites/enemy_elite.png"
	return load(path) as Texture2D


func _get_display_color() -> Color:
	if _is_status_active("control"):
		return Color(0.68, 0.92, 1.0, 1.0)
	if _is_status_active("curse"):
		return Color(0.76, 0.52, 1.0, 1.0)
	if _is_status_active("corrosion"):
		return Color(0.44, 1.0, 0.72, 1.0)
	if _is_status_active("poison"):
		return Color(0.58, 0.96, 0.52, 1.0)
	if _is_status_active("burn"):
		return Color(1.0, 0.7, 0.52, 1.0)
	if _is_status_active("vulnerable"):
		return Color(1.0, 0.82, 0.48, 1.0)
	if _is_status_active("slow"):
		return Color(0.72, 0.88, 1.0, 1.0)
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


func _get_status_entry(status_type: String) -> Dictionary:
	var status: Dictionary = Dictionary(_statuses.get(status_type, {}))
	if status.is_empty():
		var config = STATUS_CONFIGS[status_type]
		status = {
			"time_left": 0.0,
			"tick_left": float(config.get("initial_tick", 0.0)),
			"tick_interval": float(config.get("tick_interval", 0.0)),
			"value": 0.0,
			"stacks": 0,
			"max_stacks": int(config.get("default_max_stacks", 1))
		}
		if status_type == "poison":
			status["detonate_threshold"] = int(config.get("detonate_threshold", 4))
	return status


func _ensure_status_visual_nodes() -> void:
	if _status_label == null:
		_status_label = Label.new()
		_status_label.name = "StatusLabel"
		_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_status_label.add_theme_font_size_override("font_size", 10)
		_status_label.position = Vector2(-36.0, -size_runtime - 30.0)
		_status_label.size = Vector2(72.0, 14.0)
		_status_label.z_index = 20
		add_child(_status_label)
	if _status_marker_root == null:
		_status_marker_root = Node2D.new()
		_status_marker_root.name = "StatusMarkers"
		_status_marker_root.position = Vector2.ZERO
		_status_marker_root.z_index = 19
		add_child(_status_marker_root)


func _update_status_visuals() -> void:
	_ensure_status_visual_nodes()
	var active_parts: Array[String] = []
	for raw_status_type in STATUS_VISUALS.keys():
		var status_type: String = String(raw_status_type)
		if not _is_status_active(status_type):
			continue
		var status: Dictionary = Dictionary(_statuses.get(status_type, {}))
		var visual: Dictionary = Dictionary(STATUS_VISUALS[status_type])
		var stacks: int = maxi(int(status.get("stacks", 1)), 1)
		var label: String = String(visual.get("label", status_type))
		active_parts.append("%s%d" % [label, stacks] if stacks > 1 else label)
	_status_label.text = " ".join(active_parts)
	_status_label.visible = not active_parts.is_empty()
	_status_label.position = Vector2(-36.0, -size_runtime - 30.0)
	var next_signature := "|".join(active_parts)
	if next_signature == _last_status_visual_signature:
		return
	_last_status_visual_signature = next_signature
	_redraw_status_markers(active_parts.size())


func _redraw_status_markers(active_count: int) -> void:
	for child in _status_marker_root.get_children():
		child.queue_free()
	if active_count <= 0:
		return
	var marker_index := 0
	for raw_status_type in STATUS_VISUALS.keys():
		var status_type: String = String(raw_status_type)
		if not _is_status_active(status_type):
			continue
		var visual: Dictionary = Dictionary(STATUS_VISUALS[status_type])
		var marker := ColorRect.new()
		var marker_color := Color.WHITE
		var raw_marker_color: Variant = visual.get("color", Color.WHITE)
		if raw_marker_color is Color:
			marker_color = raw_marker_color
		marker.color = marker_color
		marker.size = Vector2(6.0, 3.0)
		marker.position = Vector2(float(marker_index) * 8.0 - float(active_count - 1) * 4.0 - 3.0, -size_runtime - 12.0)
		_status_marker_root.add_child(marker)
		marker_index += 1


func _is_status_active(status_type: String) -> bool:
	if not _statuses.has(status_type):
		return false
	var status: Dictionary = Dictionary(_statuses.get(status_type, {}))
	return float(status.get("time_left", 0.0)) > 0.0 and int(status.get("stacks", 0)) > 0


func _merged_status_value(status_type: String, current_value: float, next_value: float) -> float:
	match status_type:
		"slow":
			return minf(current_value, next_value) if current_value > 0.0 else next_value
		_:
			return maxf(current_value, next_value)


func _debug_status_event(event_name: String, detail: String) -> void:
	print_verbose("[status][%s][%s] %s" % [enemy_id, event_name, detail])
