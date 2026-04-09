extends Node2D
class_name GameManager

const BOSS_SPAWN_TIME := 390.0
const ENEMY_SCENE := preload("res://scenes/enemies/enemy.tscn")
const EXPERIENCE_SCENE := preload("res://scenes/props/experience_orb.tscn")
const CONTENT_CATALOG := preload("res://scripts/data/content_catalog.gd")
const BRANCH_CATALOG := preload("res://scripts/data/branch_catalog.gd")
const SPECIAL_CARD_SCENE := preload("res://scenes/props/special_card_pickup.tscn")
const SPECIAL_CARD_CATALOG := preload("res://scripts/data/special_card_catalog.gd")

const STAGE_CONFIGS := [
	{
		"name": "冷街",
		"start": 0.0,
		"spawn_rate": 0.95,
		"pack_min": 1,
		"pack_max": 1,
		"weights": {"runner": 1.0},
		"message": "冷街苏醒，先建立基础节奏"
	},
	{
		"name": "围压",
		"start": 70.0,
		"spawn_rate": 1.2,
		"pack_min": 1,
		"pack_max": 2,
		"weights": {"runner": 1.0, "brute": 0.55},
		"message": "肉盾开始封路，注意走位空间"
	},
	{
		"name": "火线",
		"start": 150.0,
		"spawn_rate": 1.7,
		"pack_min": 2,
		"pack_max": 2,
		"weights": {"runner": 0.95, "brute": 0.7, "shooter": 0.4},
		"message": "远程火力加入，敌人开始混编"
	},
	{
		"name": "崩压",
		"start": 250.0,
		"spawn_rate": 2.25,
		"pack_min": 2,
		"pack_max": 3,
		"weights": {"runner": 1.15, "brute": 0.85, "shooter": 0.8},
		"message": "敌群密度提高，精英会更频繁出现"
	},
	{
		"name": "终幕",
		"start": 340.0,
		"spawn_rate": 2.8,
		"pack_min": 3,
		"pack_max": 3,
		"weights": {"runner": 1.3, "brute": 1.0, "shooter": 1.0},
		"message": "终幕逼近，准备迎接首领"
	}
]

var enemy_definitions: Array[EnemyData] = []
var enemy_by_id: Dictionary = {}
var upgrade_definitions: Array[UpgradeData] = []
var current_upgrade_options: Array[UpgradeData] = []
var current_special_card_options: Array[Dictionary] = []
var upgrade_levels: Dictionary = {}
var meta_progression: MetaProgression
var selected_special_cards: Array[String] = []
var current_branch_options: Array[Dictionary] = []
var selected_branch_id := ""
var selected_branch_name := ""

var elapsed_time := 0.0
var kills := 0
var current_experience := 0.0
var experience_to_next := 18.0
var level := 1
var pending_level_ups := 0
var spawn_budget := 0.0
var shard_gain_this_run := 0
var next_card_event_index := 0
var run_seed := 0

var manual_pause := false
var branch_selection_active := false
var level_up_active := false
var special_card_active := false
var run_finished := false
var current_stage_index := -1
var elite_timer := 90.0
var wave_timer := 24.0
var boss_spawned := false
var boss_defeated := false
var active_boss: Enemy
var card_rng := RandomNumberGenerator.new()
var card_event_times: Array[float] = [95.0, 205.0, 320.0]

@onready var arena: Node2D = $Arena
@onready var player: Player = $Player
@onready var enemies_layer: Node2D = $Enemies
@onready var projectiles_layer: Node2D = $Projectiles
@onready var drops_layer: Node2D = $Drops
@onready var cards_layer: Node2D = $Cards
@onready var effects_layer: Node2D = $Effects
@onready var audio_manager: AudioManager = $AudioManager
@onready var hud: HUD = $UI/HUD
@onready var branch_select_panel: BranchSelectPanel = $UI/BranchSelectPanel
@onready var level_up_panel: LevelUpPanel = $UI/LevelUpPanel
@onready var result_panel: ResultPanel = $UI/ResultPanel
@onready var special_card_panel: SpecialCardPanel = $UI/SpecialCardPanel


func _ready() -> void:
	randomize()
	process_mode = Node.PROCESS_MODE_ALWAYS
	run_seed = int(Time.get_unix_time_from_system()) ^ randi()
	card_rng.seed = run_seed
	_ensure_input_map()
	add_to_group("game")
	meta_progression = MetaProgression.load_or_create()
	_load_definitions()
	_connect_signals()
	meta_progression.apply_to_player(player)
	player.sync_upgrade_levels(upgrade_levels)
	hud.configure_boss_goal(BOSS_SPAWN_TIME)
	_update_stage(true)
	_refresh_hud()
	hud.set_build_text(_compose_build_summary())
	hud.set_pause_state(false)
	_present_branch_selection()


func _process(delta: float) -> void:
	if manual_pause or branch_selection_active or level_up_active or special_card_active or run_finished:
		return

	elapsed_time += delta
	hud.set_elapsed_time(elapsed_time)
	_update_stage(false)
	_update_boss_hud()

	if not boss_spawned and elapsed_time >= BOSS_SPAWN_TIME:
		_spawn_boss()
	if boss_spawned:
		return

	_update_special_card_event()
	spawn_budget += delta * _current_spawn_rate()
	while spawn_budget >= 1.0:
		spawn_budget -= 1.0
		_spawn_enemy_pack()

	if elapsed_time >= 120.0:
		elite_timer -= delta
		if elite_timer <= 0.0:
			_spawn_elite()
			elite_timer = maxf(42.0, 78.0 - float(current_stage_index) * 7.0)

	if elapsed_time >= 60.0:
		wave_timer -= delta
		if wave_timer <= 0.0:
			_spawn_wave_event()
			wave_timer = maxf(15.0, 28.0 - float(current_stage_index) * 3.5)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game") and not run_finished and not branch_selection_active and not level_up_active and not special_card_active:
		_toggle_manual_pause()
	elif event.is_action_pressed("restart_run") and run_finished:
		_restart_run()


func _connect_signals() -> void:
	player.projectile_spawned.connect(_on_projectile_spawned)
	player.effect_spawned.connect(_on_effect_spawned)
	player.health_changed.connect(_on_player_health_changed)
	player.shot_fired.connect(_on_player_shot_fired)
	player.died.connect(_on_player_died)
	branch_select_panel.branch_selected.connect(_on_branch_selected)
	level_up_panel.option_selected.connect(_on_upgrade_selected)
	result_panel.restart_requested.connect(_restart_run)
	result_panel.meta_upgrade_requested.connect(_on_meta_upgrade_requested)
	special_card_panel.card_selected.connect(_on_special_card_selected)


func _present_branch_selection() -> void:
	current_branch_options = BRANCH_CATALOG.get_branch_definitions()
	branch_selection_active = true
	hud.set_objective_text("目标：先选择本局主分支")
	hud.show_event("选择一个主分支，决定本局成长倾向和武器风格", 2.4)
	_set_modal_pause(true)
	branch_select_panel.present(current_branch_options)


func _on_branch_selected(index: int) -> void:
	if index < 0 or index >= current_branch_options.size():
		return
	var branch: Dictionary = current_branch_options[index]
	selected_branch_id = String(branch.get("id", ""))
	selected_branch_name = String(branch.get("name", ""))
	player.set_branch_definition(branch)
	player.sync_upgrade_levels(upgrade_levels)
	current_branch_options.clear()
	branch_selection_active = false
	branch_select_panel.hide_panel()
	_set_modal_pause(false)
	hud.configure_boss_goal(BOSS_SPAWN_TIME)
	hud.set_build_text(_compose_build_summary())
	hud.show_event("已接入主分支：%s" % selected_branch_name, 2.0)


func _ensure_input_map() -> void:
	_register_action("move_left", [KEY_A, KEY_LEFT])
	_register_action("move_right", [KEY_D, KEY_RIGHT])
	_register_action("move_up", [KEY_W, KEY_UP])
	_register_action("move_down", [KEY_S, KEY_DOWN])
	_register_action("pause_game", [KEY_ESCAPE, KEY_P])
	_register_action("restart_run", [KEY_R])


func _register_action(action_name: String, keycodes: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	var existing_events: Array[InputEvent] = InputMap.action_get_events(action_name)
	for keycode in keycodes:
		var already_added := false
		for event in existing_events:
			if event is InputEventKey and (event.physical_keycode == keycode or event.keycode == keycode):
				already_added = true
				break
		if already_added:
			continue
		var key_event := InputEventKey.new()
		key_event.physical_keycode = keycode
		key_event.keycode = keycode
		InputMap.action_add_event(action_name, key_event)


func _load_definitions() -> void:
	enemy_definitions.clear()
	enemy_by_id.clear()
	for definition in CONTENT_CATALOG.get_enemy_definitions():
		enemy_definitions.append(definition)
		enemy_by_id[definition.enemy_id] = definition

	upgrade_definitions.clear()
	for definition in CONTENT_CATALOG.get_upgrade_definitions():
		upgrade_definitions.append(definition)


func _current_stage_config() -> Dictionary:
	return STAGE_CONFIGS[current_stage_index]


func _update_stage(force: bool) -> void:
	var new_stage_index := 0
	for index in range(STAGE_CONFIGS.size()):
		if elapsed_time >= float(STAGE_CONFIGS[index]["start"]):
			new_stage_index = index

	if not force and new_stage_index == current_stage_index:
		return

	current_stage_index = new_stage_index
	var stage: Dictionary = _current_stage_config()
	hud.set_stage_text(current_stage_index + 1, String(stage["name"]))
	hud.show_event("阶段 %d - %s\n%s" % [
		current_stage_index + 1,
		String(stage["name"]),
		String(stage["message"])
	], 2.6)


func _current_spawn_rate() -> float:
	var stage: Dictionary = _current_stage_config()
	return float(stage["spawn_rate"])


func _spawn_enemy_pack() -> void:
	var stage: Dictionary = _current_stage_config()
	var pack_min: int = int(stage["pack_min"])
	var pack_max: int = int(stage["pack_max"])
	var pack_size: int = randi_range(pack_min, pack_max)
	if active_boss != null and is_instance_valid(active_boss):
		pack_size = maxi(1, pack_size - 1)

	for _i in range(pack_size):
		var enemy_id: String = _pick_enemy_id(stage["weights"])
		if enemy_id.is_empty():
			continue
		_spawn_enemy_by_id(enemy_id, false, _pick_spawn_position())


func _pick_enemy_id(weights: Dictionary) -> String:
	var total_weight := 0.0
	for enemy_id in weights.keys():
		total_weight += float(weights[enemy_id])
	if total_weight <= 0.0:
		return ""

	var roll: float = randf() * total_weight
	var cumulative := 0.0
	for enemy_id in weights.keys():
		cumulative += float(weights[enemy_id])
		if roll <= cumulative:
			return String(enemy_id)
	return String(weights.keys()[0])


func _spawn_enemy_by_id(enemy_id: String, elite: bool, spawn_position: Vector2) -> Enemy:
	var definition: EnemyData = enemy_by_id.get(enemy_id) as EnemyData
	if definition == null:
		return null

	var enemy: Enemy = ENEMY_SCENE.instantiate() as Enemy
	enemies_layer.add_child(enemy)
	enemy.global_position = spawn_position
	enemy.setup(definition, player, elite)
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.projectile_spawned.connect(_on_projectile_spawned)
	enemy.boss_skill_triggered.connect(_on_boss_skill_triggered)
	return enemy


func _spawn_elite() -> void:
	var stage: Dictionary = _current_stage_config()
	var elite_pool: Array[String] = ["runner", "brute"]
	if current_stage_index >= 2:
		elite_pool.append("shooter")

	var picked_id: String = elite_pool[randi() % elite_pool.size()]
	var enemy := _spawn_enemy_by_id(picked_id, true, _pick_spawn_position())
	if enemy == null:
		return
	hud.show_event("精英出现：%s" % String(enemy.data.display_name), 1.8)
	audio_manager.play_sfx("elite_spawn", 1.0, -1.5)
	_spawn_burst(enemy.global_position, Color(1.0, 0.78, 0.36, 1.0), 5.0, 16, 0.45, 120.0)


func _spawn_wave_event() -> void:
	var base_angle: float = randf() * TAU
	match current_stage_index:
		0:
			for offset in [-0.18, 0.0, 0.18]:
				_spawn_enemy_by_id("runner", false, _pick_spawn_position_from_angle(base_angle + offset, 640.0))
		1:
			for offset in [-0.22, 0.22]:
				_spawn_enemy_by_id("brute", false, _pick_spawn_position_from_angle(base_angle + offset, 620.0))
			for offset in [-0.3, 0.0, 0.3]:
				_spawn_enemy_by_id("runner", false, _pick_spawn_position_from_angle(base_angle + PI + offset, 560.0))
		_:
			for offset in [-0.24, 0.0, 0.24]:
				_spawn_enemy_by_id("shooter", false, _pick_spawn_position_from_angle(base_angle + offset, 600.0))
			for offset in [-0.34, -0.12, 0.12, 0.34]:
				_spawn_enemy_by_id("runner", false, _pick_spawn_position_from_angle(base_angle + PI + offset, 560.0))


func _spawn_boss() -> void:
	_clear_special_card_pickups()
	var boss_position := _pick_spawn_position_from_angle(randf() * TAU, 620.0)
	active_boss = _spawn_enemy_by_id("boss", false, boss_position)
	if active_boss == null:
		return
	boss_spawned = true
	hud.set_boss_objective_active(true, "目标：击败余烬监工")
	hud.show_event("首领降临：余烬监工", 3.0)
	audio_manager.play_sfx("boss_spawn", 1.0, -0.5)
	if arena.has_method("set_boss_mode"):
		arena.set_boss_mode(true, 1)
	_spawn_burst(active_boss.global_position, Color(0.8, 0.24, 0.32, 1.0), 7.0, 26, 0.65, 150.0)


func _pick_spawn_position() -> Vector2:
	return _pick_spawn_position_from_angle(randf() * TAU, randf_range(380.0, 620.0))


func _pick_spawn_position_from_angle(angle: float, distance: float) -> Vector2:
	var raw_position: Vector2 = player.global_position + Vector2.RIGHT.rotated(angle) * distance
	return Vector2(
		clampf(raw_position.x, -1540.0, 1540.0),
		clampf(raw_position.y, -1540.0, 1540.0)
	)


func _update_boss_hud() -> void:
	if active_boss != null and is_instance_valid(active_boss):
		hud.show_boss("余烬监工", active_boss.current_health, active_boss.max_health_runtime)
	else:
		hud.hide_boss()


func _on_projectile_spawned(projectile: Node2D) -> void:
	projectiles_layer.add_child(projectile)


func _on_effect_spawned(effect: Node2D) -> void:
	effects_layer.add_child(effect)


func _on_player_health_changed(current_health: float, max_health: float) -> void:
	hud.set_health(current_health, max_health)


func _on_player_shot_fired(weapon_name: String) -> void:
	if weapon_name == "pulse":
		audio_manager.play_sfx("shoot", 0.72, -3.0)
		_spawn_burst(player.global_position, Color(0.43, 0.86, 1.0, 1.0), 4.0, 10, 0.24, 90.0)
	else:
		audio_manager.play_sfx("shoot", randf_range(0.92, 1.08), -6.0)


func _on_player_died() -> void:
	projectiles_layer.process_mode = Node.PROCESS_MODE_DISABLED
	_finish_run(false)


func _on_enemy_defeated(world_position: Vector2, experience_reward: int, enemy_id: String, was_elite: bool, was_boss: bool) -> void:
	kills += 1
	hud.set_kills(kills)

	if was_boss:
		active_boss = null
		boss_defeated = true
		hud.show_event("首领被击溃，战区已经稳定", 2.6)
		hud.set_boss_objective_active(false, "目标：已完成")
		if arena.has_method("set_boss_mode"):
			arena.set_boss_mode(false, 0)
		_finish_run(true)
		return
	elif was_elite:
		hud.show_event("精英已击杀，获得额外回旋空间", 1.4)

	var orb_count := 1
	if was_elite:
		orb_count = 3
	if was_boss:
		orb_count = 8

	for index in range(orb_count):
		var orb: ExperienceOrb = EXPERIENCE_SCENE.instantiate() as ExperienceOrb
		drops_layer.add_child(orb)
		orb.global_position = world_position + Vector2(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0)) * float(index)
		orb.setup(int(experience_reward / orb_count), player)
		orb.collected.connect(_on_experience_collected)


func _on_experience_collected(amount: int) -> void:
	if run_finished:
		return
	current_experience += amount
	audio_manager.play_sfx("pickup", randf_range(0.96, 1.08), -9.0)
	while current_experience >= experience_to_next:
		current_experience -= experience_to_next
		level += 1
		pending_level_ups += 1
		experience_to_next = floorf(experience_to_next * 1.22 + 7.0)
	_refresh_hud()
	if pending_level_ups > 0 and not level_up_active:
		_present_level_up()


func _present_level_up() -> void:
	current_upgrade_options = _pick_upgrade_options(3)
	if current_upgrade_options.is_empty():
		pending_level_ups = 0
		return

	level_up_active = true
	_set_modal_pause(true)
	audio_manager.play_sfx("level_up", 1.0, -1.5)
	level_up_panel.present(current_upgrade_options, upgrade_levels, selected_branch_name)


func _pick_upgrade_options(count: int) -> Array[UpgradeData]:
	var candidates: Array[UpgradeData] = []
	var forced_upgrade: UpgradeData
	for definition in upgrade_definitions:
		if definition.upgrade_id.begins_with("pulse_") and definition.upgrade_id != "pulse_emitter" and not player.pulse_enabled:
			continue
		var current_level: int = int(upgrade_levels.get(definition.upgrade_id, 0))
		if current_level >= definition.max_level:
			continue
		if not player.pulse_enabled and level >= 4 and definition.upgrade_id == "pulse_emitter" and current_level == 0:
			forced_upgrade = definition
			continue
		candidates.append(definition)

	var selected: Array[UpgradeData] = []
	if forced_upgrade != null:
		selected.append(forced_upgrade)

	while selected.size() < count and not candidates.is_empty():
		var primary_pick: bool = selected.size() < count - 1
		var total_weight := 0.0
		for candidate in candidates:
			total_weight += _upgrade_candidate_weight(candidate, primary_pick)
		var roll: float = randf() * total_weight
		var cumulative := 0.0
		var chosen_index := 0
		for index in range(candidates.size()):
			cumulative += _upgrade_candidate_weight(candidates[index], primary_pick)
			if roll <= cumulative:
				chosen_index = index
				break
		selected.append(candidates[chosen_index])
		candidates.remove_at(chosen_index)
	return selected


func _on_upgrade_selected(index: int) -> void:
	if index < 0 or index >= current_upgrade_options.size():
		return

	var upgrade: UpgradeData = current_upgrade_options[index]
	upgrade_levels[upgrade.upgrade_id] = int(upgrade_levels.get(upgrade.upgrade_id, 0)) + 1
	player.apply_upgrade(upgrade)
	player.sync_upgrade_levels(upgrade_levels)
	hud.set_build_text(_compose_build_summary())
	_refresh_hud()
	pending_level_ups = maxi(pending_level_ups - 1, 0)
	level_up_panel.hide_panel()

	if pending_level_ups > 0:
		current_upgrade_options.clear()
		_present_level_up()
		return

	level_up_active = false
	_set_modal_pause(false)


func _finish_run(victory: bool) -> void:
	if run_finished:
		return

	run_finished = true
	manual_pause = false
	branch_selection_active = false
	level_up_active = false
	special_card_active = false
	branch_select_panel.hide_panel()
	level_up_panel.hide_panel()
	special_card_panel.hide_panel()
	hud.set_pause_state(false)
	hud.hide_boss()
	get_tree().paused = true

	shard_gain_this_run = _calculate_shard_gain(victory)
	meta_progression.shards += shard_gain_this_run
	meta_progression.save()

	if victory:
		audio_manager.play_sfx("victory", 1.0, -0.5)
	else:
		audio_manager.play_sfx("defeat", 1.0, -0.5)

	var title := "战斗结束"
	if victory:
		title = "生存成功"

	var summary := "存活 %s\n等级 %d\n击败 %d\n首领状态 %s\n最终构筑: %s" % [
		_format_time(elapsed_time),
		level,
		kills,
		"已击败" if boss_defeated else ("已现身" if boss_spawned else "未出现"),
		_compose_build_summary()
	]
	_refresh_result_panel(title, summary)


func _refresh_result_panel(title: String, summary: String) -> void:
	result_panel.show_result(
		title,
		summary,
		meta_progression.shards,
		shard_gain_this_run,
		meta_progression.build_upgrade_view_models()
	)


func _calculate_shard_gain(victory: bool) -> int:
	var gain := int(kills / 12) + level * 2 + int(elapsed_time / 60.0) * 3
	if boss_defeated:
		gain += 18
	elif boss_spawned:
		gain += 8
	if victory:
		gain += 24
	var shard_bonus_rate: float = meta_progression.get_total_effect_value("shard_bonus_rate")
	if shard_bonus_rate > 0.0:
		gain = int(round(float(gain) * (1.0 + shard_bonus_rate)))
	return maxi(gain, 6)


func _on_meta_upgrade_requested(upgrade_id: String) -> void:
	if not run_finished:
		return
	if not meta_progression.purchase(upgrade_id):
		return
	audio_manager.play_sfx("level_up", 0.9, -4.0)
	_refresh_result_panel(result_panel.title_label.text, result_panel.summary_label.text)


func _toggle_manual_pause() -> void:
	manual_pause = not manual_pause
	get_tree().paused = manual_pause
	hud.set_pause_state(manual_pause)


func _restart_run() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _refresh_hud() -> void:
	hud.set_health(player.current_health, player.max_health)
	hud.set_experience(current_experience, experience_to_next, level)
	hud.set_elapsed_time(elapsed_time)
	hud.set_kills(kills)


func _compose_build_summary() -> String:
	var summary: String = player.get_build_summary()
	if not selected_special_cards.is_empty():
		summary += " | 卡牌 " + " / ".join(selected_special_cards)
	return summary


func _format_time(seconds: float) -> String:
	var total_seconds: int = int(seconds)
	var minutes: int = total_seconds / 60
	var remainder: int = total_seconds % 60
	return "%02d:%02d" % [minutes, remainder]


func _upgrade_candidate_weight(candidate: UpgradeData, primary_pick: bool = true) -> float:
	var weight: float = candidate.rarity_weight
	match candidate.upgrade_id:
		"rapid_fire":
			if int(upgrade_levels.get("power_shot", 0)) > 0:
				weight *= 1.35
		"power_shot":
			if int(upgrade_levels.get("rapid_fire", 0)) > 0:
				weight *= 1.35
		"split_round":
			if int(upgrade_levels.get("piercing_round", 0)) > 0:
				weight *= 1.4
		"piercing_round":
			if int(upgrade_levels.get("split_round", 0)) > 0:
				weight *= 1.45
		"pulse_emitter":
			if level >= 4:
				weight *= 1.2
		"pulse_core":
			if player.pulse_enabled or int(upgrade_levels.get("pulse_emitter", 0)) > 0:
				weight *= 1.28
			if int(upgrade_levels.get("pulse_drive", 0)) > 0:
				weight *= 1.18
		"pulse_drive":
			if player.pulse_enabled or int(upgrade_levels.get("pulse_emitter", 0)) > 0:
				weight *= 1.24
			if int(upgrade_levels.get("pulse_core", 0)) > 0:
				weight *= 1.22
	weight *= BRANCH_CATALOG.get_branch_weight_multiplier(candidate, selected_branch_id, primary_pick)
	return weight


func on_enemy_hit(world_position: Vector2, enemy_id: String, was_elite: bool, was_boss: bool, died_now: bool) -> void:
	var color := Color(0.95, 0.3, 0.28, 1.0)
	if enemy_id == "shooter":
		color = Color(0.44, 0.78, 0.97, 1.0)
	elif enemy_id == "brute":
		color = Color(0.9, 0.66, 0.32, 1.0)
	elif was_elite:
		color = Color(1.0, 0.86, 0.45, 1.0)
	elif was_boss:
		color = Color(0.92, 0.34, 0.36, 1.0)

	if died_now:
		audio_manager.play_sfx("enemy_die", randf_range(0.92, 1.04), -3.0)
		_spawn_burst(world_position, color, 5.0 if not was_boss else 7.0, 16 if not was_boss else 24, 0.34, 130.0)
	else:
		audio_manager.play_sfx("hit", randf_range(0.96, 1.08), -7.0)
		_spawn_burst(world_position, color, 3.0, 8, 0.18, 84.0)


func on_player_feedback(feedback_name: String, world_position: Vector2) -> void:
	if feedback_name == "hurt":
		audio_manager.play_sfx("hurt", randf_range(0.94, 1.02), -4.0)
		_spawn_burst(world_position, Color(0.8, 0.2, 0.24, 1.0), 4.0, 10, 0.22, 95.0)


func _on_boss_skill_triggered(skill_name: String, world_position: Vector2, phase: int) -> void:
	match skill_name:
		"phase_shift":
			hud.show_event("余烬监工进入二阶段，弹幕和压迫都会升级", 2.6)
			hud.set_boss_objective_active(true, "目标：撑住二阶段并击溃首领")
			audio_manager.play_sfx("boss_spawn", 1.08, -1.0)
			if arena.has_method("set_boss_mode"):
				arena.set_boss_mode(true, phase)
			_spawn_burst(world_position, Color(0.95, 0.38, 0.32, 1.0), 8.0, 30, 0.72, 180.0)
		"ember_burst":
			hud.show_event("首领技能：扇形弹幕", 1.1)
			audio_manager.play_sfx("shoot", 0.88, -2.0)
		"ember_charge":
			hud.show_event("首领技能：灼火突进", 1.1)
			audio_manager.play_sfx("hurt", 1.08, -5.0)
			_spawn_burst(world_position, Color(0.92, 0.28, 0.24, 1.0), 5.0, 12, 0.28, 96.0)
		"ring_burst":
			hud.show_event("首领技能：余烬环爆", 1.2)
			audio_manager.play_sfx("boss_spawn", 1.12, -3.0)
			_spawn_burst(world_position, Color(0.98, 0.42, 0.33, 1.0), 6.0, 18, 0.36, 124.0)
		"summon_guards":
			hud.show_event("首领技能：召集护卫", 1.2)
			audio_manager.play_sfx("elite_spawn", 0.94, -2.0)
			_spawn_burst(world_position, Color(0.86, 0.62, 0.24, 1.0), 5.5, 16, 0.34, 120.0)
			_spawn_boss_support_wave(phase, world_position)


func _update_special_card_event() -> void:
	if next_card_event_index >= card_event_times.size():
		return
	if special_card_active or cards_layer.get_child_count() > 0:
		return
	if elapsed_time < card_event_times[next_card_event_index]:
		return
	next_card_event_index += 1
	_spawn_special_card_pickup()


func _spawn_special_card_pickup() -> void:
	var pickup: SpecialCardPickup = SPECIAL_CARD_SCENE.instantiate() as SpecialCardPickup
	cards_layer.add_child(pickup)
	pickup.global_position = _pick_card_spawn_position()
	pickup.picked_up.connect(_on_special_card_pickup)
	hud.show_event("检测到特殊技能卡，靠近后可触发一次额外抉择", 2.0)


func _pick_card_spawn_position() -> Vector2:
	var angle: float = card_rng.randf_range(0.0, TAU)
	var distance: float = card_rng.randf_range(160.0, 260.0)
	var raw_position: Vector2 = player.global_position + Vector2.RIGHT.rotated(angle) * distance
	return Vector2(
		clampf(raw_position.x, -1460.0, 1460.0),
		clampf(raw_position.y, -1460.0, 1460.0)
	)


func _on_special_card_pickup(pickup: SpecialCardPickup) -> void:
	if pickup != null and is_instance_valid(pickup):
		pickup.queue_free()
	current_special_card_options = _pick_special_card_offers(3)
	if current_special_card_options.is_empty():
		return
	special_card_active = true
	_set_modal_pause(true)
	hud.show_event("特殊技能卡启动，选择一张改变本局节奏", 1.8)
	special_card_panel.present(current_special_card_options, "选择一张技能卡。高收益卡通常伴随代价。")


func _pick_special_card_offers(count: int) -> Array[Dictionary]:
	var definitions: Array[Dictionary] = SPECIAL_CARD_CATALOG.get_card_definitions()
	var selected: Array[Dictionary] = []
	while selected.size() < count and not definitions.is_empty():
		var total_weight: float = 0.0
		for definition in definitions:
			total_weight += _special_card_weight(definition)
		var roll: float = card_rng.randf() * total_weight
		var cumulative: float = 0.0
		var chosen_index: int = 0
		for index in range(definitions.size()):
			cumulative += _special_card_weight(definitions[index])
			if roll <= cumulative:
				chosen_index = index
				break
		selected.append(SPECIAL_CARD_CATALOG.resolve_card_effects(definitions[chosen_index], card_rng, player.pulse_enabled))
		definitions.remove_at(chosen_index)
	return selected


func _special_card_weight(definition: Dictionary) -> float:
	var weight: float = float(definition.get("weight", 1.0))
	var card_type: String = String(definition.get("type", ""))
	var card_id: String = String(definition.get("id", ""))
	if card_type == "风险" and current_stage_index >= 2:
		weight *= 1.22
	if card_type == "未知" and next_card_event_index >= 2:
		weight *= 1.15
	if card_id == "pulse_prism" and player.pulse_enabled:
		weight *= 1.35
	if card_id == "pulse_prism" and int(upgrade_levels.get("pulse_core", 0)) > 0:
		weight *= 1.28
	if card_id == "feral_script" and int(upgrade_levels.get("rapid_fire", 0)) > 0:
		weight *= 1.25
	if card_id == "glass_engine" and int(upgrade_levels.get("split_round", 0)) > 0:
		weight *= 1.3
	if selected_branch_id == "tank" and (card_id == "rift_stride" or card_id == "pulse_prism"):
		weight *= 1.16
	if selected_branch_id == "debuff" and (card_id == "blood_contract" or card_id == "feral_script"):
		weight *= 1.22
	if selected_branch_id == "building" and (card_id == "pulse_prism" or card_id == "glass_engine"):
		weight *= 1.18
	return weight


func _on_special_card_selected(index: int) -> void:
	if index < 0 or index >= current_special_card_options.size():
		return
	var card: Dictionary = current_special_card_options[index]
	var resolved_effects: Array[Dictionary] = []
	for effect in Array(card.get("resolved_effects", [])):
		resolved_effects.append(Dictionary(effect).duplicate(true))
	for effect in resolved_effects:
		player.apply_meta_bonus(String(effect.get("type", "")), float(effect.get("amount", 0.0)))
	selected_special_cards.append(String(card.get("name", "")))
	player.refresh_health_ui()
	_refresh_hud()
	hud.set_build_text(_compose_build_summary())
	hud.show_event("技能卡生效：%s\n%s" % [
		String(card.get("name", "")),
		SPECIAL_CARD_CATALOG.describe_effects(resolved_effects)
	], 2.4)
	audio_manager.play_sfx("level_up", 0.94, -3.0)
	current_special_card_options.clear()
	special_card_active = false
	special_card_panel.hide_panel()
	_set_modal_pause(false)


func _clear_special_card_pickups() -> void:
	for child in cards_layer.get_children():
		child.queue_free()


func _spawn_boss_support_wave(phase: int, origin: Vector2) -> void:
	var support_ids: Array[String] = ["runner", "runner", "brute"]
	if phase >= 2:
		support_ids.append("shooter")
	for index in range(support_ids.size()):
		var angle: float = TAU * float(index) / float(support_ids.size()) + randf_range(-0.18, 0.18)
		var distance: float = 110.0 + 26.0 * float(index % 2)
		var spawn_position: Vector2 = origin + Vector2.RIGHT.rotated(angle) * distance
		_spawn_enemy_by_id(
			support_ids[index],
			false,
			Vector2(
				clampf(spawn_position.x, -1540.0, 1540.0),
				clampf(spawn_position.y, -1540.0, 1540.0)
			)
		)


func _set_modal_pause(active: bool) -> void:
	get_tree().paused = active


func _spawn_burst(world_position: Vector2, color: Color, size: float, count: int, duration: float, spread: float) -> void:
	var burst := PixelBurst.new()
	burst.global_position = world_position
	burst.setup(color, size, count, duration, spread)
	effects_layer.add_child(burst)
