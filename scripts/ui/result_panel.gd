extends Control
class_name ResultPanel

signal restart_requested
signal meta_upgrade_requested(upgrade_id: String)

@onready var title_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var summary_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/SummaryLabel
@onready var shard_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/ShardLabel
@onready var upgrade_buttons: Dictionary = {
	"endurance": $CenterContainer/Panel/MarginContainer/VBoxContainer/MetaUpgrades/EnduranceButton,
	"drill": $CenterContainer/Panel/MarginContainer/VBoxContainer/MetaUpgrades/DrillButton,
	"magnet": $CenterContainer/Panel/MarginContainer/VBoxContainer/MetaUpgrades/MagnetButton,
	"stride": $CenterContainer/Panel/MarginContainer/VBoxContainer/MetaUpgrades/StrideButton
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	hide()
	$CenterContainer/Panel/MarginContainer/VBoxContainer/RestartButton.pressed.connect(_on_restart_pressed)
	for upgrade_id in upgrade_buttons.keys():
		var button: Button = upgrade_buttons[upgrade_id] as Button
		button.pressed.connect(_on_meta_button_pressed.bind(upgrade_id))


func show_result(title_text: String, summary_text: String, shard_total: int, shard_gain: int, upgrade_models: Array[Dictionary]) -> void:
	title_label.text = title_text
	summary_label.text = summary_text
	shard_label.text = "暗核碎片 %d  （本局 +%d）" % [shard_total, shard_gain]
	for model in upgrade_models:
		var button: Button = upgrade_buttons.get(String(model["id"])) as Button
		if button == null:
			continue
		button.disabled = not bool(model["can_buy"])
		button.text = "%s\n%s\nLv.%d/%d  花费 %d" % [
			model["name"],
			model["description"],
			int(model["level"]),
			int(model["max_level"]),
			int(model["cost"])
		]
	show()


func hide_panel() -> void:
	hide()


func _on_restart_pressed() -> void:
	restart_requested.emit()


func _on_meta_button_pressed(upgrade_id: String) -> void:
	meta_upgrade_requested.emit(upgrade_id)
