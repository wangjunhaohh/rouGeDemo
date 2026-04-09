extends RefCounted
class_name SpecialCardCatalog

const CARD_BUFF_ICON := preload("res://art/sprites/card_buff.png")
const CARD_RISK_ICON := preload("res://art/sprites/card_risk.png")
const CARD_UNKNOWN_ICON := preload("res://art/sprites/card_unknown.png")

const BUFF_POOL := [
	{"type": "projectile_damage", "amount": 7.0, "text": "主武器伤害 +7", "tag": "projectile"},
	{"type": "projectile_cooldown", "amount": -0.1, "text": "主武器冷却 -0.1 秒", "tag": "tempo"},
	{"type": "move_speed", "amount": 18.0, "text": "移动速度 +18", "tag": "mobility"},
	{"type": "pickup_radius", "amount": 20.0, "text": "拾取范围 +20", "tag": "pickup"},
	{"type": "pulse_damage", "amount": 8.0, "text": "脉冲伤害 +8", "tag": "pulse"},
	{"type": "pulse_cooldown", "amount": -0.18, "text": "脉冲冷却 -0.18 秒", "tag": "pulse"}
]

const DEBUFF_POOL := [
	{"type": "max_health", "amount": -12.0, "text": "最大生命 -12"},
	{"type": "move_speed", "amount": -12.0, "text": "移动速度 -12"},
	{"type": "projectile_cooldown", "amount": 0.08, "text": "主武器冷却 +0.08 秒"},
	{"type": "pickup_radius", "amount": -14.0, "text": "拾取范围 -14"}
]


static func get_card_definitions() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	for definition in _build_card_definitions():
		items.append(definition.duplicate(true))
	return items


static func _build_card_definitions() -> Array[Dictionary]:
	return [
		{
			"id": "feral_script",
			"name": "狂袭脚本",
			"type": "增益",
			"rarity": "稀有",
			"weight": 1.0,
			"effect_pool_tags": PackedStringArray(["projectile", "tempo"]),
			"allow_debuff": false,
			"display_text": "主武器伤害 +5，冷却 -0.08 秒",
			"icon": CARD_BUFF_ICON,
			"effects": [
				{"type": "projectile_damage", "amount": 5.0, "text": "主武器伤害 +5"},
				{"type": "projectile_cooldown", "amount": -0.08, "text": "主武器冷却 -0.08 秒"}
			]
		},
		{
			"id": "rift_stride",
			"name": "裂步棱镜",
			"type": "增益",
			"rarity": "普通",
			"weight": 0.92,
			"effect_pool_tags": PackedStringArray(["mobility", "pickup"]),
			"allow_debuff": false,
			"display_text": "移动速度 +18，拾取范围 +18",
			"icon": CARD_BUFF_ICON,
			"effects": [
				{"type": "move_speed", "amount": 18.0, "text": "移动速度 +18"},
				{"type": "pickup_radius", "amount": 18.0, "text": "拾取范围 +18"}
			]
		},
		{
			"id": "pulse_prism",
			"name": "脉冲棱镜",
			"type": "增益",
			"rarity": "稀有",
			"weight": 0.88,
			"effect_pool_tags": PackedStringArray(["pulse", "tempo"]),
			"allow_debuff": false,
			"display_text": "解锁脉冲，并让脉冲伤害 +6、冷却 -0.2 秒",
			"icon": CARD_BUFF_ICON,
			"effects": [
				{"type": "unlock_pulse", "amount": 1.0, "text": "解锁脉冲"},
				{"type": "pulse_damage", "amount": 6.0, "text": "脉冲伤害 +6"},
				{"type": "pulse_cooldown", "amount": -0.2, "text": "脉冲冷却 -0.2 秒"}
			]
		},
		{
			"id": "blood_contract",
			"name": "血契协议",
			"type": "风险",
			"rarity": "稀有",
			"weight": 0.8,
			"effect_pool_tags": PackedStringArray(["projectile", "risk"]),
			"allow_debuff": true,
			"display_text": "主武器伤害 +12，但最大生命 -18",
			"icon": CARD_RISK_ICON,
			"effects": [
				{"type": "projectile_damage", "amount": 12.0, "text": "主武器伤害 +12"},
				{"type": "max_health", "amount": -18.0, "text": "最大生命 -18"}
			]
		},
		{
			"id": "glass_engine",
			"name": "玻璃引擎",
			"type": "风险",
			"rarity": "传奇",
			"weight": 0.64,
			"effect_pool_tags": PackedStringArray(["projectile", "split", "risk"]),
			"allow_debuff": true,
			"display_text": "主武器弹体 +1、穿透 +1，但移动速度 -14",
			"icon": CARD_RISK_ICON,
			"effects": [
				{"type": "projectile_count", "amount": 1.0, "text": "主武器弹体 +1"},
				{"type": "projectile_pierce", "amount": 1.0, "text": "主武器穿透 +1"},
				{"type": "move_speed", "amount": -14.0, "text": "移动速度 -14"}
			]
		},
		{
			"id": "unknown_protocol",
			"name": "未知协议",
			"type": "未知",
			"rarity": "传奇",
			"weight": 0.74,
			"effect_pool_tags": PackedStringArray(["wild"]),
			"allow_debuff": true,
			"display_text": "结果不可预测，可能是强化，也可能附带代价",
			"icon": CARD_UNKNOWN_ICON,
			"effects": []
		}
	]


static func resolve_card_effects(definition: Dictionary, rng: RandomNumberGenerator, pulse_enabled: bool) -> Dictionary:
	var result: Dictionary = definition.duplicate(true)
	var effects: Array[Dictionary] = []
	if String(definition.get("id", "")) == "unknown_protocol":
		var primary_effect: Dictionary = _pick_effect(BUFF_POOL, rng, pulse_enabled)
		effects.append(primary_effect)
		if rng.randf() < 0.55:
			var penalty: Dictionary = DEBUFF_POOL[rng.randi_range(0, DEBUFF_POOL.size() - 1)]
			effects.append(penalty.duplicate(true))
		elif rng.randf() < 0.35:
			effects.append(_pick_effect(BUFF_POOL, rng, pulse_enabled))
		result["display_text"] = _join_effect_texts(effects)
	else:
		for effect in Array(definition.get("effects", [])):
			effects.append(Dictionary(effect).duplicate(true))
	result["resolved_effects"] = effects
	return result


static func describe_effects(effects: Array[Dictionary]) -> String:
	return _join_effect_texts(effects)


static func _pick_effect(pool: Array, rng: RandomNumberGenerator, pulse_enabled: bool) -> Dictionary:
	var filtered: Array[Dictionary] = []
	for effect in pool:
		var item: Dictionary = Dictionary(effect)
		if not pulse_enabled and String(item.get("tag", "")) == "pulse":
			filtered.append({
				"type": "unlock_pulse",
				"amount": 1.0,
				"text": "解锁脉冲"
			})
			continue
		filtered.append(item.duplicate(true))
	var index: int = rng.randi_range(0, filtered.size() - 1)
	return filtered[index].duplicate(true)


static func _join_effect_texts(effects: Array[Dictionary]) -> String:
	var parts: Array[String] = []
	for effect in effects:
		parts.append(String(effect.get("text", "")))
	return "，".join(parts)
