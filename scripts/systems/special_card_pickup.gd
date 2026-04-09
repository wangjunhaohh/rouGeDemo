extends Area2D
class_name SpecialCardPickup

signal picked_up(pickup: SpecialCardPickup)

var bob_time := 0.0

@onready var visual: Sprite2D = $Visual
@onready var glow: Sprite2D = $Glow


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	glow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.texture = preload("res://art/sprites/card_pickup.png")
	glow.texture = preload("res://art/sprites/card_unknown.png")
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	bob_time += delta
	visual.position.y = sin(bob_time * 3.2) * 4.0
	glow.position.y = visual.position.y
	glow.modulate.a = 0.42 + sin(bob_time * 4.8) * 0.18
	glow.rotation = bob_time * 0.6


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	picked_up.emit(self)
