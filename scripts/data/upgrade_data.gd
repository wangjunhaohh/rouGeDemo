extends Resource
class_name UpgradeData

@export var upgrade_id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var rarity_weight := 1.0
@export var max_level := 1
@export var tags: PackedStringArray = PackedStringArray(["neutral"])
@export var exclusive_branch := ""
@export var synergy_tags: PackedStringArray = PackedStringArray()
@export var effect_type := ""
@export var amount := 0.0
@export var secondary_effect_type := ""
@export var secondary_amount := 0.0
