extends Area2D
class_name ExperienceOrb

signal collected(amount: int)

var amount := 5
var travel_speed := 120.0
var target: Node2D

@onready var visual: Sprite2D = $Visual


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.texture = load("res://art/sprites/experience_orb.png") as Texture2D
	body_entered.connect(_on_body_entered)


func setup(experience_amount: int, target_player: Node2D) -> void:
	amount = experience_amount
	target = target_player


func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return

	var to_target := target.global_position - global_position
	var distance := to_target.length()
	var pickup_radius: float = 96.0
	if target.has_method("get_pickup_radius"):
		pickup_radius = float(target.get_pickup_radius())

	if distance <= maxf(160.0, pickup_radius * 2.2):
		travel_speed = minf(travel_speed + delta * 420.0, 540.0)
		global_position += to_target.normalized() * travel_speed * delta


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	collected.emit(amount)
	queue_free()
