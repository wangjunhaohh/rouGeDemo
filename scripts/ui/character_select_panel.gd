extends Control
class_name CharacterSelectPanel

signal character_selected(index: int)

var _buttons: Array[Button] = []

@onready var title_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/SubTitleLabel
@onready var panel: PanelContainer = $CenterContainer/Panel
@onready var backdrop: ColorRect = $Backdrop


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	hide()
	InkUIStyle.apply_panel(panel)
	InkUIStyle.apply_label_colors(title_label, subtitle_label)
	backdrop.color = Color(0.01, 0.015, 0.014, 0.72)
	_buttons = [
		$CenterContainer/Panel/MarginContainer/VBoxContainer/Options/OptionA,
		$CenterContainer/Panel/MarginContainer/VBoxContainer/Options/OptionB,
		$CenterContainer/Panel/MarginContainer/VBoxContainer/Options/OptionC
	]
	for index in range(_buttons.size()):
		_buttons[index].pressed.connect(_on_button_pressed.bind(index))
		_buttons[index].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_buttons[index].alignment = HORIZONTAL_ALIGNMENT_CENTER
		InkUIStyle.apply_character_button(_buttons[index])


func present(characters: Array[Dictionary]) -> void:
	title_label.text = "选择出战人物"
	subtitle_label.text = "人物决定基础攻击、专属技能和初始节奏，随后选择本局主分支。"
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
		button.text = "%s\n%s\n专属：%s\n推荐：%s" % [
			String(character.get("name", "")),
			String(character.get("role", "")),
			String(skill.get("name", "")),
			recommended
		]
		button.tooltip_text = String(character.get("weakness", ""))


func hide_panel() -> void:
	hide()


func _on_button_pressed(index: int) -> void:
	character_selected.emit(index)
