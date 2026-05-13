extends Control
class_name WendaoBeiPanel

signal back_requested

const BACKGROUND_TEXTURE := preload("res://art/backgrounds/wendao_bei_page.png")
const CATEGORY_LIST_TEXTURE := preload("res://art/ui/wendao_category_list_base.png")
const CATEGORY_SELECTED_TEXTURE := preload("res://art/ui/wendao_category_selected.png")
const TASK_ROW_NORMAL_TEXTURE := preload("res://art/ui/wendao_task_row_normal.png")
const TASK_ROW_SELECTED_TEXTURE := preload("res://art/ui/wendao_task_row_selected.png")
const SOURCE_HAN_SERIF_FONT := preload("res://art/fonts/NotoSerifSC-VF.ttf")
const TASK_ICON_TEXTURES := {
	"achievement_intro_qingxu": preload("res://art/ui/achievement_intro_qingxu.png"),
	"achievement_monster_01": preload("res://art/ui/achievement_monster_01.png"),
	"achievement_mountain_01": preload("res://art/ui/achievement_mountain_01.png"),
	"achievement_treasure_01": preload("res://art/ui/achievement_treasure_01.png"),
	"achievement_qi_01": preload("res://art/ui/achievement_qi_01.png"),
	"achievement_trial_01": preload("res://art/ui/achievement_trial_01.png"),
}
const DESIGN_SIZE := Vector2(1672.0, 941.0)
const CURRENCY_START := Vector2(888.0, 24.0)
const CURRENCY_ITEM_SIZE := Vector2(172.0, 42.0)
const CURRENCY_GAP := 20.0
const CATEGORY_LIST_RECT := Rect2(220.0, 166.0, 172.0, 664.0)
const CATEGORY_SLOT_RECTS := [
	Rect2(246.0, 210.0, 124.0, 70.0),
	Rect2(248.0, 300.0, 120.0, 70.0),
	Rect2(248.0, 390.0, 120.0, 70.0),
	Rect2(248.0, 480.0, 120.0, 70.0),
	Rect2(248.0, 571.0, 120.0, 70.0),
	Rect2(248.0, 662.0, 120.0, 70.0),
]
const CATEGORY_LABEL_OFFSET := Vector2(11.0, 12.0)
const CATEGORY_LABEL_SIZE := Vector2(100.0, 44.0)
const CATEGORY_DOT_OFFSET := Vector2(110.0, 8.0)
const CATEGORY_DOT_SIZE := Vector2(11.0, 11.0)
const TASK_ROW_RECTS := [
	Rect2(455.0, 180.0, 530.0, 100.0),
	Rect2(455.0, 300.0, 530.0, 100.0),
	Rect2(455.0, 420.0, 530.0, 100.0),
	Rect2(455.0, 526.0, 530.0, 100.0),
	Rect2(455.0, 632.0, 530.0, 100.0),
	Rect2(455.0, 738.0, 530.0, 100.0),
]
const TASK_SELECTED_ROW_OFFSET := Vector2(0.0, -4.0)
const TASK_SELECTED_ROW_SIZE := Vector2(530.0, 116.0)
const TASK_ICON_SIZE := Vector2(82.0, 82.0)
const TASK_TITLE_OFFSET := Vector2(126.0, 17.0)
const TASK_DESC_OFFSET := Vector2(126.0, 55.0)
const TASK_PROGRESS_OFFSET := Vector2(418.0, 16.0)
const TASK_STATUS_OFFSET := Vector2(410.0, 54.0)
const TASK_TITLE_SIZE := Vector2(250.0, 34.0)
const TASK_DESC_SIZE := Vector2(275.0, 30.0)
const TASK_PROGRESS_SIZE := Vector2(84.0, 28.0)
const TASK_STATUS_SIZE := Vector2(82.0, 34.0)
const TASK_RED_DOT_OFFSET := Vector2(494.0, 47.0)
const DETAIL_RECT := Rect2(1080.0, 178.0, 455.0, 642.0)
const CLAIM_RECT := Rect2(1212.0, 715.0, 225.0, 72.0)
const BACK_RECT := Rect2(822.0, 850.0, 240.0, 62.0)

const VIEW_DATA := {
	"currencyBar": {
		"items": [
			{"id": "coin", "name": "铜钱", "icon": "icon_coin", "value": 12000, "showAdd": false},
			{"id": "jade", "name": "灵玉", "icon": "icon_jade", "value": 320, "showAdd": true},
			{"id": "achievement_point", "name": "问道值", "icon": "icon_wendao", "value": 24, "maxValue": 120, "showAdd": false}
		]
	},
	"leftCategoryList": {
		"selectedId": "all",
		"items": [
			{"id": "all", "name": "万象", "redDot": false, "unlock": true},
			{"id": "journey", "name": "仙途", "redDot": false, "unlock": true},
			{"id": "monster", "name": "斩妖", "redDot": true, "unlock": true},
			{"id": "collection", "name": "藏珍", "redDot": false, "unlock": true},
			{"id": "explore", "name": "云游", "redDot": false, "unlock": true},
			{"id": "trial", "name": "试炼", "redDot": false, "unlock": true}
		]
	},
	"centerAchievementList": {
		"selectedId": "kill_monster_100",
		"items": [
			{
				"id": "intro_qingxu",
				"categoryId": "journey",
				"title": "初入青墟",
				"desc": "完成主线任务【青墟问道】",
				"icon": "achievement_intro_qingxu",
				"progress": {"current": 1, "target": 1},
				"status": "completed",
				"statusText": "已铭刻",
				"redDot": false
			},
			{
				"id": "kill_monster_100",
				"categoryId": "monster",
				"title": "斩妖初试",
				"desc": "累计击败100只妖兽",
				"icon": "achievement_monster_01",
				"progress": {"current": 73, "target": 100},
				"status": "claimable",
				"statusText": "可领取",
				"redDot": true
			},
			{
				"id": "mountain_secret_10",
				"categoryId": "explore",
				"title": "山海初识",
				"desc": "解锁10处山海秘境",
				"icon": "achievement_mountain_01",
				"progress": {"current": 7, "target": 10},
				"status": "in_progress",
				"statusText": "修行中",
				"redDot": false
			},
			{
				"id": "treasure_quality_5",
				"categoryId": "collection",
				"title": "灵宝入囊",
				"desc": "获得5件紫色及以上品质灵宝",
				"icon": "achievement_treasure_01",
				"progress": {"current": 2, "target": 5},
				"status": "unstarted",
				"statusText": "未参悟",
				"redDot": false
			},
			{
				"id": "qi_mid_stage",
				"categoryId": "journey",
				"title": "炼气有成",
				"desc": "境界达到炼气中期",
				"icon": "achievement_qi_01",
				"progress": {"current": 1, "target": 1},
				"status": "completed",
				"statusText": "已铭刻",
				"redDot": false
			},
			{
				"id": "trial_floor_3",
				"categoryId": "trial",
				"title": "试炼锋芒",
				"desc": "通关试炼之地·第三层",
				"icon": "achievement_trial_01",
				"progress": {"current": 0, "target": 1},
				"status": "unstarted",
				"statusText": "未参悟",
				"redDot": false
			}
		]
	},
	"rightAchievementDetail": {
		"id": "kill_monster_100",
		"title": "斩妖初试",
		"subtitle": "初识妖邪，锋芒初露",
		"icon": "achievement_monster_01",
		"desc": "初试斩妖，锋芒初露。斩尽魑魅，方窥仙途。",
		"categoryId": "monster",
		"condition": {"title": "达成条件", "desc": "累计击败100只妖兽"},
		"progress": {"current": 73, "target": 100, "percent": 0.73, "text": "73/100"},
		"rewards": [
			{"id": "reward_coin", "name": "铜钱", "icon": "icon_coin", "count": 200},
			{"id": "reward_jade", "name": "灵玉", "icon": "icon_jade", "count": 50},
			{"id": "reward_crystal", "name": "寒晶", "icon": "icon_crystal", "count": 1},
			{"id": "reward_scroll", "name": "问道残卷", "icon": "icon_scroll", "count": 1}
		],
		"action": {"type": "claim", "text": "领取", "enabled": true},
		"status": "claimable"
	}
}

var background: TextureRect
var category_list_background: TextureRect
var currency_nodes: Array[Node] = []
var category_nodes: Array[Node] = []
var task_row_nodes: Array[Node] = []
var detail_nodes: Array[Node] = []
var claim_button: Button
var back_button: Button
var active_category_id := ""
var selected_achievement_id := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	mouse_filter = Control.MOUSE_FILTER_STOP
	active_category_id = String(Dictionary(VIEW_DATA["leftCategoryList"]).get("selectedId", "all"))
	selected_achievement_id = String(Dictionary(VIEW_DATA["centerAchievementList"]).get("selectedId", ""))
	hide()
	_build_view()
	_refresh_all()


func present() -> void:
	show()
	_refresh_all()


func hide_panel() -> void:
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause_game"):
		get_viewport().set_input_as_handled()
		back_requested.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_refresh_all()


func _build_view() -> void:
	background = TextureRect.new()
	background.name = "Background"
	background.texture = BACKGROUND_TEXTURE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	category_list_background = TextureRect.new()
	category_list_background.name = "CategoryListBackground"
	category_list_background.texture = CATEGORY_LIST_TEXTURE
	category_list_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	category_list_background.stretch_mode = TextureRect.STRETCH_SCALE
	category_list_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(category_list_background)

	claim_button = _make_text_button("ClaimButton")
	claim_button.pressed.connect(_on_claim_pressed)
	add_child(claim_button)

	back_button = _make_text_button("BackButton")
	back_button.text = "返回仙府"
	back_button.pressed.connect(func() -> void: back_requested.emit())
	add_child(back_button)


func _refresh_all() -> void:
	_set_design_rect(category_list_background, CATEGORY_LIST_RECT)
	_refresh_currency_bar()
	_refresh_categories()
	_refresh_task_rows()
	_refresh_detail()
	_set_design_rect(back_button, BACK_RECT)


func _refresh_currency_bar() -> void:
	_clear_nodes(currency_nodes)
	var items: Array = Array(Dictionary(VIEW_DATA["currencyBar"]).get("items", []))
	for index in range(items.size()):
		var item: Dictionary = items[index]
		var rect := Rect2(CURRENCY_START + Vector2((CURRENCY_ITEM_SIZE.x + CURRENCY_GAP) * float(index), 0.0), CURRENCY_ITEM_SIZE)
		var panel := _make_paper_panel(0.70)
		add_child(panel)
		currency_nodes.append(panel)
		_set_design_rect(panel, rect)

		var icon := _make_icon_placeholder(true)
		add_child(icon)
		currency_nodes.append(icon)
		_set_design_rect(icon, Rect2(rect.position + Vector2(8.0, 8.0), Vector2(26.0, 26.0)))

		var text := _format_currency_value(item)
		var label := _make_label(text, 19, false)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(label)
		currency_nodes.append(label)
		_set_design_rect(label, Rect2(rect.position + Vector2(38.0, 7.0), Vector2(92.0, 30.0)))

		if bool(item.get("showAdd", false)):
			var add_button := _make_text_button("Add%sButton" % String(item.get("id", "")).capitalize())
			add_button.text = "+"
			add_button.add_theme_font_size_override("font_size", 24)
			add_child(add_button)
			currency_nodes.append(add_button)
			_set_design_rect(add_button, Rect2(rect.position + Vector2(134.0, 5.0), Vector2(32.0, 32.0)))


func _refresh_categories() -> void:
	_clear_nodes(category_nodes)
	var items: Array = Array(Dictionary(VIEW_DATA["leftCategoryList"]).get("items", []))
	var visible_count: int = min(items.size(), CATEGORY_SLOT_RECTS.size())
	for index in range(visible_count):
		var item: Dictionary = items[index]
		var rect: Rect2 = CATEGORY_SLOT_RECTS[index]
		var selected := String(item.get("id", "")) == active_category_id

		if selected:
			var selected_plaque := TextureRect.new()
			selected_plaque.texture = CATEGORY_SELECTED_TEXTURE
			selected_plaque.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			selected_plaque.stretch_mode = TextureRect.STRETCH_SCALE
			selected_plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(selected_plaque)
			category_nodes.append(selected_plaque)
			_set_design_rect(selected_plaque, rect)

		var button := _make_text_button("Category%sButton" % String(item.get("id", "")).capitalize())
		button.text = ""
		button.disabled = not bool(item.get("unlock", true))
		button.pressed.connect(_on_category_pressed.bind(String(item.get("id", ""))))
		add_child(button)
		category_nodes.append(button)
		_set_design_rect(button, rect)

		var label := _make_label(String(item.get("name", "")), 30, true)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color(0.18, 0.08, 0.03, 1.0) if selected else Color(0.09, 0.08, 0.05, 1.0))
		add_child(label)
		category_nodes.append(label)
		_set_design_rect(label, Rect2(rect.position + CATEGORY_LABEL_OFFSET, CATEGORY_LABEL_SIZE))

		if bool(item.get("redDot", false)):
			var dot := _make_red_dot()
			add_child(dot)
			category_nodes.append(dot)
			_set_design_rect(dot, Rect2(rect.position + CATEGORY_DOT_OFFSET, CATEGORY_DOT_SIZE))


func _refresh_task_rows() -> void:
	_clear_nodes(task_row_nodes)
	var tasks := _tasks_for_active_category()
	if selected_achievement_id.is_empty() and not tasks.is_empty():
		selected_achievement_id = String(tasks[0].get("id", ""))
	var selected_in_filter := false
	for task in tasks:
		if String(task.get("id", "")) == selected_achievement_id:
			selected_in_filter = true
			break
	if not selected_in_filter:
		selected_achievement_id = String(tasks[0].get("id", "")) if not tasks.is_empty() else ""

	var visible_count: int = min(tasks.size(), TASK_ROW_RECTS.size())
	for index in range(visible_count):
		_add_task_row(tasks[index], index)


func _add_task_row(task: Dictionary, index: int) -> void:
	var selected := String(task.get("id", "")) == selected_achievement_id
	var base_rect: Rect2 = TASK_ROW_RECTS[index]
	var row_rect := Rect2(base_rect.position + TASK_SELECTED_ROW_OFFSET, TASK_SELECTED_ROW_SIZE) if selected else base_rect
	var content_origin := row_rect.position

	var row_texture := TextureRect.new()
	row_texture.texture = TASK_ROW_SELECTED_TEXTURE if selected else TASK_ROW_NORMAL_TEXTURE
	row_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	row_texture.stretch_mode = TextureRect.STRETCH_SCALE
	row_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row_texture)
	task_row_nodes.append(row_texture)
	_set_design_rect(row_texture, row_rect)

	var button := _make_text_button("TaskRow%d" % index)
	button.text = ""
	button.pressed.connect(_on_task_pressed.bind(String(task.get("id", ""))))
	add_child(button)
	task_row_nodes.append(button)
	_set_design_rect(button, row_rect)

	var icon := _make_task_icon(String(task.get("icon", "")))
	add_child(icon)
	task_row_nodes.append(icon)
	_set_design_rect(icon, Rect2(content_origin + _task_icon_offset(index), TASK_ICON_SIZE))

	var title := _make_label(String(task.get("title", "")), 28, false)
	title.add_theme_color_override("font_color", Color(0.10, 0.08, 0.05, 1.0))
	add_child(title)
	task_row_nodes.append(title)
	_set_design_rect(title, Rect2(content_origin + TASK_TITLE_OFFSET, TASK_TITLE_SIZE))

	var desc := _make_label(String(task.get("desc", "")), 19, false)
	desc.add_theme_color_override("font_color", Color(0.12, 0.10, 0.07, 1.0))
	add_child(desc)
	task_row_nodes.append(desc)
	_set_design_rect(desc, Rect2(content_origin + TASK_DESC_OFFSET, TASK_DESC_SIZE))

	var progress_data: Dictionary = Dictionary(task.get("progress", {}))
	var progress := _make_label("%d/%d" % [int(progress_data.get("current", 0)), int(progress_data.get("target", 0))], 20, false)
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	progress.add_theme_color_override("font_color", Color(0.11, 0.10, 0.08, 1.0))
	add_child(progress)
	task_row_nodes.append(progress)
	_set_design_rect(progress, Rect2(content_origin + _task_progress_offset(index), TASK_PROGRESS_SIZE))

	var status_panel := _make_task_status_panel(String(task.get("status", "")))
	add_child(status_panel)
	task_row_nodes.append(status_panel)
	_set_design_rect(status_panel, Rect2(content_origin + _task_status_offset(index), TASK_STATUS_SIZE))

	var status := _make_label(String(task.get("statusText", "")), 19, false)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status.add_theme_color_override("font_color", _task_status_text_color(String(task.get("status", ""))))
	add_child(status)
	task_row_nodes.append(status)
	_set_design_rect(status, Rect2(content_origin + _task_status_offset(index), TASK_STATUS_SIZE))

	if bool(task.get("redDot", false)):
		var dot := _make_red_dot()
		add_child(dot)
		task_row_nodes.append(dot)
		_set_design_rect(dot, Rect2(content_origin + TASK_RED_DOT_OFFSET, CATEGORY_DOT_SIZE))


func _refresh_detail() -> void:
	_clear_nodes(detail_nodes)
	var detail := _detail_for_selected()
	if detail.is_empty():
		claim_button.visible = false
		return

	var icon_panel := _make_icon_placeholder(false)
	add_child(icon_panel)
	detail_nodes.append(icon_panel)
	_set_design_rect(icon_panel, Rect2(1118.0, 226.0, 110.0, 110.0))

	var title := _make_label(String(detail.get("title", "")), 36, true)
	add_child(title)
	detail_nodes.append(title)
	_set_design_rect(title, Rect2(1250.0, 240.0, 240.0, 48.0))

	var subtitle := _make_label(String(detail.get("subtitle", "")), 19, false)
	add_child(subtitle)
	detail_nodes.append(subtitle)
	_set_design_rect(subtitle, Rect2(1250.0, 292.0, 300.0, 28.0))

	var desc := _make_label(String(detail.get("desc", "")), 20, false)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(desc)
	detail_nodes.append(desc)
	_set_design_rect(desc, Rect2(1250.0, 320.0, 300.0, 58.0))

	var condition: Dictionary = Dictionary(detail.get("condition", {}))
	var condition_title := _make_label(String(condition.get("title", "达成条件")), 22, true)
	condition_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(condition_title)
	detail_nodes.append(condition_title)
	_set_design_rect(condition_title, Rect2(1210.0, 405.0, 210.0, 36.0))

	var condition_desc := _make_label(String(condition.get("desc", "")), 20, false)
	add_child(condition_desc)
	detail_nodes.append(condition_desc)
	_set_design_rect(condition_desc, Rect2(1118.0, 448.0, 340.0, 32.0))

	var progress_data: Dictionary = Dictionary(detail.get("progress", {}))
	var progress := ProgressBar.new()
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress.show_percentage = false
	progress.min_value = 0.0
	progress.max_value = float(progress_data.get("target", 1))
	progress.value = float(progress_data.get("current", 0))
	add_child(progress)
	detail_nodes.append(progress)
	_set_design_rect(progress, Rect2(1120.0, 500.0, 315.0, 16.0))

	var progress_label := _make_label(String(progress_data.get("text", "")), 21, false)
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(progress_label)
	detail_nodes.append(progress_label)
	_set_design_rect(progress_label, Rect2(1440.0, 488.0, 95.0, 36.0))

	var rewards_title := _make_label("奖励预览", 22, true)
	rewards_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(rewards_title)
	detail_nodes.append(rewards_title)
	_set_design_rect(rewards_title, Rect2(1210.0, 548.0, 210.0, 34.0))

	var rewards: Array = Array(detail.get("rewards", []))
	for index in range(rewards.size()):
		var reward: Dictionary = rewards[index]
		var reward_panel := _make_reward_box()
		add_child(reward_panel)
		detail_nodes.append(reward_panel)
		_set_design_rect(reward_panel, Rect2(1108.0 + 99.0 * float(index), 592.0, 84.0, 76.0))

		var reward_label := _make_label("%s %d" % [String(reward.get("name", "")), int(reward.get("count", 0))], 16, false)
		reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reward_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		add_child(reward_label)
		detail_nodes.append(reward_label)
		_set_design_rect(reward_label, Rect2(1106.0 + 99.0 * float(index), 640.0, 88.0, 34.0))

	var action: Dictionary = Dictionary(detail.get("action", {}))
	claim_button.visible = true
	claim_button.text = String(action.get("text", "领取"))
	claim_button.disabled = not bool(action.get("enabled", true))
	InkUIStyle.apply_orbit_button(claim_button)
	_set_design_rect(claim_button, CLAIM_RECT)


func _on_category_pressed(category_id: String) -> void:
	active_category_id = category_id
	selected_achievement_id = ""
	_refresh_all()


func _on_task_pressed(achievement_id: String) -> void:
	selected_achievement_id = achievement_id
	_refresh_all()


func _on_claim_pressed() -> void:
	pass


func _tasks_for_active_category() -> Array[Dictionary]:
	var tasks: Array[Dictionary] = []
	var items: Array = Array(Dictionary(VIEW_DATA["centerAchievementList"]).get("items", []))
	for task in items:
		var task_dict := Dictionary(task)
		if active_category_id == "all" or String(task_dict.get("categoryId", "")) == active_category_id:
			tasks.append(task_dict)
	return tasks


func _detail_for_selected() -> Dictionary:
	var detail: Dictionary = Dictionary(VIEW_DATA.get("rightAchievementDetail", {}))
	if String(detail.get("id", "")) == selected_achievement_id:
		return detail
	return {}


func _format_currency_value(item: Dictionary) -> String:
	if item.has("maxValue"):
		return "%d/%d" % [int(item.get("value", 0)), int(item.get("maxValue", 0))]
	return "%d" % int(item.get("value", 0))


func _make_task_icon(icon_id: String) -> Control:
	if TASK_ICON_TEXTURES.has(icon_id):
		var icon := TextureRect.new()
		icon.texture = TASK_ICON_TEXTURES[icon_id]
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return icon
	return _make_icon_placeholder(false)


func _task_icon_offset(index: int) -> Vector2:
	if index >= 2:
		return Vector2(27.0, 3.0)
	return Vector2(27.0, 16.0)


func _task_progress_offset(index: int) -> Vector2:
	if index >= 2:
		return Vector2(TASK_PROGRESS_OFFSET.x, 13.0)
	return TASK_PROGRESS_OFFSET


func _task_status_offset(index: int) -> Vector2:
	if index >= 2:
		return Vector2(TASK_STATUS_OFFSET.x, 43.0)
	return TASK_STATUS_OFFSET


func _make_task_status_panel(status_key: String) -> Panel:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	match status_key:
		"claimable":
			box.bg_color = Color(0.86, 0.68, 0.40, 0.72)
			box.border_color = Color(0.55, 0.35, 0.14, 0.55)
		"completed":
			box.bg_color = Color(0.86, 0.82, 0.74, 0.18)
			box.border_color = Color(0.58, 0.12, 0.08, 0.70)
		"in_progress":
			box.bg_color = Color(0.80, 0.84, 0.80, 0.16)
			box.border_color = Color(0.22, 0.36, 0.43, 0.70)
		_:
			box.bg_color = Color(0.76, 0.72, 0.64, 0.14)
			box.border_color = Color(0.21, 0.18, 0.14, 0.55)
	box.set_border_width_all(1)
	box.set_corner_radius_all(5)
	panel.add_theme_stylebox_override("panel", box)
	return panel


func _task_status_text_color(status_key: String) -> Color:
	match status_key:
		"claimable":
			return Color(0.13, 0.09, 0.04, 1.0)
		"completed":
			return Color(0.58, 0.12, 0.08, 1.0)
		"in_progress":
			return Color(0.16, 0.28, 0.35, 1.0)
		_:
			return Color(0.11, 0.10, 0.08, 1.0)


func _make_text_button(button_name: String) -> Button:
	var button := Button.new()
	button.name = button_name
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", InkUIStyle.INK_BRUSH_FONT)
	button.add_theme_font_size_override("font_size", 25)
	button.add_theme_color_override("font_color", Color(0.13, 0.1, 0.06, 1.0))
	button.add_theme_color_override("font_hover_color", Color(0.24, 0.08, 0.04, 1.0))
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	return button


func _make_label(text: String, font_size: int, use_brush_font: bool) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.13, 0.1, 0.06, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0.96, 0.90, 0.74, 0.45))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	if use_brush_font:
		label.add_theme_font_override("font", InkUIStyle.INK_BRUSH_FONT)
	else:
		label.add_theme_font_override("font", SOURCE_HAN_SERIF_FONT)
	return label


func _make_icon_placeholder(small: bool) -> Panel:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.55, 0.50, 0.42, 0.10)
	box.border_color = Color(0.40, 0.34, 0.26, 0.30)
	box.set_border_width_all(1)
	box.set_corner_radius_all(16 if small else 64)
	panel.add_theme_stylebox_override("panel", box)
	return panel


func _make_reward_box() -> Panel:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _make_soft_box(Color(0.78, 0.72, 0.62, 0.42), Color(0.40, 0.34, 0.26, 0.28), 5))
	return panel


func _make_paper_panel(alpha: float) -> Panel:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _make_soft_box(Color(0.84, 0.80, 0.70, alpha), Color(0.42, 0.36, 0.26, 0.12), 8))
	return panel


func _make_soft_box(bg_color: Color, border_color: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg_color
	box.border_color = border_color
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	return box


func _make_red_dot() -> Panel:
	var dot := Panel.new()
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.77, 0.13, 0.09, 0.96)
	box.border_color = Color(0.48, 0.07, 0.04, 0.70)
	box.set_border_width_all(1)
	box.set_corner_radius_all(16)
	dot.add_theme_stylebox_override("panel", box)
	return dot


func _clear_nodes(nodes: Array[Node]) -> void:
	for node in nodes:
		if is_instance_valid(node):
			node.queue_free()
	nodes.clear()


func _set_design_rect(control: Control, rect: Rect2) -> void:
	var viewport_size := get_viewport_rect().size
	var scale: float = maxf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	var draw_size := DESIGN_SIZE * scale
	var offset := (viewport_size - draw_size) * 0.5
	control.position = offset + rect.position * scale
	control.size = rect.size * scale
