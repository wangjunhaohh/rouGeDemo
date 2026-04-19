extends RefCounted
class_name BranchCatalog

const TANK_WEAPON_FRAME_PATHS := {
	"idle": "res://art/sprites/branch_weapons/tank_blade_idle.png",
	"windup": "res://art/sprites/branch_weapons/tank_blade_windup.png",
	"release": "res://art/sprites/branch_weapons/tank_blade_swing.png",
	"recover": "res://art/sprites/branch_weapons/tank_blade_recover.png"
}
const TANK_FLASH_FRAME_PATHS := {
	"a": "res://art/sprites/branch_weapons/tank_slash_a.png",
	"b": "res://art/sprites/branch_weapons/tank_slash_b.png"
}
const DEBUFF_WEAPON_FRAME_PATHS := {
	"idle": "res://art/sprites/branch_weapons/debuff_staff_idle.png",
	"windup": "res://art/sprites/branch_weapons/debuff_staff_cast.png",
	"release": "res://art/sprites/branch_weapons/debuff_staff_release.png",
	"recover": "res://art/sprites/branch_weapons/debuff_staff_idle.png"
}
const DEBUFF_FLASH_FRAME_PATHS := {
	"a": "res://art/sprites/branch_weapons/debuff_cast_a.png",
	"b": "res://art/sprites/branch_weapons/debuff_cast_b.png"
}
const BUILDING_WEAPON_FRAME_PATHS := {
	"idle": "res://art/sprites/branch_weapons/building_relay_idle.png",
	"windup": "res://art/sprites/branch_weapons/building_relay_charge.png",
	"release": "res://art/sprites/branch_weapons/building_relay_release.png",
	"recover": "res://art/sprites/branch_weapons/building_relay_idle.png"
}
const BUILDING_FLASH_FRAME_PATHS := {
	"a": "res://art/sprites/branch_weapons/building_signal_a.png",
	"b": "res://art/sprites/branch_weapons/building_signal_b.png"
}
const DEBUFF_PROJECTILE_TEXTURE_PATH := "res://art/sprites/branch_weapons/debuff_orb.png"
const BUILDING_PROJECTILE_TEXTURE_PATH := "res://art/sprites/branch_weapons/building_bolt.png"

static func get_branch_definitions() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	for definition in _build_branch_definitions():
		items.append(Dictionary(definition).duplicate(true))
	return items


static func get_branch_definition(branch_id: String) -> Dictionary:
	for definition in _build_branch_definitions():
		var item: Dictionary = definition
		if String(item.get("id", "")) == branch_id:
			return item.duplicate(true)
	return {}


static func _build_branch_definitions() -> Array[Dictionary]:
	return [
		{
			"id": "tank",
			"name": "肉盾流",
			"summary": "贴脸站场，靠震荡护环清开近身压力",
			"description": "开局最大生命 +18，受到接触伤害 -18%。每 5 次主武器射击会触发一次近身震荡护环，受击时也会触发一次弱化反震。",
			"accent_color": Color(0.9, 0.74, 0.42, 1.0),
			"weapon_tint": Color(0.96, 0.84, 0.58, 1.0),
			"flash_color": Color(1.0, 0.9, 0.58, 1.0),
			"weapon_type": "melee",
			"attack_shape": "arc",
			"attack_range": 96.0,
			"attack_arc": 108.0,
			"windup_time": 0.18,
			"recovery_time": 0.15,
			"animation_key": "tank_blade",
			"weapon_length": 20.0,
			"muzzle_distance": 30.0,
			"flash_distance": 32.0,
			"weapon_base_scale": 0.72,
			"flash_base_scale": 0.92,
			"projectile_scale": 0.62,
			"projectile_spin": 0.0,
			"projectile_speed_multiplier": 1.0,
			"projectile_range_multiplier": 1.0,
			"weapon_frames": _load_frame_dictionary(TANK_WEAPON_FRAME_PATHS),
			"flash_frames": _load_frame_dictionary(TANK_FLASH_FRAME_PATHS),
			"damage_taken_multiplier": 0.82,
			"guard_shot_interval": 5,
			"guard_damage": 14.0,
			"guard_radius": 96.0,
			"guard_knockback": 360.0,
			"starting_effects": [
				{"type": "max_health", "amount": 18.0}
			],
			"preferred_tags": PackedStringArray(["tank"]),
			"secondary_tags": PackedStringArray(["neutral", "building"]),
			"priority_synergy_tags": PackedStringArray(["survival", "guard", "pulse", "mobility"])
		},
		{
			"id": "debuff",
			"name": "异常流",
			"summary": "燃烧直伤配合法球灼地，持续压血控场",
			"description": "主武器和脉冲附带燃烧。每 5 次主武器射击会额外抛出一枚蚀火法球，落地后生成减速灼地区域。",
			"accent_color": Color(0.95, 0.38, 0.26, 1.0),
			"weapon_tint": Color(0.96, 0.62, 0.42, 1.0),
			"flash_color": Color(1.0, 0.58, 0.34, 1.0),
			"weapon_type": "thrown",
			"attack_shape": "orb",
			"attack_range": 0.0,
			"attack_arc": 0.0,
			"windup_time": 0.2,
			"recovery_time": 0.12,
			"animation_key": "debuff_staff",
			"weapon_length": 17.0,
			"muzzle_distance": 24.0,
			"flash_distance": 24.0,
			"weapon_base_scale": 0.7,
			"flash_base_scale": 0.82,
			"projectile_scale": 0.68,
			"projectile_spin": 7.4,
			"projectile_speed_multiplier": 0.9,
			"projectile_range_multiplier": 0.92,
			"weapon_frames": _load_frame_dictionary(DEBUFF_WEAPON_FRAME_PATHS),
			"flash_frames": _load_frame_dictionary(DEBUFF_FLASH_FRAME_PATHS),
			"projectile_texture": _load_texture(DEBUFF_PROJECTILE_TEXTURE_PATH),
			"burn_damage": 4.0,
			"burn_duration": 2.4,
			"scorch_orb_shot_interval": 5,
			"scorch_orb_damage": 11.0,
			"scorch_orb_speed": 245.0,
			"scorch_orb_range": 280.0,
			"scorch_field_radius": 84.0,
			"scorch_field_duration": 2.8,
			"scorch_field_tick_damage": 2.0,
			"scorch_field_tick_interval": 0.5,
			"scorch_slow_duration": 0.95,
			"scorch_slow_amount": 0.8,
			"preferred_tags": PackedStringArray(["debuff"]),
			"secondary_tags": PackedStringArray(["neutral", "building"]),
			"priority_synergy_tags": PackedStringArray(["burn", "tempo", "damage", "pressure"])
		},
		{
			"id": "building",
			"name": "召唤流",
			"summary": "哨戒节点自动开火并周期性放出压制脉冲",
			"description": "每 6 次主武器射击会部署 1 个短命哨戒节点。节点会自主射击，并定期释放近距离压制脉冲。",
			"accent_color": Color(0.42, 0.88, 0.96, 1.0),
			"weapon_tint": Color(0.56, 0.86, 0.96, 1.0),
			"flash_color": Color(0.58, 0.95, 1.0, 1.0),
			"weapon_type": "ranged",
			"attack_shape": "bolt",
			"attack_range": 0.0,
			"attack_arc": 0.0,
			"windup_time": 0.14,
			"recovery_time": 0.1,
			"animation_key": "building_relay",
			"weapon_length": 16.0,
			"muzzle_distance": 25.0,
			"flash_distance": 26.0,
			"weapon_base_scale": 0.72,
			"flash_base_scale": 0.84,
			"projectile_scale": 0.66,
			"projectile_spin": 0.0,
			"projectile_speed_multiplier": 1.08,
			"projectile_range_multiplier": 1.0,
			"weapon_frames": _load_frame_dictionary(BUILDING_WEAPON_FRAME_PATHS),
			"flash_frames": _load_frame_dictionary(BUILDING_FLASH_FRAME_PATHS),
			"projectile_texture": _load_texture(BUILDING_PROJECTILE_TEXTURE_PATH),
			"sentry_shot_interval": 6,
			"sentry_lifetime": 8.0,
			"sentry_fire_interval": 0.78,
			"sentry_damage_multiplier": 0.42,
			"sentry_range": 340.0,
			"sentry_pulse_damage": 8.0,
			"sentry_pulse_radius": 68.0,
			"sentry_pulse_interval": 1.75,
			"preferred_tags": PackedStringArray(["building"]),
			"secondary_tags": PackedStringArray(["neutral", "tank"]),
			"priority_synergy_tags": PackedStringArray(["summon", "range", "formation", "pulse"])
		}
	]


static func _load_frame_dictionary(paths: Dictionary) -> Dictionary:
	var frames: Dictionary = {}
	for key in paths.keys():
		frames[key] = _load_texture(String(paths[key]))
	return frames


static func _load_texture(path: String) -> Texture2D:
	var image := Image.new()
	var error := image.load(ProjectSettings.globalize_path(path))
	if error != OK:
		push_warning("Failed to load branch weapon texture: %s" % path)
		return null
	return ImageTexture.create_from_image(image)


static func get_branch_name(branch_id: String) -> String:
	var definition: Dictionary = get_branch_definition(branch_id)
	return String(definition.get("name", "未定分支"))


static func has_branch_tag(upgrade: UpgradeData, branch_id: String) -> bool:
	if String(upgrade.exclusive_branch) == branch_id:
		return true
	for tag in upgrade.tags:
		if String(tag) == branch_id:
			return true
	return false


static func is_neutral(upgrade: UpgradeData) -> bool:
	for tag in upgrade.tags:
		if String(tag) == "neutral":
			return true
	return false


static func is_primary_branch_match(upgrade: UpgradeData, branch_id: String) -> bool:
	if branch_id.is_empty():
		return false
	if not upgrade.exclusive_branch.is_empty():
		return String(upgrade.exclusive_branch) == branch_id
	var definition: Dictionary = get_branch_definition(branch_id)
	var preferred_tags: PackedStringArray = PackedStringArray(definition.get("preferred_tags", PackedStringArray()))
	for raw_tag in upgrade.tags:
		if preferred_tags.has(String(raw_tag)):
			return true
	return false


static func get_branch_weight_multiplier(upgrade: UpgradeData, branch_id: String, primary_pick: bool) -> float:
	if branch_id.is_empty():
		return 1.0
	if not upgrade.exclusive_branch.is_empty():
		if String(upgrade.exclusive_branch) == branch_id:
			return 2.45 if primary_pick else 1.22
		return 0.0

	var definition: Dictionary = get_branch_definition(branch_id)
	var preferred_tags: PackedStringArray = PackedStringArray(definition.get("preferred_tags", PackedStringArray()))
	var secondary_tags: PackedStringArray = PackedStringArray(definition.get("secondary_tags", PackedStringArray()))
	var matched_preferred := false
	var matched_secondary := false
	var matched_neutral := false
	for raw_tag in upgrade.tags:
		var tag: String = String(raw_tag)
		if preferred_tags.has(tag):
			matched_preferred = true
		elif secondary_tags.has(tag):
			matched_secondary = true
		elif tag == "neutral":
			matched_neutral = true

	if primary_pick:
		if matched_preferred:
			return 2.35
		if matched_secondary:
			return 1.22
		if matched_neutral:
			return 1.12
		return 0.68

	if matched_neutral:
		return 1.35
	if matched_secondary:
		return 1.18
	if matched_preferred:
		return 1.0
	return 0.82


static func get_branch_synergy_multiplier(upgrade: UpgradeData, branch_id: String) -> float:
	if branch_id.is_empty():
		return 1.0
	var definition: Dictionary = get_branch_definition(branch_id)
	var priority_synergy_tags: PackedStringArray = PackedStringArray(definition.get("priority_synergy_tags", PackedStringArray()))
	if priority_synergy_tags.is_empty():
		return 1.0

	var matched_count := 0
	for raw_tag in upgrade.synergy_tags:
		if priority_synergy_tags.has(String(raw_tag)):
			matched_count += 1
	if matched_count <= 0:
		return 1.0

	var per_match := 1.06
	if String(upgrade.exclusive_branch) == branch_id:
		per_match = 1.1
	return float(pow(per_match, float(matched_count)))
