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


func present(options: Array, levels: Dictionary) -> void:
	title_label.text = "等级提升"
	subtitle_label.text = "选择一个即时生效的成长项"
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
		button.text = "%s\n%s\nLv.%d/%d" % [
			upgrade.display_name,
			upgrade.description,
			current_level + 1,
			upgrade.max_level
		]


func hide_panel() -> void:
	hide()


func _on_button_pressed(index: int) -> void:
	option_selected.emit(index)
