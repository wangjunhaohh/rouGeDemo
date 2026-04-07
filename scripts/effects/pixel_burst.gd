extends Node2D
class_name PixelBurst

var color := Color(1, 1, 1, 1)
var duration := 0.28
var particle_count := 10
var spread := 110.0
var size := 4.0

var _elapsed := 0.0
var _particles: Array[Dictionary] = []


func _ready() -> void:
	randomize()
	for _i in range(particle_count):
		var direction := Vector2.RIGHT.rotated(randf() * TAU)
		_particles.append({
			"velocity": direction * randf_range(spread * 0.55, spread),
			"offset": Vector2.ZERO,
			"size": randf_range(size * 0.7, size * 1.25)
		})


func setup(burst_color: Color, burst_size: float, burst_count: int, burst_duration: float, burst_spread: float) -> void:
	color = burst_color
	size = burst_size
	particle_count = burst_count
	duration = burst_duration
	spread = burst_spread


func _process(delta: float) -> void:
	_elapsed += delta
	var progress := minf(_elapsed / duration, 1.0)
	for index in range(_particles.size()):
		var particle: Dictionary = _particles[index]
		particle["offset"] += particle["velocity"] * delta
		_particles[index] = particle
	queue_redraw()
	if progress >= 1.0:
		queue_free()


func _draw() -> void:
	var progress := minf(_elapsed / duration, 1.0)
	for particle in _particles:
		var particle_size: float = particle["size"]
		var alpha := 1.0 - progress
		var draw_color := color
		draw_color.a = alpha
		var rect := Rect2(particle["offset"], Vector2.ONE * particle_size)
		draw_rect(rect, draw_color, true)
