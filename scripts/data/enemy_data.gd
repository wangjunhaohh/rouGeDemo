extends Resource
class_name EnemyData

@export var enemy_id := ""
@export var display_name := ""
@export var behavior := "chase"
@export var max_health := 30.0
@export var move_speed := 100.0
@export var touch_damage := 8.0
@export var experience_reward := 5
@export var size := 12.0
@export var spawn_weight := 1.0
@export var color := Color(0.9, 0.2, 0.2, 1.0)
@export var preferred_distance := 220.0
@export var projectile_cooldown := 2.0
@export var projectile_speed := 220.0
@export var projectile_damage := 8.0
