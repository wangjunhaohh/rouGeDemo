extends SceneTree

const OUT_DIR := "res://art"
const TRANSPARENT := Color(0, 0, 0, 0)


func _initialize() -> void:
	randomize()
	_make_dir("res://art/backgrounds")
	_make_dir("res://art/sprites")

	_save_image(_generate_arena_tile(), "res://art/backgrounds/arena_tile.png")
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
	quit()


func _make_dir(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))


func _save_image(image: Image, path: String) -> void:
	image.save_png(ProjectSettings.globalize_path(path))


func _generate_arena_tile() -> Image:
	var image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var base := Color8(16, 18, 26)
	var stone_a := Color8(24, 26, 35)
	var stone_b := Color8(30, 32, 42)
	var crack := Color8(42, 11, 19)
	var ember := Color8(77, 22, 30)

	image.fill(base)
	for ty in range(0, 128, 16):
		for tx in range(0, 128, 16):
			var tile_color := stone_a if ((tx + ty) / 16) % 2 == 0 else stone_b
			for y in range(16):
				for x in range(16):
					var px := tx + x
					var py := ty + y
					var shade := float(((x + y) % 5) - 2) * 0.012
					var color := tile_color.lightened(shade)
					if x == 0 or y == 0:
						color = color.darkened(0.25)
					if x == 15 or y == 15:
						color = color.lightened(0.06)
					if randf() < 0.08:
						color = color.lightened(randf() * 0.08)
					image.set_pixel(px, py, color)

	for _i in range(28):
		var start := Vector2i(randi_range(0, 127), randi_range(0, 127))
		var length := randi_range(8, 28)
		var dir := Vector2i([-1, 1][randi() % 2], [-1, 1][randi() % 2])
		for step in range(length):
			var px := clampi(start.x + dir.x * step + randi_range(-1, 1), 0, 127)
			var py := clampi(start.y + dir.y * step + randi_range(-1, 1), 0, 127)
			image.set_pixel(px, py, crack)
			if randf() < 0.3:
				image.set_pixel(clampi(px + 1, 0, 127), py, ember)

	for _i in range(16):
		var center := Vector2i(randi_range(10, 118), randi_range(10, 118))
		var radius := randi_range(3, 6)
		for y in range(center.y - radius, center.y + radius + 1):
			for x in range(center.x - radius, center.x + radius + 1):
				if x < 0 or y < 0 or x >= 128 or y >= 128:
					continue
				var distance := Vector2(x - center.x, y - center.y).length()
				if distance <= radius and randf() > 0.18:
					var stain := Color8(52, 14, 19).lerp(Color8(24, 6, 10), distance / float(radius))
					image.set_pixel(x, y, stain)
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
		"................",
		".....RRRR.......",
		"....RrrrrR......",
		"...RrrMMrrR.....",
		"...RrMMMMrR.....",
		"...RrMMMMrR.....",
		"...RrMMMMrR.....",
		"....RMMMMR......",
		"....rRMMRr......",
		"...r..MM..r.....",
		"...r..MM..r.....",
		"..rr..MM..rr....",
		"..r...MM...r....",
		"......MM........",
		"......MM........"
	], {
		".": TRANSPARENT,
		"R": Color8(162, 54, 59),
		"r": Color8(108, 32, 36),
		"M": Color8(241, 231, 215)
	}, 4)


func _generate_brute_sprite() -> Image:
	return _sprite_from_pattern([
		"................",
		"....OOOOOO......",
		"...OooooooO.....",
		"..OooMMMMooO....",
		"..OooMMMMooO....",
		"..OooooooooO....",
		"..OooOOOOooO....",
		"..OooOOOOooO....",
		"..OooOOOOooO....",
		"..OOoOOOOoOO....",
		"...OooOOooO.....",
		"...O..OO..O.....",
		"..OO..OO..OO....",
		"..OO..OO..OO....",
		"...O..OO..O.....",
		"......OO........"
	], {
		".": TRANSPARENT,
		"O": Color8(151, 104, 43),
		"o": Color8(102, 69, 25),
		"M": Color8(231, 209, 181)
	}, 4)


func _generate_shooter_sprite() -> Image:
	return _sprite_from_pattern([
		"................",
		"......CC........",
		".....CccC.......",
		"....Cccccc......",
		"...CcMMMMcC.....",
		"...CccMMccC.....",
		"...CccccccC.....",
		"...CccccccC.....",
		"....CccccC......",
		"...bbCccCbb.....",
		"..bb..CC..bb....",
		"..b...CC...b....",
		"......CC........",
		".....bCCb.......",
		"....bb..bb......",
		"................"
	], {
		".": TRANSPARENT,
		"C": Color8(69, 144, 196),
		"c": Color8(33, 91, 131),
		"M": Color8(220, 236, 246),
		"b": Color8(46, 54, 72)
	}, 4)


func _generate_elite_sprite() -> Image:
	return _sprite_from_pattern([
		"................",
		".....GGGG.......",
		"....GggggG......",
		"...GgMMMMgG.....",
		"...GgMMMMgG.....",
		"...GggggggG.....",
		"..GGgGGGGgGG....",
		"..GggGGGGggG....",
		"..GggGGGGggG....",
		"...GgGGGGgG.....",
		"..AA.GGGG.AA....",
		"..A..GGGG..A....",
		".....GGGG.......",
		"...AAGGGGAA.....",
		"...AA....AA.....",
		"................"
	], {
		".": TRANSPARENT,
		"G": Color8(212, 160, 62),
		"g": Color8(123, 78, 24),
		"M": Color8(255, 232, 189),
		"A": Color8(161, 42, 43)
	}, 4)


func _generate_boss_sprite() -> Image:
	return _sprite_from_pattern([
		"................",
		"......TT........",
		".....TWWT.......",
		"....TWWWWT......",
		"...TWWMMWWT.....",
		"..TWWMMMMWWT....",
		"..TWWMMMMWWT....",
		"..TWWMMMMWWT....",
		"..TWWMMMMWWT....",
		"..TWWWMMWWWT....",
		"...TWWWWWWT.....",
		"..RRTWWWWTRR....",
		".RRR.TTTT.RRR...",
		".R....TT....R...",
		"......TT........",
		".....R..R......."
	], {
		".": TRANSPARENT,
		"T": Color8(87, 98, 125),
		"W": Color8(34, 44, 58),
		"M": Color8(223, 241, 255),
		"R": Color8(122, 28, 39)
	}, 5)


func _generate_player_projectile_sprite() -> Image:
	return _sprite_from_pattern([
		"......Y.........",
		".....YYY........",
		"....YYYYY.......",
		"...YYYYYYY......",
		"....YYYYY.......",
		".....YYY........",
		"......Y.........",
		"................"
	], {
		".": TRANSPARENT,
		"Y": Color8(248, 225, 107)
	}, 4)


func _generate_enemy_projectile_sprite() -> Image:
	return _sprite_from_pattern([
		"......B.........",
		".....BBB........",
		"....BBRBB.......",
		"...BBRRRBB......",
		"....BBRBB.......",
		".....BBB........",
		"......B.........",
		"................"
	], {
		".": TRANSPARENT,
		"B": Color8(80, 173, 220),
		"R": Color8(184, 58, 72)
	}, 4)


func _generate_experience_orb_sprite() -> Image:
	return _sprite_from_pattern([
		"................",
		"......GG........",
		"....GGllGG......",
		"...GllllllG.....",
		"...GllWWllG.....",
		"..GlllWWlllG....",
		"..GlllWWlllG....",
		"..GllWWWWllG....",
		"...GllllllG.....",
		"...GGllllGG.....",
		".....GGGG.......",
		"................"
	], {
		".": TRANSPARENT,
		"G": Color8(74, 220, 138),
		"l": Color8(28, 151, 88),
		"W": Color8(213, 255, 223)
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
