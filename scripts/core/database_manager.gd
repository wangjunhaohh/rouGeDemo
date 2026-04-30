extends RefCounted
class_name DatabaseManager

const DATABASE_VERSION := 1
const DATABASE_PATH := "user://local_database.json"
const DEFAULT_PLAYER_ID := "local_player"
const MAX_RUN_RECORDS := 300


static func load_player_save(player_id: String = DEFAULT_PLAYER_ID) -> Dictionary:
	var database := load_or_create_database()
	var rows: Dictionary = Dictionary(database.get("player_saves", {}))
	var row: Dictionary = Dictionary(rows.get(player_id, {}))
	return Dictionary(row.get("save_data", {})).duplicate(true)


static func upsert_player_save(save_data: Dictionary, player_id: String = DEFAULT_PLAYER_ID) -> void:
	var database := load_or_create_database()
	var rows: Dictionary = Dictionary(database.get("player_saves", {}))
	rows[player_id] = {
		"player_id": player_id,
		"save_version": int(save_data.get("version", 0)),
		"save_data": save_data.duplicate(true),
		"updated_at": int(Time.get_unix_time_from_system())
	}
	database["player_saves"] = rows
	_save_database(database)


static func upsert_player_settings(settings: Dictionary, player_id: String = DEFAULT_PLAYER_ID) -> void:
	var database := load_or_create_database()
	var rows: Dictionary = Dictionary(database.get("player_settings", {}))
	rows[player_id] = {
		"player_id": player_id,
		"settings_version": int(settings.get("version", 0)),
		"settings_data": settings.duplicate(true),
		"updated_at": int(Time.get_unix_time_from_system())
	}
	database["player_settings"] = rows
	_save_database(database)


static func insert_run_record(run_record: Dictionary, player_id: String = DEFAULT_PLAYER_ID) -> void:
	var database := load_or_create_database()
	var records: Array = Array(database.get("run_records", []))
	var row := {
		"run_id": String(run_record.get("run_id", "")),
		"player_id": player_id,
		"character_id": String(run_record.get("character_id", "")),
		"branch_id": String(run_record.get("branch_id", "")),
		"victory": bool(run_record.get("victory", false)),
		"elapsed_time": float(run_record.get("elapsed_time", 0.0)),
		"kills": int(run_record.get("kills", 0)),
		"level": int(run_record.get("level", 1)),
		"shard_gain": int(run_record.get("shard_gain", 0)),
		"record_data": run_record.duplicate(true),
		"created_at": int(Time.get_unix_time_from_system())
	}
	records.append(row)
	while records.size() > MAX_RUN_RECORDS:
		records.pop_front()
	database["run_records"] = records
	_save_database(database)


static func load_or_create_database() -> Dictionary:
	var database := _load_database()
	if database.is_empty():
		database = _default_database()
		_save_database(database)
		return database
	var sanitized := _sanitize_database(database)
	_save_database(sanitized)
	return sanitized


static func _default_database() -> Dictionary:
	return {
		"version": DATABASE_VERSION,
		"engine": "local_json_database",
		"player_saves": {},
		"player_settings": {},
		"run_records": []
	}


static func _sanitize_database(database: Dictionary) -> Dictionary:
	var sanitized := _default_database()
	_merge_dictionary(sanitized, database)
	sanitized["version"] = DATABASE_VERSION
	if typeof(sanitized.get("player_saves", {})) != TYPE_DICTIONARY:
		sanitized["player_saves"] = {}
	if typeof(sanitized.get("player_settings", {})) != TYPE_DICTIONARY:
		sanitized["player_settings"] = {}
	if typeof(sanitized.get("run_records", [])) != TYPE_ARRAY:
		sanitized["run_records"] = []
	var records: Array = Array(sanitized["run_records"])
	while records.size() > MAX_RUN_RECORDS:
		records.pop_front()
	sanitized["run_records"] = records
	return sanitized


static func _merge_dictionary(target: Dictionary, source: Dictionary) -> void:
	for key in source.keys():
		var source_value: Variant = source[key]
		if target.has(key) and typeof(target[key]) == TYPE_DICTIONARY and typeof(source_value) == TYPE_DICTIONARY:
			var target_dictionary: Dictionary = Dictionary(target[key])
			_merge_dictionary(target_dictionary, Dictionary(source_value))
			target[key] = target_dictionary
		else:
			target[key] = source_value


static func _load_database() -> Dictionary:
	if not FileAccess.file_exists(DATABASE_PATH):
		return {}
	var file := FileAccess.open(DATABASE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return Dictionary(parsed)
	push_warning("DatabaseManager failed to parse %s, fallback to empty database." % DATABASE_PATH)
	return {}


static func _save_database(database: Dictionary) -> void:
	var file := FileAccess.open(DATABASE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("DatabaseManager failed to write %s." % DATABASE_PATH)
		return
	file.store_string(JSON.stringify(database, "\t"))
