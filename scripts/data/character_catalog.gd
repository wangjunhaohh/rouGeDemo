extends RefCounted
class_name CharacterCatalog


static func get_character_definitions() -> Array[Dictionary]:
	return [
		{
			"id": "swordsman",
			"name": "剑客",
			"description": "高攻击近战角色，擅长快速切入与多段斩击。",
			"role": "近战爆发 / 多段斩击",
			"difficulty": "中",
			"recommended_branches": PackedStringArray(["肉盾流", "异常流"]),
			"weakness": "生存中低，被围住时风险较高。",
			"exclusive_skill_id": "shadow_sword_array",
			"base_stats": {
				"max_health": 90.0,
				"projectile_damage": 14.0,
				"attack_speed": 1.15,
				"move_speed": 210.0,
				"armor": 2.0,
				"critical_chance": 0.08,
				"spell_power": 8.0,
				"skill_cooldown_multiplier": 1.0,
				"skill_radius_multiplier": 1.0
			}
		},
		{
			"id": "mage",
			"name": "法师",
			"description": "范围法术角色，擅长用法阵和轰炸控制战场。",
			"role": "法术范围 / 区域压制",
			"difficulty": "中",
			"recommended_branches": PackedStringArray(["异常流", "召唤流"]),
			"weakness": "身板脆，怕被近身，技能空窗期压力较高。",
			"exclusive_skill_id": "arcane_bombardment",
			"base_stats": {
				"max_health": 75.0,
				"projectile_damage": 8.0,
				"attack_speed": 0.9,
				"move_speed": 190.0,
				"armor": 1.0,
				"critical_chance": 0.0,
				"spell_power": 16.0,
				"skill_cooldown_multiplier": 0.95,
				"skill_radius_multiplier": 1.1
			}
		}
	]


static func get_character_definition(character_id: String) -> Dictionary:
	for definition in get_character_definitions():
		if String(definition.get("id", "")) == character_id:
			return definition.duplicate(true)
	return {}


static func get_skill_definition(skill_id: String) -> Dictionary:
	var definitions := {
		"shadow_sword_array": {
			"id": "shadow_sword_array",
			"owner_character_id": "swordsman",
			"name": "瞬影剑阵",
			"description": "短时间释放 5 段残影斩击，对同一目标最多命中 4 次。",
			"cooldown": 18.0,
			"duration": 1.2,
			"damage_scale": 0.7,
			"radius": 160.0,
			"slash_count": 5,
			"max_hit_per_target": 4,
			"damage_taken_multiplier": 0.5,
			"knockback": 170.0,
			"tags": PackedStringArray(["melee", "slash", "burst"])
		},
		"arcane_bombardment": {
			"id": "arcane_bombardment",
			"owner_character_id": "mage",
			"name": "环域轰炸",
			"description": "在自身周围展开跟随法阵，周期生成预警轰炸。",
			"cooldown": 16.0,
			"duration": 4.0,
			"damage_scale": 0.9,
			"radius": 180.0,
			"tick_interval": 0.35,
			"explosion_radius": 45.0,
			"warning_delay": 0.28,
			"burn_damage": 2.0,
			"burn_duration": 1.6,
			"slow_duration": 0.45,
			"slow_amount": 0.82,
			"tags": PackedStringArray(["magic", "aoe", "debuff"])
		}
	}
	var definition: Dictionary = definitions.get(skill_id, {})
	return definition.duplicate(true)
