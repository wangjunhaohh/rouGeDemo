extends Control
class_name HomePanel

signal start_requested
signal character_upgrade_requested(character_id: String, upgrade_id: String)

const TREE_NODE_SIZE := Vector2(176.0, 88.0)

var _characters: Array[Dictionary] = []
var _meta_progression: MetaProgression
var _selected_character_id := ""
var _character_buttons: Array[Button] = []
var _tree_buttons: Array[Button] = []

@onready var title_label: Label = $MarginContainer/Root/TopRow/TitleBox/TitleLabel
@onready var subtitle_label: Label = $MarginContainer/Root/TopRow/TitleBox/SubTitleLabel
@onready var shard_label: Label = $MarginContainer/Root/TopRow/ActionBox/ShardLabel
@onready var start_button: Button = $MarginContainer/Root/TopRow/ActionBox/StartButton
@onready var character_list: VBoxContainer = $MarginContainer/Root/Content/CharacterPanel/MarginContainer/VBoxContainer/CharacterList
@onready var tree_title_label: Label = $MarginContainer/Root/Content/TreePanel/MarginContainer/VBoxContainer/TreeTitleLabel
@onready var tree_detail_label: Label = $MarginContainer/Root/Content/TreePanel/MarginContainer/VBoxContainer/TreeDetailLabel
@onready var tree_canvas: Control = $MarginContainer/Root/Content/TreePanel/MarginContainer/VBoxContainer/SkillTreeCanvas
@onready var tree_lines: SkillTreeLines = $MarginContainer/Root/Content/TreePanel/MarginContainer/VBoxContainer/SkillTreeCanvas/TreeLines


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	hide()
	start_button.pressed.connect(func() -> void: start_requested.emit())


func present(characters: Array[Dictionary], meta_progression: MetaProgression, game_title: String) -> void:
	_characters = characters.duplicate(true)
	_meta_progression = meta_progression
	if _selected_character_id.is_empty() and not _characters.is_empty():
		_selected_character_id = String(_characters[0].get("id", ""))
	title_label.text = game_title
	subtitle_label.text = "暗街、余烬、碎片与未完成的轮回"
	show()
	_refresh()


func refresh(meta_progression: MetaProgression) -> void:
	_meta_progression = meta_progression
	_refresh()


func hide_panel() -> void:
	hide()


func _refresh() -> void:
	if _meta_progression == null:
		return
	shard_label.text = "暗核碎片 %d" % _meta_progression.shards
	_refresh_character_buttons()
	call_deferred("_render_selected_tree")


func _refresh_character_buttons() -> void:
	for button in _character_buttons:
		if button.get_parent() != null:
			button.get_parent().remove_child(button)
		button.queue_free()
	_character_buttons.clear()

	for character in _characters:
		var character_id: String = String(character.get("id", ""))
		var button := Button.new()
		button.custom_minimum_size = Vector2(0.0, 104.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 16)
		button.text = _format_character_button_text(character, character_id)
		button.pressed.connect(_select_character.bind(character_id))
		character_list.add_child(button)
		_character_buttons.append(button)


func _format_character_button_text(character: Dictionary, character_id: String) -> String:
	var selected_text := "已选" if character_id == _selected_character_id else "人物"
	var total_level := _meta_progression.get_character_total_level(character_id)
	return "%s  %s\n%s\n成长投入 Lv.%d" % [
		selected_text,
		String(character.get("name", "")),
		String(character.get("role", "")),
		total_level
	]


func _select_character(character_id: String) -> void:
	_selected_character_id = character_id
	_refresh()


func _render_selected_tree() -> void:
	if _meta_progression == null or _selected_character_id.is_empty():
		return
	for button in _tree_buttons:
		if button.get_parent() != null:
			button.get_parent().remove_child(button)
		button.queue_free()
	_tree_buttons.clear()

	var character := _get_selected_character()
	var skill := CharacterCatalog.get_skill_definition(String(character.get("exclusive_skill_id", "")))
	tree_title_label.text = "%s 技能树" % String(character.get("name", ""))
	tree_detail_label.text = "%s | 专属：%s | 已投入 Lv.%d" % [
		String(character.get("role", "")),
		String(skill.get("name", "")),
		_meta_progression.get_character_total_level(_selected_character_id)
	]

	var models: Array[Dictionary] = _meta_progression.build_character_upgrade_view_models(_selected_character_id)
	var canvas_size := tree_canvas.size
	if canvas_size.x <= 1.0 or canvas_size.y <= 1.0:
		canvas_size = tree_canvas.custom_minimum_size

	var node_positions: Dictionary = {}
	var connections: Array[Dictionary] = []
	for model in models:
		var upgrade_id: String = String(model.get("id", ""))
		var normalized_position: Vector2 = model.get("position", Vector2(0.5, 0.5))
		var center_position := Vector2(
			lerpf(TREE_NODE_SIZE.x * 0.55, canvas_size.x - TREE_NODE_SIZE.x * 0.55, normalized_position.x),
			lerpf(TREE_NODE_SIZE.y * 0.6, canvas_size.y - TREE_NODE_SIZE.y * 0.6, normalized_position.y)
		)
		node_positions[upgrade_id] = center_position
		var requires: Dictionary = Dictionary(model.get("requires", {}))
		for required_id in requires.keys():
			connections.append({"from": String(required_id), "to": upgrade_id})

	for model in models:
		_add_tree_button(model, node_positions[String(model.get("id", ""))])
	tree_lines.set_graph(node_positions, connections)


func _add_tree_button(model: Dictionary, center_position: Vector2) -> void:
	var button := Button.new()
	button.position = center_position - TREE_NODE_SIZE * 0.5
	button.size = TREE_NODE_SIZE
	button.custom_minimum_size = TREE_NODE_SIZE
	button.focus_mode = Control.FOCUS_NONE
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_font_size_override("font_size", 13)
	button.disabled = not bool(model.get("can_buy", false))
	button.text = _format_tree_button_text(model)
	var upgrade_id: String = String(model.get("id", ""))
	button.pressed.connect(func() -> void:
		character_upgrade_requested.emit(_selected_character_id, upgrade_id)
	)
	tree_canvas.add_child(button)
	_tree_buttons.append(button)


func _format_tree_button_text(model: Dictionary) -> String:
	var level := int(model.get("level", 0))
	var max_level := int(model.get("max_level", 0))
	var cost := int(model.get("cost", 0))
	var status_text := "花费 %d" % cost
	var locked_reason: String = String(model.get("locked_reason", ""))
	if level >= max_level:
		status_text = "已满级"
	elif not locked_reason.is_empty():
		status_text = locked_reason
	elif not bool(model.get("can_buy", false)):
		status_text = "碎片不足 %d" % cost
	return "%s\n%s\nLv.%d/%d  %s" % [
		String(model.get("name", "")),
		String(model.get("description", "")),
		level,
		max_level,
		status_text
	]


func _get_selected_character() -> Dictionary:
	for character in _characters:
		if String(character.get("id", "")) == _selected_character_id:
			return character
	return {}
