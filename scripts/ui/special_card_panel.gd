extends Control
class_name SpecialCardPanel

signal card_selected(index: int)

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


func present(cards: Array[Dictionary], prompt_text: String) -> void:
	title_label.text = "特殊技能卡"
	subtitle_label.text = prompt_text
	show()
	for index in range(_buttons.size()):
		var button: Button = _buttons[index]
		if index >= cards.size():
			button.disabled = true
			button.visible = false
			continue
		var card: Dictionary = cards[index]
		button.visible = true
		button.disabled = false
		button.icon = card.get("icon") as Texture2D
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.text = "%s  [%s / %s]\n%s" % [
			String(card.get("name", "")),
			String(card.get("type", "")),
			String(card.get("rarity", "")),
			String(card.get("display_text", ""))
		]


func hide_panel() -> void:
	hide()


func _on_button_pressed(index: int) -> void:
	card_selected.emit(index)
