extends SceneTree

const TRANSPARENT := Color(0, 0, 0, 0)
const OUT_DIR := "res://art/sprites/branch_weapons"


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_save_image(_generate_tank_blade_idle(), "%s/tank_blade_idle.png" % OUT_DIR)
	_save_image(_generate_tank_blade_windup(), "%s/tank_blade_windup.png" % OUT_DIR)
	_save_image(_generate_tank_blade_swing(), "%s/tank_blade_swing.png" % OUT_DIR)
	_save_image(_generate_tank_blade_recover(), "%s/tank_blade_recover.png" % OUT_DIR)
	_save_image(_generate_tank_slash_a(), "%s/tank_slash_a.png" % OUT_DIR)
	_save_image(_generate_tank_slash_b(), "%s/tank_slash_b.png" % OUT_DIR)
	_save_image(_generate_debuff_staff_idle(), "%s/debuff_staff_idle.png" % OUT_DIR)
	_save_image(_generate_debuff_staff_cast(), "%s/debuff_staff_cast.png" % OUT_DIR)
	_save_image(_generate_debuff_staff_release(), "%s/debuff_staff_release.png" % OUT_DIR)
	_save_image(_generate_debuff_cast_a(), "%s/debuff_cast_a.png" % OUT_DIR)
	_save_image(_generate_debuff_cast_b(), "%s/debuff_cast_b.png" % OUT_DIR)
	_save_image(_generate_debuff_orb(), "%s/debuff_orb.png" % OUT_DIR)
	_save_image(_generate_building_relay_idle(), "%s/building_relay_idle.png" % OUT_DIR)
	_save_image(_generate_building_relay_charge(), "%s/building_relay_charge.png" % OUT_DIR)
	_save_image(_generate_building_relay_release(), "%s/building_relay_release.png" % OUT_DIR)
	_save_image(_generate_building_signal_a(), "%s/building_signal_a.png" % OUT_DIR)
	_save_image(_generate_building_signal_b(), "%s/building_signal_b.png" % OUT_DIR)
	_save_image(_generate_building_bolt(), "%s/building_bolt.png" % OUT_DIR)
	quit()


func _save_image(image: Image, path: String) -> void:
	image.save_png(ProjectSettings.globalize_path(path))


func _generate_tank_blade_idle() -> Image:
	return _sprite_from_pattern([
		"................",
		".......MM.......",
		".......MM.......",
		".......MM.......",
		".......MM.......",
		"......MYYM......",
		".....MYYYYM.....",
		"....MYYYYYYM....",
		"....MYYYYYYM....",
		".....MYYYYM.....",
		"......MYYM......",
		".......SS.......",
		"......SSSS......",
		".......SS.......",
		"................",
		"................"
	], {
		".": TRANSPARENT,
		"M": Color8(114, 120, 146),
		"Y": Color8(231, 201, 118),
		"S": Color8(87, 60, 34)
	}, 4)


func _generate_tank_blade_windup() -> Image:
	return _sprite_from_pattern([
		"................",
		"....MM..........",
		"...MMMM.........",
		"...MMMMM........",
		"..MMYYMM........",
		"..MYYYYMM.......",
		"..MYYYYYYM......",
		"...MYYYYYYM.....",
		"...MMYYYYYM.....",
		"....MMYYYYM.....",
		".....MMYYM......",
		"......SS........",
		".....SSSS.......",
		"......SS........",
		"................",
		"................"
	], {
		".": TRANSPARENT,
		"M": Color8(114, 120, 146),
		"Y": Color8(231, 201, 118),
		"S": Color8(87, 60, 34)
	}, 4)


func _generate_tank_blade_swing() -> Image:
	return _sprite_from_pattern([
		"................",
		"..........MM....",
		".........MMMM...",
		"........MYYYMM..",
		".......MYYYYYYM.",
		"......MYYYYYYYMM",
		"......MYYYYYYYMM",
		".......MYYYYYYM.",
		"........MYYYYM..",
		".........MYYM...",
		"..........SS....",
		".........SSSS...",
		"..........SS....",
		"................",
		"................",
		"................"
	], {
		".": TRANSPARENT,
		"M": Color8(114, 120, 146),
		"Y": Color8(231, 201, 118),
		"S": Color8(87, 60, 34)
	}, 4)


func _generate_tank_blade_recover() -> Image:
	return _sprite_from_pattern([
		"................",
		"..........MM....",
		".........MMMM...",
		"........MYYYYM..",
		".......MYYYYYM..",
		"......MYYYYYM...",
		".....MYYYYYM....",
		"....MYYYYYM.....",
		"....MYYYYM......",
		".....MYYM.......",
		"......SS........",
		".....SSSS.......",
		"......SS........",
		"................",
		"................",
		"................"
	], {
		".": TRANSPARENT,
		"M": Color8(114, 120, 146),
		"Y": Color8(231, 201, 118),
		"S": Color8(87, 60, 34)
	}, 4)


func _generate_tank_slash_a() -> Image:
	return _sprite_from_pattern([
		"................",
		"............AA..",
		".........AAAAAA.",
		".......AAAAAABB.",
		".....AAAAAABBB..",
		"....AAAAABBB....",
		"....AAAABB......",
		".....AABB.......",
		"......BB........",
		"................",
		"................",
		"................",
		"................",
		"................",
		"................",
		"................"
	], {
		".": TRANSPARENT,
		"A": Color8(255, 235, 180),
		"B": Color8(255, 195, 104)
	}, 4)


func _generate_tank_slash_b() -> Image:
	return _sprite_from_pattern([
		"................",
		"...........AA...",
		"........AAAAAA..",
		"......AAAAABBB..",
		"....AAAAABBB....",
		"...AAAABBB......",
		"...AAABB........",
		"....ABB.........",
		".....B..........",
		"................",
		"................",
		"................",
		"................",
		"................",
		"................",
		"................"
	], {
		".": TRANSPARENT,
		"A": Color8(255, 244, 206),
		"B": Color8(251, 201, 116)
	}, 4)


func _generate_debuff_staff_idle() -> Image:
	return _sprite_from_pattern([
		"................",
		".......OO.......",
		"......OYYO......",
		"......OYYO......",
		".......PP.......",
		".......PP.......",
		".......PP.......",
		".......PP.......",
		".......PP.......",
		".......PP.......",
		"......PRP.......",
		"......RR........",
		".....RRR........",
		"................",
		"................",
		"................"
	], {
		".": TRANSPARENT,
		"O": Color8(128, 48, 36),
		"Y": Color8(255, 182, 120),
		"P": Color8(92, 59, 124),
		"R": Color8(188, 92, 58)
	}, 4)


func _generate_debuff_staff_cast() -> Image:
	return _sprite_from_pattern([
		"................",
		"......OOO.......",
		".....OYYYOO.....",
		".....OYYYOO.....",
		"......OPP.......",
		"......PPP.......",
		"......PPP.......",
		"......PPP.......",
		".....PPP........",
		".....PPR........",
		".....RRR........",
		"....RRR.........",
		"................",
		"................",
		"................",
		"................"
	], {
		".": TRANSPARENT,
		"O": Color8(128, 48, 36),
		"Y": Color8(255, 182, 120),
		"P": Color8(92, 59, 124),
		"R": Color8(188, 92, 58)
	}, 4)


func _generate_debuff_staff_release() -> Image:
	return _sprite_from_pattern([
		"................",
		"........OO......",
		".......OYYOO....",
		".......OYYOO....",
		"........PPP.....",
		"........PPP.....",
		".......PPP......",
		"......PPP.......",
		".....PPP........",
		".....PPR........",
		".....RRR........",
		"....RR..........",
		"................",
		"................",
		"................",
		"................"
	], {
		".": TRANSPARENT,
		"O": Color8(128, 48, 36),
		"Y": Color8(255, 182, 120),
		"P": Color8(92, 59, 124),
		"R": Color8(188, 92, 58)
	}, 4)


func _generate_debuff_cast_a() -> Image:
	return _sprite_from_pattern([
		"................",
		"......AA........",
		"....AABBA.......",
		"...AABBCCA......",
		"...ABCCCB.......",
		"..AABCCB........",
		"...ABBA.........",
		"....AA..........",
		"................",
		"................",
		"................",
		"................",
		"................",
		"................",
		"................",
		"................"
	], {
		".": TRANSPARENT,
		"A": Color8(255, 205, 132),
		"B": Color8(246, 132, 72),
		"C": Color8(255, 244, 220)
	}, 4)


func _generate_debuff_cast_b() -> Image:
	return _sprite_from_pattern([
		"................",
		"........AA......",
		"......AABBAA....",
		".....AABCCBBA...",
		"....AABCCCCBA...",
		".....AABCCBA....",
		"......AABBA.....",
		".......AA.......",
		"................",
		"................",
		"................",
		"................",
		"................",
		"................",
		"................",
		"................"
	], {
		".": TRANSPARENT,
		"A": Color8(255, 230, 170),
		"B": Color8(250, 154, 78),
		"C": Color8(255, 246, 224)
	}, 4)


func _generate_debuff_orb() -> Image:
	return _sprite_from_pattern([
		"................",
		"......aa........",
		".....aBBA.......",
		"...aaBCCCCaa....",
		"..aaBCCDDCCaa...",
		"...aaBCCCCaa....",
		".....aBBA.......",
		"......aa........",
		"................",
		"................",
		"................",
		"................",
		"................",
		"................",
		"................",
		"................"
	], {
		".": TRANSPARENT,
		"a": Color8(182, 68, 48),
		"B": Color8(248, 143, 79),
		"C": Color8(255, 194, 118),
		"D": Color8(255, 241, 214)
	}, 4)


func _generate_building_relay_idle() -> Image:
	return _sprite_from_pattern([
		"................",
		"......TT........",
		".....TWWT.......",
		".....TWWT.......",
		"......TT........",
		"......TT........",
		"......TT........",
		".....BBBB.......",
		"....BCCCCB......",
		"....BCCCCC......",
		".....BBBB.......",
		"......SS........",
		".....SSS........",
		"................",
		"................",
		"................"
	], {
		".": TRANSPARENT,
		"T": Color8(76, 104, 146),
		"W": Color8(196, 240, 255),
		"B": Color8(33, 52, 78),
		"C": Color8(88, 174, 228),
		"S": Color8(86, 60, 36)
	}, 4)


func _generate_building_relay_charge() -> Image:
	return _sprite_from_pattern([
		"................",
		".....TTT........",
		"....TWWWT.......",
		"....TWWWT.......",
		".....TTT........",
		".....TTT........",
		"....TTT.........",
		"...BBB..........",
		"..BCCCCB........",
		"..BCCCCCB.......",
		"...BBBB.........",
		"....SS..........",
		"...SSS..........",
		"................",
		"................",
		"................"
	], {
		".": TRANSPARENT,
		"T": Color8(76, 104, 146),
		"W": Color8(196, 240, 255),
		"B": Color8(33, 52, 78),
		"C": Color8(88, 174, 228),
		"S": Color8(86, 60, 36)
	}, 4)


func _generate_building_relay_release() -> Image:
	return _sprite_from_pattern([
		"................",
		"........TTT.....",
		".......TWWWT....",
		".......TWWWT....",
		"........TTT.....",
		"........TTT.....",
		".........TTT....",
		"..........BBB...",
		"........BCCCCB..",
		".......BCCCCCB..",
		".........BBBB...",
		"..........SS....",
		"..........SSS...",
		"................",
		"................",
		"................"
	], {
		".": TRANSPARENT,
		"T": Color8(76, 104, 146),
		"W": Color8(196, 240, 255),
		"B": Color8(33, 52, 78),
		"C": Color8(88, 174, 228),
		"S": Color8(86, 60, 36)
	}, 4)


func _generate_building_signal_a() -> Image:
	return _sprite_from_pattern([
		"................",
		".......A........",
		"......ABB.......",
		".....ABCCB......",
		"....ABCCCCB.....",
		".....ABCCB......",
		"......ABB.......",
		".......A........",
		"................",
		"................",
		"................",
		"................",
		"................",
		"................",
		"................",
		"................"
	], {
		".": TRANSPARENT,
		"A": Color8(140, 228, 255),
		"B": Color8(84, 178, 228),
		"C": Color8(232, 252, 255)
	}, 4)


func _generate_building_signal_b() -> Image:
	return _sprite_from_pattern([
		"................",
		"......AAA.......",
		".....ABBBA......",
		"....ABCCCBA.....",
		"...ABCCCCCCB....",
		"....ABCCCBA.....",
		".....ABBBA......",
		"......AAA.......",
		"................",
		"................",
		"................",
		"................",
		"................",
		"................",
		"................",
		"................"
	], {
		".": TRANSPARENT,
		"A": Color8(170, 239, 255),
		"B": Color8(98, 194, 236),
		"C": Color8(240, 253, 255)
	}, 4)


func _generate_building_bolt() -> Image:
	return _sprite_from_pattern([
		"................",
		".......bb.......",
		"......bCCb......",
		"....bbCDDCbb....",
		"...bbCDWWDCbb...",
		"....bbCDDCbb....",
		"......bCCb......",
		".......bb.......",
		"................",
		"................",
		"................",
		"................",
		"................",
		"................",
		"................",
		"................"
	], {
		".": TRANSPARENT,
		"b": Color8(52, 124, 167),
		"C": Color8(113, 216, 245),
		"D": Color8(174, 239, 255),
		"W": Color8(245, 252, 255)
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
