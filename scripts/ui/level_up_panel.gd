extends Control
class_name LevelUpPanel

signal option_selected(index: int)

var _buttons: Array[Button] = []

@onready var title_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/SubtitleLabel


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


func present(options: Array, levels: Dictionary, branch_name: String = "") -> void:
	title_label.text = "等级提升"
	subtitle_label.text = "选择一个即时生效的成长项：前两张偏向当前流派，第三张偏向通用成长"
	if not branch_name.is_empty():
		subtitle_label.text += " | 当前流派：%s" % branch_name
	show()
	for index in range(_buttons.size()):
		var button: Button = _buttons[index]
		if index >= options.size():
			button.disabled = true
			button.text = "无可用升级"
			continue
		var upgrade: UpgradeData = options[index]
		var current_level: int = int(levels.get(upgrade.upgrade_id, 0))
		button.disabled = false
		button.text = _format_upgrade_text(upgrade, current_level, branch_name)


func hide_panel() -> void:
	hide()


func _on_button_pressed(index: int) -> void:
	option_selected.emit(index)


func _format_upgrade_text(upgrade: UpgradeData, current_level: int, branch_name: String) -> String:
	var type_label := _get_upgrade_type_label(upgrade, branch_name)
	return "%s\n%s\n\n%s\n\nLv.%d/%d" % [
		type_label,
		upgrade.display_name,
		upgrade.description,
		current_level + 1,
		upgrade.max_level
	]


func _get_upgrade_type_label(upgrade: UpgradeData, branch_name: String) -> String:
	if not upgrade.exclusive_branch.is_empty():
		if branch_name.is_empty():
			return "流派专属"
		return "%s专属" % branch_name
	return "通用成长"
