extends SceneTree

const OUT_DIR := "res://art"
const TRANSPARENT := Color(0, 0, 0, 0)


func _initialize() -> void:
	randomize()
	_make_dir("res://art/backgrounds")
	_make_dir("res://art/sprites")

	_save_image(_generate_arena_tile(), "res://art/backgrounds/arena_tile.png")
	_save_image(_generate_arena_overlay(), "res://art/backgrounds/arena_overlay.png")
	_save_image(_generate_vignette(), "res://art/backgrounds/vignette.png")
	_save_image(_generate_panel_tile(), "res://art/backgrounds/panel_tile.png")
	_save_image(_generate_player_sprite(), "res://art/sprites/player.png")
	_save_image(_generate_runner_sprite(), "res://art/sprites/enemy_runner.png")
	_save_image(_generate_brute_sprite(), "res://art/sprites/enemy_brute.png")
	_save_image(_generate_shooter_sprite(), "res://art/sprites/enemy_shooter.png")
	_save_image(_generate_elite_sprite(), "res://art/sprites/enemy_elite.png")
	_save_image(_generate_boss_sprite(), "res://art/sprites/enemy_boss.png")
	_save_image(_generate_player_projectile_sprite(), "res://art/sprites/projectile_player.png")
	_save_image(_generate_enemy_projectile_sprite(), "res://art/sprites/projectile_enemy.png")
	_save_image(_generate_experience_orb_sprite(), "res://art/sprites/experience_orb.png")
	_save_image(_generate_weapon_blaster_sprite(), "res://art/sprites/weapon_blaster.png")
	_save_image(_generate_weapon_flash_sprite(), "res://art/sprites/weapon_flash.png")
	_save_image(_generate_card_pickup_sprite(), "res://art/sprites/card_pickup.png")
	_save_image(_generate_card_icon_sprite("buff"), "res://art/sprites/card_buff.png")
	_save_image(_generate_card_icon_sprite("risk"), "res://art/sprites/card_risk.png")
	_save_image(_generate_card_icon_sprite("unknown"), "res://art/sprites/card_unknown.png")
	quit()


func _make_dir(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))


func _save_image(image: Image, path: String) -> void:
	image.save_png(ProjectSettings.globalize_path(path))


func _generate_arena_tile() -> Image:
	var size: int = 256
	var slab_size: int = 32
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var base: Color = Color8(10, 11, 16)
	var mortar: Color = Color8(7, 8, 12)
	var soot: Color = Color8(13, 15, 20)
	var crack: Color = Color8(48, 15, 22)
	var ember: Color = Color8(99, 34, 40)

	image.fill(base)
	for ty in range(0, size, slab_size):
		for tx in range(0, size, slab_size):
			var tile_color: Color = _pick_stone_color(tx, ty, slab_size)
			var tile_x: int = int(tx / slab_size)
			var tile_y: int = int(ty / slab_size)
			var bevel_depth: int = 3 + int((tile_x + tile_y) % 2)
			for y in range(slab_size):
				for x in range(slab_size):
					var px: int = tx + x
					var py: int = ty + y
					var edge_distance: int = mini(mini(x, slab_size - 1 - x), mini(y, slab_size - 1 - y))
					var color: Color = mortar
					if edge_distance >= 2:
						var wave: float = sin(float(px) * 0.09) * 0.014 + cos(float(py) * 0.07) * 0.013
						var patch: float = sin(float(px + py) * 0.035) * 0.012
						color = tile_color.lightened(wave + patch)
						if edge_distance <= bevel_depth:
							color = color.darkened(0.12 - float(edge_distance) * 0.02)
						elif edge_distance == bevel_depth + 1:
							color = color.lightened(0.05)
						if x % 11 == 0 and y % 7 == 0:
							color = color.darkened(0.03)
						if (px + py) % 29 == 0:
							color = color.lightened(0.015)
						if (px - py) % 31 == 0:
							color = color.darkened(0.015)
					image.set_pixel(px, py, color)

	for _i in range(10):
		var center: Vector2i = Vector2i(randi_range(24, size - 24), randi_range(24, size - 24))
		var radius: Vector2i = Vector2i(randi_range(10, 20), randi_range(7, 16))
		_blend_blob(image, center, radius, soot, 0.18)

	for _i in range(8):
		var start: Vector2i = Vector2i(randi_range(24, size - 24), randi_range(24, size - 24))
		var length: int = randi_range(18, 56)
		_blend_scratch(image, start, _pick_scratch_direction(), length, crack, ember, 0.58)

	return image


func _generate_arena_overlay() -> Image:
	var size: int = 256
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var shadow: Color = Color8(8, 10, 14)
	var ember: Color = Color8(92, 30, 37)

	image.fill(TRANSPARENT)
	for _i in range(9):
		var center: Vector2i = Vector2i(randi_range(32, size - 32), randi_range(32, size - 32))
		var radius: Vector2i = Vector2i(randi_range(16, 32), randi_range(10, 22))
		_stamp_overlay_blob(image, center, radius, shadow, 0.2)

	for _i in range(6):
		var start: Vector2i = Vector2i(randi_range(28, size - 28), randi_range(28, size - 28))
		var length: int = randi_range(24, 64)
		_stamp_overlay_scratch(image, start, _pick_scratch_direction(), length, shadow, ember)

	return image


func _generate_vignette() -> Image:
	var size := 512
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(TRANSPARENT)
	var center := Vector2(size * 0.5, size * 0.5)
	for y in range(size):
		for x in range(size):
			var uv := (Vector2(x, y) - center) / center
			var strength := clampf((uv.length() - 0.35) / 0.65, 0.0, 1.0)
			var alpha := pow(strength, 1.8) * 0.82
			var tint := Color8(10, 6, 11, 0)
			tint.a = alpha
			image.set_pixel(x, y, tint)
	return image


func _pick_stone_color(tx: int, ty: int, slab_size: int) -> Color:
	var tile_x: int = int(tx / slab_size)
	var tile_y: int = int(ty / slab_size)
	var pattern: int = int((tile_x + tile_y * 2) % 3)
	match pattern:
		0:
			return Color8(19, 22, 29)
		1:
			return Color8(24, 27, 35)
		_:
			return Color8(29, 33, 42)


func _pick_scratch_direction() -> Vector2i:
	var direction_index: int = randi() % 6
	match direction_index:
		0:
			return Vector2i(1, 0)
		1:
			return Vector2i(0, 1)
		2:
			return Vector2i(1, 1)
		3:
			return Vector2i(1, -1)
		4:
			return Vector2i(-1, 1)
		_:
			return Vector2i(-1, 0)


func _blend_blob(image: Image, center: Vector2i, radius: Vector2i, tint: Color, strength: float) -> void:
	var min_x: int = maxi(center.x - radius.x, 0)
	var max_x: int = mini(center.x + radius.x, image.get_width() - 1)
	var min_y: int = maxi(center.y - radius.y, 0)
	var max_y: int = mini(center.y + radius.y, image.get_height() - 1)
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var normalized: Vector2 = Vector2(float(x - center.x) / float(radius.x), float(y - center.y) / float(radius.y))
			var distance: float = normalized.length()
			if distance > 1.0:
				continue
			var weight: float = pow(1.0 - distance, 1.45) * strength
			var current: Color = image.get_pixel(x, y)
			image.set_pixel(x, y, current.lerp(tint, weight))


func _blend_scratch(image: Image, start: Vector2i, direction: Vector2i, length: int, crack: Color, ember: Color, strength: float) -> void:
	for step in range(length):
		var offset_x: int = 0
		var offset_y: int = 0
		if step % 5 == 0:
			offset_x = randi_range(-1, 1)
			offset_y = randi_range(-1, 1)
		var px: int = clampi(start.x + direction.x * step + offset_x, 0, image.get_width() - 1)
		var py: int = clampi(start.y + direction.y * step + offset_y, 0, image.get_height() - 1)
		var current: Color = image.get_pixel(px, py)
		image.set_pixel(px, py, current.lerp(crack, strength))
		if step % 6 == 0 and randf() < 0.28:
			var ember_x: int = clampi(px + randi_range(-1, 1), 0, image.get_width() - 1)
			var ember_y: int = clampi(py + randi_range(-1, 1), 0, image.get_height() - 1)
			var ember_current: Color = image.get_pixel(ember_x, ember_y)
			image.set_pixel(ember_x, ember_y, ember_current.lerp(ember, 0.35))


func _stamp_overlay_blob(image: Image, center: Vector2i, radius: Vector2i, tint: Color, max_alpha: float) -> void:
	var min_x: int = maxi(center.x - radius.x, 0)
	var max_x: int = mini(center.x + radius.x, image.get_width() - 1)
	var min_y: int = maxi(center.y - radius.y, 0)
	var max_y: int = mini(center.y + radius.y, image.get_height() - 1)
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var normalized: Vector2 = Vector2(float(x - center.x) / float(radius.x), float(y - center.y) / float(radius.y))
			var distance: float = normalized.length()
			if distance > 1.0:
				continue
			var alpha: float = pow(1.0 - distance, 1.9) * max_alpha
			var current: Color = image.get_pixel(x, y)
			if alpha <= current.a:
				continue
			var next: Color = tint
			next.a = alpha
			image.set_pixel(x, y, next)


func _stamp_overlay_scratch(image: Image, start: Vector2i, direction: Vector2i, length: int, shadow: Color, ember: Color) -> void:
	for step in range(length):
		var offset_x: int = 0
		var offset_y: int = 0
		if step % 4 == 0:
			offset_x = randi_range(-1, 1)
			offset_y = randi_range(-1, 1)
		var px: int = clampi(start.x + direction.x * step + offset_x, 0, image.get_width() - 1)
		var py: int = clampi(start.y + direction.y * step + offset_y, 0, image.get_height() - 1)
		var mark: Color = shadow
		mark.a = 0.3
		image.set_pixel(px, py, mark)
		if step % 8 == 0 and randf() < 0.35:
			var spark_x: int = clampi(px + randi_range(-1, 1), 0, image.get_width() - 1)
			var spark_y: int = clampi(py + randi_range(-1, 1), 0, image.get_height() - 1)
			var spark: Color = ember
			spark.a = 0.55
			image.set_pixel(spark_x, spark_y, spark)


func _generate_panel_tile() -> Image:
	var image := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	var base := Color8(18, 22, 30)
	var mid := Color8(25, 31, 40)
	var highlight := Color8(60, 69, 82)
	var shadow := Color8(7, 9, 13)
	var accent := Color8(87, 25, 33)
	image.fill(base)

	for y in range(96):
		for x in range(96):
			var band := sin(float(x + y) * 0.2) * 0.02
			image.set_pixel(x, y, mid.lightened(band))

	for i in range(96):
		image.set_pixel(i, 0, highlight)
		image.set_pixel(i, 1, highlight.darkened(0.15))
		image.set_pixel(i, 94, shadow.lightened(0.05))
		image.set_pixel(i, 95, shadow)
		image.set_pixel(0, i, highlight)
		image.set_pixel(1, i, highlight.darkened(0.15))
		image.set_pixel(94, i, shadow.lightened(0.05))
		image.set_pixel(95, i, shadow)

	for x in range(10, 86):
		image.set_pixel(x, 10, accent)
		image.set_pixel(x, 85, accent.darkened(0.2))
	for y in range(10, 86):
		image.set_pixel(10, y, accent)
		image.set_pixel(85, y, accent.darkened(0.2))

	for _i in range(50):
		var px := randi_range(8, 87)
		var py := randi_range(8, 87)
		image.set_pixel(px, py, highlight.lightened(randf() * 0.2))
	return image


func _generate_player_sprite() -> Image:
	return _sprite_from_pattern([
		"................",
		"................",
		"......YY........",
		".....YYYY.......",
		"....YHHHHY......",
		"...YHBBBBHY.....",
		"...YBBBBBBY.....",
		"...YBWWWWBY.....",
		"...YBWWWWBY.....",
		"...YBWWWWBY.....",
		"....YBWWBY......",
		"....SBBBBS......",
		"...S..BB..S.....",
		"...S..BB..S.....",
		"..GG..BB..GG....",
		"..GG..BB..GG...."
	], {
		".": TRANSPARENT,
		"Y": Color8(214, 177, 82),
		"H": Color8(54, 28, 32),
		"B": Color8(74, 99, 128),
		"W": Color8(183, 219, 238),
		"S": Color8(34, 38, 48),
		"G": Color8(88, 102, 122)
	}, 4)


func _generate_runner_sprite() -> Image:
	return _sprite_from_pattern([
		"................",
		".....aaAA.......",
		"....aABBAa......",
		"...aABCCBAa.....",
		"...aBCCCCBa.....",
		"..aBDCCCCDBa....",
		"..aBDCCCCDBa....",
		"..aABCCCCBAa....",
		"...aBBCCBBa.....",
		"...d.BCCB.d.....",
		"..dd.BCCB.dd....",
		"..d..BCCB..d....",
		".....BCCB.......",
		"....dB..Bd......",
		"...dd....dd.....",
		"................"
	], {
		".": TRANSPARENT,
		"a": Color8(93, 24, 32),
		"A": Color8(173, 54, 73),
		"B": Color8(131, 42, 55),
		"C": Color8(244, 226, 200),
		"D": Color8(255, 248, 230),
		"d": Color8(64, 20, 27)
	}, 4)


func _generate_brute_sprite() -> Image:
	return _sprite_from_pattern([
		"................",
		"...ttOOOOtt.....",
		"..tOoooAAooOt...",
		"..OooABBBBAooO..",
		".tOoABCCCCBAoOt.",
		".OOABCDDDDCBAOO.",
		".OOABCDDDDCBAOO.",
		".OOABCDDDDCBAOO.",
		".OOABBCCCCBBAOO.",
		".tOOABBBBBBAOOt.",
		"..OOAABBBBAAOO..",
		"..OOAABBBBAAOO..",
		"...OO..BB..OO...",
		"..tOO..BB..OOt..",
		"...tt..BB..tt...",
		"................"
	], {
		".": TRANSPARENT,
		"t": Color8(90, 58, 23),
		"O": Color8(132, 86, 34),
		"o": Color8(101, 66, 24),
		"A": Color8(171, 116, 50),
		"B": Color8(120, 81, 35),
		"C": Color8(243, 221, 190),
		"D": Color8(255, 247, 225)
	}, 4)


func _generate_shooter_sprite() -> Image:
	return _sprite_from_pattern([
		"................",
		".....ssCC.......",
		"...ssCccccCs....",
		"...sCcABBAcCs...",
		"..sCcABDDBAcCs..",
		"..CCaBDEEDBaCC..",
		"..CCaBDEEDBaCC..",
		"..CCaBDDDDBaCC..",
		"..sCCaBBBBaCCs..",
		"...sCCaBBaCCs...",
		"..bb.sCCCCs.bb..",
		"..b..sCCCCs..b..",
		".....sCCCCs.....",
		"....bbC..Cbb....",
		"...bbb....bbb...",
		"................"
	], {
		".": TRANSPARENT,
		"s": Color8(27, 56, 86),
		"C": Color8(63, 132, 184),
		"c": Color8(35, 88, 128),
		"a": Color8(86, 179, 225),
		"A": Color8(47, 101, 146),
		"B": Color8(77, 161, 206),
		"D": Color8(212, 232, 245),
		"E": Color8(246, 252, 255),
		"b": Color8(39, 49, 70)
	}, 4)


func _generate_elite_sprite() -> Image:
	return _sprite_from_pattern([
		"................",
		".....rrGG.......",
		"...rrGggggGr....",
		"...rGgABBAgGr...",
		"..rGgABCCBAgGr..",
		"..GGABCDDCBAGG..",
		".rGGABCDDCBAGGr.",
		".rGGABCCCCBAGGr.",
		"..GGgABBBBAgGG..",
		"..rGGgABBAgGGr..",
		"..RR.GGGGGG.RR..",
		"..R..GGGGGG..R..",
		".....GGGGGG.....",
		"...RRGG..GGRR...",
		"..RRR......RRR..",
		"................"
	], {
		".": TRANSPARENT,
		"r": Color8(128, 29, 37),
		"R": Color8(161, 40, 48),
		"G": Color8(212, 160, 62),
		"g": Color8(129, 83, 27),
		"A": Color8(180, 132, 44),
		"B": Color8(143, 99, 28),
		"C": Color8(255, 226, 177),
		"D": Color8(255, 245, 216)
	}, 4)


func _generate_boss_sprite() -> Image:
	return _sprite_from_pattern([
		"....rrTTTTrr....",
		"...rTWWAAWWTr...",
		"..rTWABBBBAWTr..",
		"..TWABCCCCBAWT..",
		".rWABCDDDDCBAWr.",
		".TWABCDFFDCBAWT.",
		".TWABCDFFDCBAWT.",
		".TWABCDDDDCBAWT.",
		".TWABCCCCCCBAWT.",
		".rTWABBBBBBAWTr.",
		"..rTWABBBBAWTr..",
		"..RR.TWGGWT.RR..",
		".RR...TGGT...RR.",
		".R....TGGT....R.",
		"......T..T......",
		".....RR..RR....."
	], {
		".": TRANSPARENT,
		"r": Color8(81, 20, 30),
		"R": Color8(117, 29, 40),
		"T": Color8(74, 88, 112),
		"W": Color8(34, 45, 61),
		"A": Color8(61, 73, 96),
		"B": Color8(50, 61, 80),
		"C": Color8(164, 188, 210),
		"D": Color8(214, 232, 247),
		"F": Color8(246, 252, 255),
		"G": Color8(203, 84, 63)
	}, 5)


func _generate_player_projectile_sprite() -> Image:
	return _sprite_from_pattern([
		"......gg........",
		".....gWWg.......",
		"...ggWYYWgg.....",
		"..ggWYYYYWgg....",
		"...ggWYYWgg.....",
		".....gWWg.......",
		"......gg........",
		"................"
	], {
		".": TRANSPARENT,
		"g": Color8(237, 141, 42),
		"W": Color8(255, 236, 180),
		"Y": Color8(255, 249, 236)
	}, 4)


func _generate_enemy_projectile_sprite() -> Image:
	return _sprite_from_pattern([
		"......dd........",
		".....dCCd.......",
		"...ddCRRCdd.....",
		"..ddCRRRRCdd....",
		"...ddCRRCdd.....",
		".....dCCd.......",
		"......dd........",
		"................"
	], {
		".": TRANSPARENT,
		"d": Color8(45, 132, 196),
		"C": Color8(108, 214, 255),
		"R": Color8(255, 122, 151)
	}, 4)


func _generate_experience_orb_sprite() -> Image:
	return _sprite_from_pattern([
		"................",
		".....nnnn.......",
		"...nnNNNNnn.....",
		"...nNCCCCNn.....",
		"..nNCCWWCCNn....",
		"..nNCWWWWCNn....",
		"..nNCWWWWCNn....",
		"..nNCCWWCCNn....",
		"...nNCCCCNn.....",
		"...nnNNNNnn.....",
		".....nnnn.......",
		"................"
	], {
		".": TRANSPARENT,
		"n": Color8(18, 152, 123),
		"N": Color8(45, 225, 170),
		"C": Color8(119, 255, 213),
		"W": Color8(240, 255, 250)
	}, 4)


func _generate_weapon_blaster_sprite() -> Image:
	return _sprite_from_pattern([
		"................",
		"................",
		"................",
		".....SSS........",
		"...TTBBBBB......",
		"..TTBBBWWWW.....",
		".TTTBBBWWYY.....",
		"..TTBBBWWWW.....",
		"...TTBBBBB......",
		".....SSS........",
		"................",
		"................"
	], {
		".": TRANSPARENT,
		"T": Color8(78, 94, 117),
		"B": Color8(34, 42, 56),
		"W": Color8(170, 206, 226),
		"Y": Color8(231, 188, 82),
		"S": Color8(117, 68, 33)
	}, 4)


func _generate_weapon_flash_sprite() -> Image:
	return _sprite_from_pattern([
		"................",
		"......Y.........",
		".....YYY........",
		"...YYYOYYY......",
		"..YYYYOOYYY.....",
		"...YYYOYYY......",
		".....YYY........",
		"......Y.........",
		"................"
	], {
		".": TRANSPARENT,
		"Y": Color8(250, 214, 103),
		"O": Color8(255, 245, 218)
	}, 4)


func _generate_card_pickup_sprite() -> Image:
	return _sprite_from_pattern([
		"................",
		"...RRRRRRRR.....",
		"..RddddddddR....",
		"..RdBBBBBBdR....",
		"..RdBWWWWBdR....",
		"..RdBWGGWBdR....",
		"..RdBWGGWBdR....",
		"..RdBWWWWBdR....",
		"..RdBBBBBBdR....",
		"..RddddddddR....",
		"...RRRRRRRR.....",
		"................"
	], {
		".": TRANSPARENT,
		"R": Color8(128, 34, 42),
		"d": Color8(30, 32, 42),
		"B": Color8(51, 72, 102),
		"W": Color8(210, 226, 232),
		"G": Color8(240, 195, 87)
	}, 4)


func _generate_card_icon_sprite(icon_type: String) -> Image:
	match icon_type:
		"buff":
			return _sprite_from_pattern([
				"................",
				"...GGGGGGGG.....",
				"..GllllllllG....",
				"..Gl..ll..lG....",
				"..Gl.GGGG.lG....",
				"..GlGGWWGGlG....",
				"..GlGGWWGGlG....",
				"..Gl.GGGG.lG....",
				"..Gl..ll..lG....",
				"..GllllllllG....",
				"...GGGGGGGG.....",
				"................"
			], {
				".": TRANSPARENT,
				"G": Color8(82, 205, 126),
				"l": Color8(19, 83, 53),
				"W": Color8(217, 255, 226)
			}, 4)
		"risk":
			return _sprite_from_pattern([
				"................",
				"...RRRRRRRR.....",
				"..RddddddddR....",
				"..Rd..RR..dR....",
				"..Rd.RRRR.dR....",
				"..RdRRWWRRdR....",
				"..RdRRWWRRdR....",
				"..Rd.RRRR.dR....",
				"..Rd..RR..dR....",
				"..RddddddddR....",
				"...RRRRRRRR.....",
				"................"
			], {
				".": TRANSPARENT,
				"R": Color8(182, 56, 64),
				"d": Color8(62, 18, 24),
				"W": Color8(255, 230, 226)
			}, 4)
		_:
			return _sprite_from_pattern([
				"................",
				"...BBBBBBBB.....",
				"..BddddddddB....",
				"..Bd..YY..dB....",
				"..Bd.YWWY.dB....",
				"..BdYYWWYYdB....",
				"..BdYYWWYYdB....",
				"..Bd.YWWY.dB....",
				"..Bd..YY..dB....",
				"..BddddddddB....",
				"...BBBBBBBB.....",
				"................"
			], {
				".": TRANSPARENT,
				"B": Color8(83, 111, 173),
				"d": Color8(24, 30, 55),
				"Y": Color8(244, 197, 88),
				"W": Color8(239, 247, 255)
			}, 4)


func _sprite_from_pattern(pattern: Array[String], palette: Dictionary, scale: int) -> Image:
	var width := pattern[0].length()
	var height := pattern.size()
	var image := Image.create(width * scale, height * scale, false, Image.FORMAT_RGBA8)
	image.fill(TRANSPARENT)
	for y in range(height):
		var row := pattern[y]
		for x in range(width):
			var key := row.substr(x, 1)
			var color: Color = palette.get(key, TRANSPARENT)
			if color.a <= 0.0:
				continue
			for sy in range(scale):
				for sx in range(scale):
					image.set_pixel(x * scale + sx, y * scale + sy, color)
	return image
