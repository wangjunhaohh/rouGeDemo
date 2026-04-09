extends Control
class_name ResultPanel

signal restart_requested
signal meta_upgrade_requested(upgrade_id: String)

@onready var title_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var summary_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/SummaryLabel
@onready var shard_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/ShardLabel
@onready var upgrades_grid: GridContainer = $CenterContainer/Panel/MarginContainer/VBoxContainer/MetaUpgrades

var upgrade_buttons: Array[Button] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	hide()
	$CenterContainer/Panel/MarginContainer/VBoxContainer/RestartButton.pressed.connect(_on_restart_pressed)
	for child in upgrades_grid.get_children():
		if child is Button:
			var button: Button = child as Button
			_bind_upgrade_button(button)
			upgrade_buttons.append(button)


func show_result(title_text: String, summary_text: String, shard_total: int, shard_gain: int, upgrade_models: Array[Dictionary]) -> void:
	title_label.text = title_text
	summary_label.text = summary_text
	shard_label.text = "暗核碎片 %d  （本局 +%d）" % [shard_total, shard_gain]
	_ensure_upgrade_button_count(upgrade_models.size())
	for index in range(upgrade_buttons.size()):
		var button: Button = upgrade_buttons[index]
		if index >= upgrade_models.size():
			button.visible = false
			continue
		var model: Dictionary = upgrade_models[index]
		var locked_reason: String = String(model.get("locked_reason", ""))
		var level_text: String = "Lv.%d/%d" % [int(model["level"]), int(model["max_level"])]
		var cost_text: String = "花费 %d" % int(model["cost"])
		if int(model["level"]) >= int(model["max_level"]):
			cost_text = "已满级"
		elif not locked_reason.is_empty():
			cost_text = locked_reason
		button.visible = true
		button.disabled = not bool(model["can_buy"])
		button.set_meta("upgrade_id", String(model["id"]))
		button.text = "%s\n%s\n%s  %s" % [
			model["name"],
			model["description"],
			level_text,
			cost_text
		]
	show()


func hide_panel() -> void:
	hide()


func _on_restart_pressed() -> void:
	restart_requested.emit()


func _ensure_upgrade_button_count(required_count: int) -> void:
	while upgrade_buttons.size() < required_count:
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(0.0, 92.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		_bind_upgrade_button(button)
		upgrades_grid.add_child(button)
		upgrade_buttons.append(button)


func _bind_upgrade_button(button: Button) -> void:
	button.pressed.connect(_on_meta_button_pressed.bind(button))


func _on_meta_button_pressed(button: Button) -> void:
	var upgrade_id: String = String(button.get_meta("upgrade_id", ""))
	if upgrade_id.is_empty():
		return
	meta_upgrade_requested.emit(upgrade_id)
