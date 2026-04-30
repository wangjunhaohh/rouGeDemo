extends Control
class_name CharacterSelectPanel

signal character_selected(index: int)

var _buttons: Array[Button] = []

@onready var title_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/SubTitleLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	hide()
	_buttons = [
		$CenterContainer/Panel/MarginContainer/VBoxContainer/Options/OptionA,
		$CenterContainer/Panel/MarginContainer/VBoxContainer/Options/OptionB,
		$CenterContainer/Panel/MarginContainer/VBoxContainer/Options/OptionC
	]
	for index in range(_buttons.size()):
		_buttons[index].pressed.connect(_on_button_pressed.bind(index))
		_buttons[index].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_buttons[index].alignment = HORIZONTAL_ALIGNMENT_CENTER


func present(characters: Array[Dictionary]) -> void:
	title_label.text = "选择出战人物"
	subtitle_label.text = "人物决定基础属性和专属技能，随后仍可选择本局主分支。"
	show()
	for index in range(_buttons.size()):
		var button: Button = _buttons[index]
		if index >= characters.size():
			button.visible = false
			button.disabled = true
			continue
		var character: Dictionary = characters[index]
		var recommended := " / ".join(PackedStringArray(character.get("recommended_branches", PackedStringArray())))
		var skill: Dictionary = CharacterCatalog.get_skill_definition(String(character.get("exclusive_skill_id", "")))
		button.visible = true
		button.disabled = false
		button.text = "%s\n%s\n技能：%s\n推荐：%s\n弱点：%s" % [
			String(character.get("name", "")),
			String(character.get("role", "")),
			String(skill.get("name", "")),
			recommended,
			String(character.get("weakness", ""))
		]


func hide_panel() -> void:
	hide()


func _on_button_pressed(index: int) -> void:
	character_selected.emit(index)
