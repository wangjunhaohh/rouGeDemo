extends RefCounted
class_name MetaProgression

const SAVE_PATH := "user://meta_progression.save"
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
	}
}

var shards: int = 0
var upgrades: Dictionary = {}


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
	return profile


func save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"shards": shards,
		"upgrades": upgrades
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
	return shards >= get_cost(upgrade_id)


func purchase(upgrade_id: String) -> bool:
	if not can_purchase(upgrade_id):
		return false
	shards -= get_cost(upgrade_id)
	upgrades[upgrade_id] = get_level(upgrade_id) + 1
	save()
	return true


func apply_to_player(player: Player) -> void:
	for upgrade_id in upgrades.keys():
		var definition: Dictionary = DEFINITIONS.get(upgrade_id, {})
		var level := get_level(upgrade_id)
		for _i in range(level):
			player.apply_meta_bonus(String(definition.get("effect_type", "")), float(definition.get("amount", 0.0)))
	player.refresh_health_ui()


func build_upgrade_view_models() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	for upgrade_id in DEFINITIONS.keys():
		var definition: Dictionary = DEFINITIONS[upgrade_id]
		items.append({
			"id": upgrade_id,
			"name": definition["name"],
			"description": definition["description"],
			"level": get_level(upgrade_id),
			"max_level": int(definition["max_level"]),
			"cost": get_cost(upgrade_id),
			"can_buy": can_purchase(upgrade_id)
		})
	return items
