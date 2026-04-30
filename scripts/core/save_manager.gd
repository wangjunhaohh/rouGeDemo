extends RefCounted
class_name SaveManager

const SAVE_VERSION := 1
const SETTINGS_VERSION := 1
const RUN_RECORD_VERSION := 1
const SAVE_PATH := "user://save_data.json"
const SETTINGS_PATH := "user://settings.json"
const RUN_RECORD_PATH := "user://run_records.json"
const LEGACY_META_PATH := "user://meta_progression.save"
const MAX_RUN_RECORDS := 80
const MAX_OFFLINE_SECONDS := 28800.0
const DEFAULT_PLAYER_ID := "local_player"


static func load_progression_state() -> Dictionary:
	var data := load_or_create_save()
	return {
		"shards": int(Dictionary(data.get("currencies", {})).get("shards", 0)),
		"upgrades": Dictionary(data.get("global_upgrades", {})).duplicate(true),
		"character_upgrades": Dictionary(data.get("character_upgrades", {})).duplicate(true),
		"offline_reward_shards": int(Dictionary(data.get("idle", {})).get("last_offline_reward_shards", 0))
	}


static func save_progression_state(shards: int, upgrades: Dictionary, character_upgrades: Dictionary) -> void:
	var data := load_or_create_save()
	var currencies: Dictionary = Dictionary(data.get("currencies", {}))
	currencies["shards"] = maxi(shards, 0)
	data["currencies"] = currencies
	data["global_upgrades"] = upgrades.duplicate(true)
	data["character_upgrades"] = character_upgrades.duplicate(true)
	_update_last_offline_time(data)
	save_data(data)


static func load_or_create_save() -> Dictionary:
	_ensure_settings_file()
	var data := _load_json(SAVE_PATH)
	if data.is_empty():
		data = DatabaseManager.load_player_save()
	if data.is_empty():
		data = _default_save_data()
		_apply_legacy_meta_progression(data)
		save_data(data)
		return data

	data = _sanitize_save_data(_migrate_save_data(data))
	_claim_offline_rewards(data)
	save_data(data)
	return data


static func save_data(data: Dictionary) -> void:
	var sanitized := _sanitize_save_data(data)
	_save_json(SAVE_PATH, sanitized)
	DatabaseManager.upsert_player_save(sanitized, String(sanitized.get("player_id", DEFAULT_PLAYER_ID)))


static func load_settings() -> Dictionary:
	var settings := _load_json(SETTINGS_PATH)
	if settings.is_empty():
		settings = _default_settings()
		_save_json(SETTINGS_PATH, settings)
		DatabaseManager.upsert_player_settings(settings)
		return settings
	var sanitized := _sanitize_settings(settings)
	_save_json(SETTINGS_PATH, sanitized)
	DatabaseManager.upsert_player_settings(sanitized)
	return sanitized


static func save_settings(settings: Dictionary) -> void:
	var sanitized := _sanitize_settings(settings)
	_save_json(SETTINGS_PATH, sanitized)
	DatabaseManager.upsert_player_settings(sanitized)


static func record_run(run_record: Dictionary) -> void:
	var data := _load_json(RUN_RECORD_PATH)
	if data.is_empty():
		data = {
			"version": RUN_RECORD_VERSION,
			"records": []
		}
	var records: Array = Array(data.get("records", []))
	var sanitized_record := run_record.duplicate(true)
	if String(sanitized_record.get("run_id", "")).is_empty():
		sanitized_record["run_id"] = "run_%d" % int(Time.get_unix_time_from_system() * 1000.0)
	sanitized_record["recorded_at"] = int(Time.get_unix_time_from_system())
	records.append(sanitized_record)
	while records.size() > MAX_RUN_RECORDS:
		records.pop_front()
	data["version"] = RUN_RECORD_VERSION
	data["records"] = records
	_save_json(RUN_RECORD_PATH, data)
	DatabaseManager.insert_run_record(sanitized_record)


static func _default_save_data() -> Dictionary:
	var now := int(Time.get_unix_time_from_system())
	return {
		"version": SAVE_VERSION,
		"player_id": DEFAULT_PLAYER_ID,
		"currencies": {
			"shards": 0,
			"gold": 0,
			"experience": 0,
			"materials": 0,
			"talent_points": 0
		},
		"unlocks": {
			"characters": ["swordsman", "mage"],
			"weapons": [],
			"branches": ["tank", "debuff", "building"],
			"upgrade_cards": [],
			"maps": ["cold_street"]
		},
		"characters": {
			"swordsman": _default_character_progress(true),
			"mage": _default_character_progress(true)
		},
		"global_upgrades": {},
		"character_upgrades": {},
		"base": {
			"level": 1,
			"buildings": {},
			"research": {}
		},
		"idle": {
			"idle_reward_level": 0,
			"last_offline_time": now,
			"max_offline_seconds": MAX_OFFLINE_SECONDS,
			"last_offline_seconds": 0.0,
			"last_offline_reward_shards": 0
		},
		"preferences": {
			"last_character_id": "swordsman",
			"last_branch_id": "tank"
		}
	}


static func _default_character_progress(unlocked: bool) -> Dictionary:
	return {
		"unlocked": unlocked,
		"level": 1,
		"experience": 0,
		"mastery": 0,
		"exclusive_skill_upgrades": {}
	}


static func _default_settings() -> Dictionary:
	return {
		"version": SETTINGS_VERSION,
		"audio": {
			"master_volume": 1.0,
			"sfx_volume": 1.0,
			"music_volume": 1.0
		},
		"display": {
			"fullscreen": false,
			"pixel_snap": true
		},
		"gameplay": {
			"damage_numbers": true,
			"screen_shake": true
		}
	}


static func _sanitize_save_data(data: Dictionary) -> Dictionary:
	var sanitized := _default_save_data()
	_merge_dictionary(sanitized, data)
	sanitized["version"] = SAVE_VERSION
	if String(sanitized.get("player_id", "")).is_empty():
		sanitized["player_id"] = DEFAULT_PLAYER_ID
	var currencies: Dictionary = Dictionary(sanitized.get("currencies", {}))
	for currency_id in currencies.keys():
		currencies[currency_id] = maxi(int(currencies[currency_id]), 0)
	sanitized["currencies"] = currencies
	_ensure_character_progress(sanitized, "swordsman")
	_ensure_character_progress(sanitized, "mage")
	return sanitized


static func _sanitize_settings(settings: Dictionary) -> Dictionary:
	var sanitized := _default_settings()
	_merge_dictionary(sanitized, settings)
	sanitized["version"] = SETTINGS_VERSION
	return sanitized


static func _migrate_save_data(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	var version := int(migrated.get("version", 0))
	if version <= 0:
		migrated["version"] = SAVE_VERSION
	return migrated


static func _apply_legacy_meta_progression(data: Dictionary) -> void:
	var legacy := _load_json(LEGACY_META_PATH)
	if legacy.is_empty():
		return
	var currencies: Dictionary = Dictionary(data.get("currencies", {}))
	currencies["shards"] = int(legacy.get("shards", currencies.get("shards", 0)))
	data["currencies"] = currencies
	data["global_upgrades"] = Dictionary(legacy.get("upgrades", {})).duplicate(true)
	data["character_upgrades"] = Dictionary(legacy.get("character_upgrades", {})).duplicate(true)


static func _claim_offline_rewards(data: Dictionary) -> void:
	var idle: Dictionary = Dictionary(data.get("idle", {}))
	var now := float(Time.get_unix_time_from_system())
	var last_time := float(idle.get("last_offline_time", now))
	var max_seconds := float(idle.get("max_offline_seconds", MAX_OFFLINE_SECONDS))
	var offline_seconds := clampf(now - last_time, 0.0, max_seconds)
	var reward_level := int(idle.get("idle_reward_level", 0))
	var reward_shards := int(floorf(offline_seconds / 600.0)) * reward_level
	if reward_shards > 0:
		var currencies: Dictionary = Dictionary(data.get("currencies", {}))
		currencies["shards"] = int(currencies.get("shards", 0)) + reward_shards
		data["currencies"] = currencies
	idle["last_offline_time"] = int(now)
	idle["last_offline_seconds"] = offline_seconds
	idle["last_offline_reward_shards"] = reward_shards
	data["idle"] = idle


static func _update_last_offline_time(data: Dictionary) -> void:
	var idle: Dictionary = Dictionary(data.get("idle", {}))
	idle["last_offline_time"] = int(Time.get_unix_time_from_system())
	data["idle"] = idle


static func _ensure_settings_file() -> void:
	if FileAccess.file_exists(SETTINGS_PATH):
		load_settings()
		return
	var settings := _default_settings()
	_save_json(SETTINGS_PATH, settings)
	DatabaseManager.upsert_player_settings(settings)


static func _ensure_character_progress(data: Dictionary, character_id: String) -> void:
	var characters: Dictionary = Dictionary(data.get("characters", {}))
	var progress: Dictionary = Dictionary(characters.get(character_id, {}))
	var defaults := _default_character_progress(true)
	_merge_dictionary(defaults, progress)
	characters[character_id] = defaults
	data["characters"] = characters


static func _merge_dictionary(target: Dictionary, source: Dictionary) -> void:
	for key in source.keys():
		var source_value: Variant = source[key]
		if target.has(key) and typeof(target[key]) == TYPE_DICTIONARY and typeof(source_value) == TYPE_DICTIONARY:
			var target_dictionary: Dictionary = Dictionary(target[key])
			_merge_dictionary(target_dictionary, Dictionary(source_value))
			target[key] = target_dictionary
		else:
			target[key] = source_value


static func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return Dictionary(parsed)
	push_warning("SaveManager failed to parse %s, fallback to defaults." % path)
	return {}


static func _save_json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("SaveManager failed to write %s." % path)
		return
	file.store_string(JSON.stringify(data, "\t"))
