extends Node2D

@onready var visual: Sprite2D = $Visual


func _ready() -> void:
	visual.z_as_relative = false
	visual.z_index = int(round(global_position.y))
