extends RefCounted
class_name BranchCatalog

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
			"name": "钢壁流",
			"summary": "高生命、近身稳压、容错更高",
			"description": "开局最大生命 +18，受到接触伤害 -18%。升级更偏向生存、机动和脉冲。",
			"accent_color": Color(0.9, 0.74, 0.42, 1.0),
			"weapon_tint": Color(0.96, 0.84, 0.58, 1.0),
			"flash_color": Color(1.0, 0.9, 0.58, 1.0),
			"damage_taken_multiplier": 0.82,
			"starting_effects": [
				{"type": "max_health", "amount": 18.0}
			],
			"preferred_tags": PackedStringArray(["tank"]),
			"secondary_tags": PackedStringArray(["neutral", "building"])
		},
		{
			"id": "debuff",
			"name": "蚀火流",
			"summary": "命中附带燃烧，输出节奏更凶",
			"description": "主武器和脉冲可附加燃烧。升级更偏向伤害、冷却和穿透。",
			"accent_color": Color(0.95, 0.38, 0.26, 1.0),
			"weapon_tint": Color(0.96, 0.62, 0.42, 1.0),
			"flash_color": Color(1.0, 0.58, 0.34, 1.0),
			"burn_damage": 4.0,
			"burn_duration": 2.4,
			"preferred_tags": PackedStringArray(["debuff"]),
			"secondary_tags": PackedStringArray(["neutral", "building"])
		},
		{
			"id": "building",
			"name": "棱塔流",
			"summary": "每隔数次射击部署短命哨戒节点",
			"description": "每 6 次主武器射击会部署 1 个哨戒节点。升级更偏向射程、分裂和脉冲。",
			"accent_color": Color(0.42, 0.88, 0.96, 1.0),
			"weapon_tint": Color(0.56, 0.86, 0.96, 1.0),
			"flash_color": Color(0.58, 0.95, 1.0, 1.0),
			"sentry_shot_interval": 6,
			"preferred_tags": PackedStringArray(["building"]),
			"secondary_tags": PackedStringArray(["neutral", "tank"])
		}
	]


static func get_branch_name(branch_id: String) -> String:
	var definition: Dictionary = get_branch_definition(branch_id)
	return String(definition.get("name", "未定分支"))


static func has_branch_tag(upgrade: UpgradeData, branch_id: String) -> bool:
	for tag in upgrade.tags:
		if String(tag) == branch_id:
			return true
	return false


static func is_neutral(upgrade: UpgradeData) -> bool:
	for tag in upgrade.tags:
		if String(tag) == "neutral":
			return true
	return false


static func get_branch_weight_multiplier(upgrade: UpgradeData, branch_id: String, primary_pick: bool) -> float:
	if branch_id.is_empty():
		return 1.0

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
