extends StaticBody2D
class_name ArenaObstacle

const OBSTACLE_LAYER := 4

var obstacle_id := ""
var obstacle_radius := 32.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Sprite2D = $Visual


func _ready() -> void:
	add_to_group("arena_obstacle")
	collision_layer = OBSTACLE_LAYER
	collision_mask = 0
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.centered = true


func setup(
	texture: Texture2D,
	collision_radius: float,
	visual_scale: Vector2 = Vector2.ONE,
	collision_offset: Vector2 = Vector2.ZERO,
	next_id: String = "",
	visual_z_index: int = 0
) -> void:
	obstacle_id = next_id
	obstacle_radius = collision_radius
	visual.texture = texture
	visual.scale = visual_scale
	visual.z_index = visual_z_index
	collision_shape.position = collision_offset
	var circle := collision_shape.shape as CircleShape2D
	if circle != null:
		circle.radius = collision_radius


func blocks_point(world_position: Vector2, padding: float = 0.0) -> bool:
	var collision_center: Vector2 = global_position + collision_shape.position
	return collision_center.distance_to(world_position) <= obstacle_radius + padding
