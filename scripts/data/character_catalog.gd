extends RefCounted
class_name CharacterCatalog

const SWORDSMAN_BODY_SPRITE_FRAMES := preload("res://resources/animations/swordsman_body_sprite_frames.tres")
const SWORDSMAN_SKILL_EFFECT_SPRITE_FRAMES := preload("res://resources/animations/swordsman_skill_effect_sprite_frames.tres")
const MAGE_BODY_SPRITE_FRAMES := preload("res://resources/animations/mage_body_sprite_frames.tres")
const MAGE_ICE_BIRD_SPRITE_FRAMES := preload("res://resources/animations/mage_ice_bird_sprite_frames.tres")


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
			"body_sprite_frames": SWORDSMAN_BODY_SPRITE_FRAMES,
			"body_visual_scale": 0.45,
			"body_visual_offset": Vector2(0.0, 3.0),
			"body_texture_filter": CanvasItem.TEXTURE_FILTER_LINEAR,
			"primary_attack_type": "melee",
			"primary_attack_range": 104.0,
			"primary_attack_arc": 110.0,
			"primary_windup_time": 0.18,
			"primary_recovery_time": 0.15,
			"primary_hit_frame_progress": 0.68,
			"primary_attack_animation": "sword_attack",
			"hide_primary_weapon_visual": true,
			"hide_melee_weapon_visual": true,
			"base_stats": {
				"max_health": 90.0,
				"projectile_damage": 14.0,
				"attack_speed": 1.15,
				"move_speed": 210.0,
				"armor": 2.0,
				"critical_chance": 0.08,
				"spell_power": 8.0,
				"attack_animation_speed_multiplier": 1.0,
				"skill_cooldown_multiplier": 1.0,
				"skill_radius_multiplier": 1.0,
				"skill_effect_speed": 1.0
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
			"body_sprite_frames": MAGE_BODY_SPRITE_FRAMES,
			"body_visual_scale": 0.45,
			"body_visual_offset": Vector2(0.0, 3.0),
			"body_texture_filter": CanvasItem.TEXTURE_FILTER_LINEAR,
			"primary_attack_type": "projectile",
			"primary_windup_time": 0.2,
			"primary_recovery_time": 0.12,
			"primary_hit_frame_progress": 0.68,
			"primary_muzzle_distance": 24.0,
			"primary_attack_animation": "ice_attack",
			"primary_attack_spawn_frame": 4,
			"hide_primary_weapon_visual": true,
			"primary_projectile": {
				"sprite_frames": MAGE_ICE_BIRD_SPRITE_FRAMES,
				"flight_animation": "flight",
				"impact_animation": "impact",
				"visual_scale": 0.45,
				"collision_radius": 18.0,
				"area_damage_radius": 30.0,
				"impact_duration": 0.12,
				"speed_multiplier": 0.95,
				"spin": 0.0,
				"texture_filter": CanvasItem.TEXTURE_FILTER_LINEAR,
				"area_damage_on_impact": true
			},
			"base_stats": {
				"max_health": 75.0,
				"projectile_damage": 8.0,
				"attack_speed": 0.9,
				"move_speed": 190.0,
				"armor": 1.0,
				"critical_chance": 0.0,
				"spell_power": 16.0,
				"attack_animation_speed_multiplier": 1.0,
				"skill_cooldown_multiplier": 0.95,
				"skill_radius_multiplier": 1.1,
				"skill_effect_speed": 1.0
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
			"effect_visual": {
				"sprite_frames": SWORDSMAN_SKILL_EFFECT_SPRITE_FRAMES,
				"animation": "cast",
				"base_size": 384.0,
				"radius_scale": 2.35,
				"speed_scale": 1.0,
				"alpha": 0.92,
				"z_index": 12
			},
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
