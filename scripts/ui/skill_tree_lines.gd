extends Control
class_name SkillTreeLines

var _node_positions: Dictionary = {}
var _connections: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_graph(node_positions: Dictionary, connections: Array[Dictionary]) -> void:
	_node_positions = node_positions.duplicate(true)
	_connections = connections.duplicate(true)
	queue_redraw()


func _draw() -> void:
	for connection in _connections:
		var from_id: String = String(connection.get("from", ""))
		var to_id: String = String(connection.get("to", ""))
		if not _node_positions.has(from_id) or not _node_positions.has(to_id):
			continue
		var from_position: Vector2 = _node_positions[from_id]
		var to_position: Vector2 = _node_positions[to_id]
		draw_line(from_position, to_position, Color(0.62, 0.84, 1.0, 0.34), 4.0, true)
		draw_line(from_position, to_position, Color(0.95, 0.76, 0.32, 0.5), 1.5, true)
