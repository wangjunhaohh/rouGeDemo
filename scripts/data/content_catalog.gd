extends RefCounted
class_name ContentCatalog

const ENEMY_DEFINITIONS := [
	preload("res://resources/enemies/runner.tres"),
	preload("res://resources/enemies/brute.tres"),
	preload("res://resources/enemies/shooter.tres"),
	preload("res://resources/enemies/boss.tres")
]

const UPGRADE_DEFINITIONS := [
	preload("res://resources/upgrades/battle_boots.tres"),
	preload("res://resources/upgrades/long_range.tres"),
	preload("res://resources/upgrades/piercing_round.tres"),
	preload("res://resources/upgrades/power_shot.tres"),
	preload("res://resources/upgrades/pulse_core.tres"),
	preload("res://resources/upgrades/pulse_drive.tres"),
	preload("res://resources/upgrades/pulse_emitter.tres"),
	preload("res://resources/upgrades/rapid_fire.tres"),
	preload("res://resources/upgrades/split_round.tres"),
	preload("res://resources/upgrades/vitality.tres")
]


static func get_enemy_definitions() -> Array[EnemyData]:
	var items: Array[EnemyData] = []
	for definition in ENEMY_DEFINITIONS:
		var enemy_data: EnemyData = definition as EnemyData
		if enemy_data != null:
			items.append(enemy_data)
	return items


static func get_upgrade_definitions() -> Array[UpgradeData]:
	var items: Array[UpgradeData] = []
	for definition in UPGRADE_DEFINITIONS:
		var upgrade_data: UpgradeData = definition as UpgradeData
		if upgrade_data != null:
			items.append(upgrade_data)
	return items
