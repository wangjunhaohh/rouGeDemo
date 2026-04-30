extends RefCounted
class_name ContentCatalog

const ENEMY_DEFINITIONS := [
	preload("res://resources/enemies/slime.tres"),
	preload("res://resources/enemies/bat.tres"),
	preload("res://resources/enemies/skeleton.tres"),
	preload("res://resources/enemies/goblin.tres"),
	preload("res://resources/enemies/mushroom.tres"),
	preload("res://resources/enemies/ghost.tres"),
	preload("res://resources/enemies/imp.tres"),
	preload("res://resources/enemies/demon.tres"),
	preload("res://resources/enemies/boss.tres")
]

const UPGRADE_DEFINITIONS := [
	preload("res://resources/upgrades/power_shot.tres"),
	preload("res://resources/upgrades/vitality.tres"),
	preload("res://resources/upgrades/battle_boots.tres"),
	preload("res://resources/upgrades/critical_focus.tres"),
	preload("res://resources/upgrades/ashen_mark.tres"),
	preload("res://resources/upgrades/acid_etching.tres"),
	preload("res://resources/upgrades/bulwark_stride.tres"),
	preload("res://resources/upgrades/binding_hex.tres"),
	preload("res://resources/upgrades/calamity_vector.tres"),
	preload("res://resources/upgrades/cinder_field.tres"),
	preload("res://resources/upgrades/ember_chain.tres"),
	preload("res://resources/upgrades/fortress_plating.tres"),
	preload("res://resources/upgrades/hammer_slam.tres"),
	preload("res://resources/upgrades/infection_wake.tres"),
	preload("res://resources/upgrades/iron_reverb.tres"),
	preload("res://resources/upgrades/last_stand.tres"),
	preload("res://resources/upgrades/plague_capsule.tres"),
	preload("res://resources/upgrades/relay_beacon.tres"),
	preload("res://resources/upgrades/scorching_payload.tres"),
	preload("res://resources/upgrades/sentry_array.tres"),
	preload("res://resources/upgrades/sentry_overclock.tres"),
	preload("res://resources/upgrades/shadow_brand.tres"),
	preload("res://resources/upgrades/shield_breaker.tres"),
	preload("res://resources/upgrades/spiked_armor.tres"),
	preload("res://resources/upgrades/tower_guard.tres"),
	preload("res://resources/upgrades/unyielding_core.tres"),
	preload("res://resources/upgrades/vanguard_edge.tres"),
	preload("res://resources/upgrades/venom_reservoir.tres")
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
