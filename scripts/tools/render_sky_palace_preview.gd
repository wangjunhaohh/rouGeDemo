extends SceneTree

const MAP_SCENE_PATH := "res://scenes/maps/sky_palace_map.tscn"
const OUTPUT_PATH := "res://art/previews/sky_palace_current_step3.png"
const VIEWPORT_SIZE := Vector2i(1672, 941)

var _started := false
var _frames_after_start := 0
var _viewport: SubViewport


func _init() -> void:
	print("Sky palace preview script init")


func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		print("Starting sky palace preview render")
		_build_preview_viewport()
		return false
	_frames_after_start += 1
	if _frames_after_start >= 3:
		_save_preview()
		return true
	return false


func _build_preview_viewport() -> void:
	print("Building sky palace preview viewport")
	var viewport := SubViewport.new()
	viewport.size = VIEWPORT_SIZE
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	_viewport = viewport

	var stage := Node2D.new()
	stage.position = Vector2(VIEWPORT_SIZE) * 0.5
	viewport.add_child(stage)

	var map_scene := load(MAP_SCENE_PATH) as PackedScene
	if map_scene == null:
		push_error("Sky palace preview scene missing: %s" % MAP_SCENE_PATH)
		quit(1)
		return

	stage.add_child(map_scene.instantiate())


func _save_preview() -> void:
	var image := _viewport.get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	if error != OK:
		push_error("Failed to save sky palace preview: %s" % error)
		quit(1)
		return

	print("Saved sky palace preview: %s" % OUTPUT_PATH)
	_viewport.queue_free()
	quit()
