extends Control
class_name BranchSelectPanel

signal branch_selected(index: int)

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


func present(branches: Array[Dictionary]) -> void:
	title_label.text = "选择本局主分支"
	subtitle_label.text = "主分支会改变本局升级刷新倾向，并提供一个立刻生效的被动风格。"
	show()
	for index in range(_buttons.size()):
		var button: Button = _buttons[index]
		if index >= branches.size():
			button.visible = false
			button.disabled = true
			continue
		var branch: Dictionary = branches[index]
		button.visible = true
		button.disabled = false
		button.modulate = Color(branch.get("accent_color", Color(1.0, 1.0, 1.0, 1.0)))
		button.text = "%s\n%s\n%s" % [
			String(branch.get("name", "")),
			String(branch.get("summary", "")),
			String(branch.get("description", ""))
		]


func hide_panel() -> void:
	hide()


func _on_button_pressed(index: int) -> void:
	branch_selected.emit(index)
