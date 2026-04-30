extends RefCounted
class_name MetaProgression

const SAVE_PATH := "user://meta_progression.save"
const UPGRADE_ORDER := [
	"endurance",
	"drill",
	"magnet",
	"stride",
	"cadence",
	"piercer",
	"furnace",
	"salvage",
	"field_medic",
	"arsenal_cache"
]
const CHARACTER_UPGRADE_ORDER := {
	"swordsman": [
		"blade_training",
		"guarded_step",
		"shadow_edge",
		"swift_footwork",
		"shadow_return"
	],
	"mage": [
		"arcane_core",
		"warded_body",
		"bombard_focus",
		"circle_control",
		"cooldown_glyph"
	]
}
const DEFINITIONS := {
	"endurance": {
		"name": "钢骨训练",
		"description": "开局最大生命 +10",
		"cost": 20,
		"cost_step": 14,
		"max_level": 5,
		"effect_type": "max_health",
		"amount": 10.0
	},
	"drill": {
		"name": "火力校准",
		"description": "开局主武器伤害 +3",
		"cost": 22,
		"cost_step": 15,
		"max_level": 5,
		"effect_type": "projectile_damage",
		"amount": 3.0
	},
	"magnet": {
		"name": "磁吸线圈",
		"description": "拾取范围 +16",
		"cost": 18,
		"cost_step": 12,
		"max_level": 4,
		"effect_type": "pickup_radius",
		"amount": 16.0
	},
	"stride": {
		"name": "轻装步法",
		"description": "移动速度 +14",
		"cost": 18,
		"cost_step": 12,
		"max_level": 4,
		"effect_type": "move_speed",
		"amount": 14.0
	},
	"cadence": {
		"name": "连发组件",
		"description": "开局主武器冷却 -0.08 秒",
		"cost": 28,
		"cost_step": 18,
		"max_level": 4,
		"effect_type": "projectile_cooldown",
		"amount": -0.08,
		"requires": {"drill": 1}
	},
	"piercer": {
		"name": "破甲芯轴",
		"description": "开局主武器穿透 +1",
		"cost": 34,
		"cost_step": 20,
		"max_level": 2,
		"effect_type": "projectile_pierce",
		"amount": 1.0,
		"requires": {"cadence": 1}
	},
	"furnace": {
		"name": "余烬电容",
		"description": "开局解锁脉冲，并让脉冲伤害 +6",
		"cost": 36,
		"cost_step": 20,
		"max_level": 1,
		"effect_type": "unlock_pulse",
		"amount": 1.0,
		"secondary_effect_type": "pulse_damage",
		"secondary_amount": 6.0,
		"requires": {"drill": 2}
	},
	"salvage": {
		"name": "残响回收",
		"description": "结算暗核碎片 +12%",
		"cost": 26,
		"cost_step": 16,
		"max_level": 3,
		"effect_type": "shard_bonus_rate",
		"amount": 0.12,
		"requires": {"magnet": 1}
	},
	"field_medic": {
		"name": "战地注剂",
		"description": "开局最大生命 +8、移动速度 +4",
		"cost": 30,
		"cost_step": 16,
		"max_level": 4,
		"effect_type": "max_health",
		"amount": 8.0,
		"secondary_effect_type": "move_speed",
		"secondary_amount": 4.0,
		"requires": {"endurance": 2}
	},
	"arsenal_cache": {
		"name": "军械暗仓",
		"description": "开局主武器伤害 +2、拾取范围 +8",
		"cost": 32,
		"cost_step": 18,
		"max_level": 4,
		"effect_type": "projectile_damage",
		"amount": 2.0,
		"secondary_effect_type": "pickup_radius",
		"secondary_amount": 8.0,
		"requires": {"drill": 2, "magnet": 1}
	}
}
const CHARACTER_DEFINITIONS := {
	"swordsman": {
		"blade_training": {
			"name": "刃术根基",
			"description": "普攻伤害 +2",
			"cost": 14,
			"cost_step": 10,
			"max_level": 5,
			"effect_type": "projectile_damage",
			"amount": 2.0,
			"position": Vector2(0.12, 0.18)
		},
		"guarded_step": {
			"name": "护身步",
			"description": "生命 +8 / 护甲 +0.5",
			"cost": 16,
			"cost_step": 11,
			"max_level": 5,
			"effect_type": "max_health",
			"amount": 8.0,
			"secondary_effect_type": "character_armor",
			"secondary_amount": 0.5,
			"position": Vector2(0.12, 0.68)
		},
		"shadow_edge": {
			"name": "影刃增幅",
			"description": "技能伤害 +8%",
			"cost": 22,
			"cost_step": 14,
			"max_level": 4,
			"effect_type": "exclusive_skill_damage_multiplier",
			"amount": 0.08,
			"requires": {"blade_training": 1},
			"position": Vector2(0.48, 0.24)
		},
		"swift_footwork": {
			"name": "疾影步",
			"description": "移速 +6 / 暴击 +1.5%",
			"cost": 20,
			"cost_step": 13,
			"max_level": 4,
			"effect_type": "move_speed",
			"amount": 6.0,
			"secondary_effect_type": "critical_chance",
			"secondary_amount": 0.015,
			"requires": {"guarded_step": 1},
			"position": Vector2(0.48, 0.68)
		},
		"shadow_return": {
			"name": "回影式",
			"description": "技能冷却 -4% / 范围 +4%",
			"cost": 34,
			"cost_step": 18,
			"max_level": 3,
			"effect_type": "exclusive_skill_cooldown_multiplier",
			"amount": -0.04,
			"secondary_effect_type": "exclusive_skill_radius_multiplier",
			"secondary_amount": 0.04,
			"requires": {"shadow_edge": 2, "swift_footwork": 1},
			"position": Vector2(0.82, 0.46)
		}
	},
	"mage": {
		"arcane_core": {
			"name": "奥术核心",
			"description": "法术强度 +3",
			"cost": 14,
			"cost_step": 10,
			"max_level": 5,
			"effect_type": "spell_power",
			"amount": 3.0,
			"position": Vector2(0.12, 0.18)
		},
		"warded_body": {
			"name": "秘纹护体",
			"description": "生命 +7 / 护甲 +0.4",
			"cost": 16,
			"cost_step": 11,
			"max_level": 5,
			"effect_type": "max_health",
			"amount": 7.0,
			"secondary_effect_type": "character_armor",
			"secondary_amount": 0.4,
			"position": Vector2(0.12, 0.68)
		},
		"bombard_focus": {
			"name": "轰炸聚焦",
			"description": "技能伤害 +9%",
			"cost": 22,
			"cost_step": 14,
			"max_level": 4,
			"effect_type": "exclusive_skill_damage_multiplier",
			"amount": 0.09,
			"requires": {"arcane_core": 1},
			"position": Vector2(0.48, 0.24)
		},
		"circle_control": {
			"name": "环域掌控",
			"description": "技能范围 +4% / 移速 +4",
			"cost": 20,
			"cost_step": 13,
			"max_level": 4,
			"effect_type": "exclusive_skill_radius_multiplier",
			"amount": 0.04,
			"secondary_effect_type": "move_speed",
			"secondary_amount": 4.0,
			"requires": {"warded_body": 1},
			"position": Vector2(0.48, 0.68)
		},
		"cooldown_glyph": {
			"name": "回响刻印",
			"description": "技能冷却 -4% / 法强 +2",
			"cost": 34,
			"cost_step": 18,
			"max_level": 3,
			"effect_type": "exclusive_skill_cooldown_multiplier",
			"amount": -0.04,
			"secondary_effect_type": "spell_power",
			"secondary_amount": 2.0,
			"requires": {"bombard_focus": 2, "circle_control": 1},
			"position": Vector2(0.82, 0.46)
		}
	}
}

var shards: int = 0
var upgrades: Dictionary = {}
var character_upgrades: Dictionary = {}


static func load_or_create() -> MetaProgression:
	var profile := MetaProgression.new()
	if not FileAccess.file_exists(SAVE_PATH):
		return profile

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return profile

	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		profile.shards = int(parsed.get("shards", 0))
		profile.upgrades = parsed.get("upgrades", {}).duplicate(true)
		profile.character_upgrades = parsed.get("character_upgrades", {}).duplicate(true)
	return profile


func save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"shards": shards,
		"upgrades": upgrades,
		"character_upgrades": character_upgrades
	}, "\t"))


func get_level(upgrade_id: String) -> int:
	return int(upgrades.get(upgrade_id, 0))


func get_cost(upgrade_id: String) -> int:
	var definition: Dictionary = DEFINITIONS.get(upgrade_id, {})
	var level := get_level(upgrade_id)
	return int(definition.get("cost", 0)) + int(definition.get("cost_step", 0)) * level


func can_purchase(upgrade_id: String) -> bool:
	var definition: Dictionary = DEFINITIONS.get(upgrade_id, {})
	if definition.is_empty():
		return false
	if get_level(upgrade_id) >= int(definition.get("max_level", 0)):
		return false
	if not _requirements_met(Dictionary(definition.get("requires", {}))):
		return false
	return shards >= get_cost(upgrade_id)


func purchase(upgrade_id: String) -> bool:
	if not can_purchase(upgrade_id):
		return false
	shards -= get_cost(upgrade_id)
	upgrades[upgrade_id] = get_level(upgrade_id) + 1
	save()
	return true


func get_character_upgrade_level(character_id: String, upgrade_id: String) -> int:
	var character_levels: Dictionary = Dictionary(character_upgrades.get(character_id, {}))
	return int(character_levels.get(upgrade_id, 0))


func get_character_upgrade_cost(character_id: String, upgrade_id: String) -> int:
	var definition: Dictionary = _get_character_upgrade_definition(character_id, upgrade_id)
	var level := get_character_upgrade_level(character_id, upgrade_id)
	return int(definition.get("cost", 0)) + int(definition.get("cost_step", 0)) * level


func can_purchase_character_upgrade(character_id: String, upgrade_id: String) -> bool:
	var definition: Dictionary = _get_character_upgrade_definition(character_id, upgrade_id)
	if definition.is_empty():
		return false
	if get_character_upgrade_level(character_id, upgrade_id) >= int(definition.get("max_level", 0)):
		return false
	if not _character_requirements_met(character_id, Dictionary(definition.get("requires", {}))):
		return false
	return shards >= get_character_upgrade_cost(character_id, upgrade_id)


func purchase_character_upgrade(character_id: String, upgrade_id: String) -> bool:
	if not can_purchase_character_upgrade(character_id, upgrade_id):
		return false
	var character_levels: Dictionary = Dictionary(character_upgrades.get(character_id, {}))
	shards -= get_character_upgrade_cost(character_id, upgrade_id)
	character_levels[upgrade_id] = get_character_upgrade_level(character_id, upgrade_id) + 1
	character_upgrades[character_id] = character_levels
	save()
	return true


func apply_to_player(player: Player) -> void:
	for upgrade_id in upgrades.keys():
		var definition: Dictionary = DEFINITIONS.get(upgrade_id, {})
		var level := get_level(upgrade_id)
		for _i in range(level):
			# 局外成长只下发本局开局属性，不直接改分支结构，避免和开局分支选择互相覆盖。
			_apply_run_effect(player, String(definition.get("effect_type", "")), float(definition.get("amount", 0.0)))
			_apply_run_effect(player, String(definition.get("secondary_effect_type", "")), float(definition.get("secondary_amount", 0.0)))
	player.refresh_health_ui()


func apply_character_to_player(player: Player, character_id: String) -> void:
	var character_levels: Dictionary = Dictionary(character_upgrades.get(character_id, {}))
	for upgrade_id in character_levels.keys():
		var definition: Dictionary = _get_character_upgrade_definition(character_id, String(upgrade_id))
		var level := get_character_upgrade_level(character_id, String(upgrade_id))
		for _i in range(level):
			_apply_run_effect(player, String(definition.get("effect_type", "")), float(definition.get("amount", 0.0)))
			_apply_run_effect(player, String(definition.get("secondary_effect_type", "")), float(definition.get("secondary_amount", 0.0)))
	player.refresh_health_ui()


func build_upgrade_view_models() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	for upgrade_id in UPGRADE_ORDER:
		var definition: Dictionary = DEFINITIONS[upgrade_id]
		items.append({
			"id": upgrade_id,
			"name": definition["name"],
			"description": definition["description"],
			"level": get_level(upgrade_id),
			"max_level": int(definition["max_level"]),
			"cost": get_cost(upgrade_id),
			"can_buy": can_purchase(upgrade_id),
			"locked_reason": get_locked_reason(upgrade_id)
		})
	return items


func build_character_upgrade_view_models(character_id: String) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	var order: Array = CHARACTER_UPGRADE_ORDER.get(character_id, [])
	for upgrade_id_variant in order:
		var upgrade_id: String = String(upgrade_id_variant)
		var definition: Dictionary = _get_character_upgrade_definition(character_id, upgrade_id)
		items.append({
			"id": upgrade_id,
			"name": definition["name"],
			"description": definition["description"],
			"level": get_character_upgrade_level(character_id, upgrade_id),
			"max_level": int(definition["max_level"]),
			"cost": get_character_upgrade_cost(character_id, upgrade_id),
			"can_buy": can_purchase_character_upgrade(character_id, upgrade_id),
			"locked_reason": get_character_upgrade_locked_reason(character_id, upgrade_id),
			"requires": Dictionary(definition.get("requires", {})),
			"position": definition.get("position", Vector2(0.5, 0.5))
		})
	return items


func get_character_total_level(character_id: String) -> int:
	var total := 0
	var character_levels: Dictionary = Dictionary(character_upgrades.get(character_id, {}))
	for upgrade_id in character_levels.keys():
		total += int(character_levels[upgrade_id])
	return total


func get_locked_reason(upgrade_id: String) -> String:
	var definition: Dictionary = DEFINITIONS.get(upgrade_id, {})
	if definition.is_empty():
		return ""
	var requirements: Dictionary = Dictionary(definition.get("requires", {}))
	if requirements.is_empty():
		return ""
	var parts: Array[String] = []
	for requirement_id in requirements.keys():
		var required_level: int = int(requirements[requirement_id])
		if get_level(String(requirement_id)) >= required_level:
			continue
		var requirement_definition: Dictionary = DEFINITIONS.get(requirement_id, {})
		var requirement_name: String = String(requirement_definition.get("name", requirement_id))
		parts.append("%s Lv.%d" % [requirement_name, required_level])
	return "需要 %s" % " / ".join(parts)


func get_character_upgrade_locked_reason(character_id: String, upgrade_id: String) -> String:
	var definition: Dictionary = _get_character_upgrade_definition(character_id, upgrade_id)
	if definition.is_empty():
		return ""
	var requirements: Dictionary = Dictionary(definition.get("requires", {}))
	if requirements.is_empty():
		return ""
	var parts: Array[String] = []
	for requirement_id in requirements.keys():
		var required_level: int = int(requirements[requirement_id])
		if get_character_upgrade_level(character_id, String(requirement_id)) >= required_level:
			continue
		var requirement_definition: Dictionary = _get_character_upgrade_definition(character_id, String(requirement_id))
		var requirement_name: String = String(requirement_definition.get("name", requirement_id))
		parts.append("%s Lv.%d" % [requirement_name, required_level])
	return "需要 %s" % " / ".join(parts)


func get_total_effect_value(effect_type: String) -> float:
	var total: float = 0.0
	for upgrade_id in upgrades.keys():
		var definition: Dictionary = DEFINITIONS.get(upgrade_id, {})
		if definition.is_empty():
			continue
		var level: int = get_level(String(upgrade_id))
		if String(definition.get("effect_type", "")) == effect_type:
			total += float(definition.get("amount", 0.0)) * level
		if String(definition.get("secondary_effect_type", "")) == effect_type:
			total += float(definition.get("secondary_amount", 0.0)) * level
	return total


func _requirements_met(requirements: Dictionary) -> bool:
	for requirement_id in requirements.keys():
		if get_level(String(requirement_id)) < int(requirements[requirement_id]):
			return false
	return true


func _character_requirements_met(character_id: String, requirements: Dictionary) -> bool:
	for requirement_id in requirements.keys():
		if get_character_upgrade_level(character_id, String(requirement_id)) < int(requirements[requirement_id]):
			return false
	return true


func _get_character_upgrade_definition(character_id: String, upgrade_id: String) -> Dictionary:
	var character_definitions: Dictionary = Dictionary(CHARACTER_DEFINITIONS.get(character_id, {}))
	return Dictionary(character_definitions.get(upgrade_id, {}))


func _apply_run_effect(player: Player, effect_type: String, amount: float) -> void:
	if effect_type.is_empty():
		return
	if effect_type == "shard_bonus_rate":
		return
	player.apply_meta_bonus(effect_type, amount)
