from __future__ import annotations

import argparse
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[2]
ART_DIR = ROOT / "art"
BACKGROUND_DIR = ART_DIR / "backgrounds"
ENEMY_DIR = ART_DIR / "enemies"
SPRITE_DIR = ART_DIR / "sprites"
PLAYER_DIRS_DIR = SPRITE_DIR / "player_dirs"
BRANCH_WEAPON_DIR = SPRITE_DIR / "branch_weapons"
THEME_PROP_DIR = ART_DIR / "themes" / "forest_temple" / "props"

SEED = 20260420
rng = random.Random(SEED)


INK = (34, 29, 25)
CHARCOAL = (67, 60, 55)
PAPER = (233, 224, 205)
PAPER_SHADE = (196, 184, 162)
MOSS = (116, 130, 108)
JADE = (110, 133, 132)
ASH_BLUE = (108, 118, 129)
GOLD = (167, 141, 91)
CINNABAR = (174, 71, 55)
PLUM = (108, 85, 99)
MIST = (216, 214, 205)


def clamp(value: int, minimum: int = 0, maximum: int = 255) -> int:
    return max(minimum, min(maximum, value))


def with_alpha(color: tuple[int, int, int], alpha: int) -> tuple[int, int, int, int]:
    return color[0], color[1], color[2], alpha


def ensure_parent(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def save_image(image: Image.Image, relative_path: str) -> None:
    path = ROOT / relative_path
    ensure_parent(path)
    image.save(path)


def transparent_canvas(size: tuple[int, int]) -> Image.Image:
    return Image.new("RGBA", size, (0, 0, 0, 0))


def paper_texture(size: tuple[int, int], base: tuple[int, int, int], variance: int = 10) -> Image.Image:
    width, height = size
    image = Image.new("RGBA", size, base + (255,))
    pixels = image.load()
    for y in range(height):
        for x in range(width):
            drift = int(math.sin(x * 0.07) * 4.0 + math.cos(y * 0.05) * 5.0)
            noise = rng.randint(-variance, variance) + drift
            r = clamp(base[0] + noise)
            g = clamp(base[1] + noise)
            b = clamp(base[2] + noise + rng.randint(-3, 3))
            pixels[x, y] = (r, g, b, 255)

    draw = ImageDraw.Draw(image)
    for _ in range(max(14, width // 18)):
        x = rng.randint(0, width - 1)
        tone = clamp(base[0] + rng.randint(-18, 18))
        draw.line(
            [
                (x, 0),
                (clamp(x + rng.randint(-12, 12), 0, width - 1), height // 2),
                (clamp(x + rng.randint(-18, 18), 0, width - 1), height - 1),
            ],
            fill=(tone, tone, clamp(tone - 5), 22),
            width=rng.randint(1, 2),
        )
    return image


def stamp_layer(
    base: Image.Image,
    draw_fn,
    color: tuple[int, int, int] | tuple[int, int, int, int],
    blur: float = 0.0,
    opacity: float = 1.0,
) -> None:
    alpha = color[3] if len(color) == 4 else 255
    mask = Image.new("L", base.size, 0)
    drawer = ImageDraw.Draw(mask)
    draw_fn(drawer)
    if blur > 0.0:
        mask = mask.filter(ImageFilter.GaussianBlur(blur))
    if opacity < 1.0 or alpha < 255:
        factor = int(alpha * opacity)
        mask = mask.point(lambda value: value * factor // 255)
    tint = Image.new("RGBA", base.size, color[:3] + (0,))
    tint.putalpha(mask)
    base.alpha_composite(tint)


def stroke(
    base: Image.Image,
    points: list[tuple[float, float]],
    color: tuple[int, int, int],
    width: int,
    alpha: int = 255,
    blur: float = 0.0,
) -> None:
    stamp_layer(
        base,
        lambda draw: draw.line(points, fill=255, width=width, joint="curve"),
        with_alpha(color, alpha),
        blur=blur,
    )


def blob(
    base: Image.Image,
    bounds: tuple[float, float, float, float],
    color: tuple[int, int, int],
    alpha: int = 255,
    blur: float = 0.0,
) -> None:
    x0, y0, x1, y1 = bounds
    normalized_bounds = (
        min(x0, x1),
        min(y0, y1),
        max(x0, x1),
        max(y0, y1),
    )
    stamp_layer(
        base,
        lambda draw: draw.ellipse(normalized_bounds, fill=255),
        with_alpha(color, alpha),
        blur=blur,
    )


def polygon(
    base: Image.Image,
    points: list[tuple[float, float]],
    color: tuple[int, int, int],
    alpha: int = 255,
    blur: float = 0.0,
) -> None:
    stamp_layer(
        base,
        lambda draw: draw.polygon(points, fill=255),
        with_alpha(color, alpha),
        blur=blur,
    )


def rectangle(
    base: Image.Image,
    bounds: tuple[float, float, float, float],
    color: tuple[int, int, int],
    alpha: int = 255,
    blur: float = 0.0,
) -> None:
    x0, y0, x1, y1 = bounds
    normalized_bounds = (
        min(x0, x1),
        min(y0, y1),
        max(x0, x1),
        max(y0, y1),
    )
    stamp_layer(
        base,
        lambda draw: draw.rounded_rectangle(normalized_bounds, radius=4, fill=255),
        with_alpha(color, alpha),
        blur=blur,
    )


def spatter(
    base: Image.Image,
    color: tuple[int, int, int],
    count: int,
    radius: tuple[int, int] = (1, 4),
    alpha: tuple[int, int] = (40, 120),
    region: tuple[int, int, int, int] | None = None,
) -> None:
    left = 0
    top = 0
    right, bottom = base.size
    if region is not None:
        left, top, right, bottom = region
    for _ in range(count):
        px = rng.randint(left, right - 1)
        py = rng.randint(top, bottom - 1)
        radius_value = rng.randint(radius[0], radius[1])
        alpha_value = rng.randint(alpha[0], alpha[1])
        blob(base, (px - radius_value, py - radius_value, px + radius_value, py + radius_value), color, alpha=alpha_value, blur=radius_value * 0.35)


def add_seal_mark(base: Image.Image, bounds: tuple[int, int, int, int]) -> None:
    rectangle(base, bounds, CINNABAR, alpha=215, blur=0.8)
    left, top, right, bottom = bounds
    stroke(base, [(left + 6, top + 8), (right - 7, top + 8)], PAPER, 3, alpha=170)
    stroke(base, [(left + 8, bottom - 8), (right - 8, bottom - 9)], PAPER, 3, alpha=170)
    stroke(base, [(left + 10, top + 12), (left + 10, bottom - 12)], PAPER, 3, alpha=150)
    stroke(base, [(right - 12, top + 10), (right - 12, bottom - 10)], PAPER, 3, alpha=150)


def add_paper_grain(base: Image.Image, alpha: int = 26) -> None:
    width, height = base.size
    overlay = transparent_canvas(base.size)
    pixels = overlay.load()
    for y in range(height):
        for x in range(width):
            if rng.random() > 0.08:
                continue
            tone = clamp(210 + rng.randint(-20, 18))
            pixels[x, y] = (tone, tone, tone, alpha)
    overlay = overlay.filter(ImageFilter.GaussianBlur(0.45))
    base.alpha_composite(overlay)


def create_backgrounds() -> None:
    tile = paper_texture((256, 256), (209, 205, 191), variance=12)
    for index in range(5):
        inset = 20 + index * 42
        stroke(tile, [(inset, 0), (inset + 5, 256)], CHARCOAL, 2, alpha=72)
        stroke(tile, [(0, inset), (256, inset - 4)], CHARCOAL, 2, alpha=68)
    for _ in range(11):
        x = rng.randint(26, 228)
        y = rng.randint(24, 230)
        blob(tile, (x - 18, y - 10, x + 18, y + 10), MOSS, alpha=42, blur=6)
    for _ in range(10):
        start_x = rng.randint(18, 230)
        start_y = rng.randint(18, 230)
        stroke(
            tile,
            [
                (start_x, start_y),
                (start_x + rng.randint(-24, 24), start_y + rng.randint(-10, 10)),
                (start_x + rng.randint(-36, 36), start_y + rng.randint(6, 28)),
            ],
            CHARCOAL,
            rng.randint(2, 4),
            alpha=70,
            blur=1.1,
        )
    stroke(tile, [(0, 186), (62, 174), (122, 165), (206, 152), (256, 148)], PAPER, 14, alpha=132, blur=5)
    stroke(tile, [(0, 190), (54, 178), (118, 170), (210, 156), (256, 151)], PAPER_SHADE, 6, alpha=96, blur=3)
    spatter(tile, MOSS, 180, radius=(1, 3), alpha=(18, 50))
    add_paper_grain(tile, alpha=24)
    save_image(tile, "art/backgrounds/forest_tile.png")

    overlay = transparent_canvas((256, 256))
    for _ in range(8):
        x = rng.randint(12, 220)
        y = rng.randint(10, 210)
        blob(overlay, (x - 36, y - 18, x + 48, y + 24), INK, alpha=36, blur=12)
    for _ in range(7):
        stroke(
            overlay,
            [
                (rng.randint(0, 40), rng.randint(34, 220)),
                (rng.randint(80, 170), rng.randint(10, 96)),
                (rng.randint(180, 255), rng.randint(20, 230)),
            ],
            JADE,
            rng.randint(4, 7),
            alpha=70,
            blur=4,
        )
    for _ in range(5):
        blob(overlay, (rng.randint(10, 190), rng.randint(22, 180), rng.randint(120, 255), rng.randint(110, 255)), PAPER, alpha=42, blur=18)
    save_image(overlay, "art/backgrounds/forest_overlay.png")

    vignette = transparent_canvas((512, 512))
    center_x = 256.0
    center_y = 256.0
    pixels = vignette.load()
    for y in range(512):
        for x in range(512):
            dx = (x - center_x) / center_x
            dy = (y - center_y) / center_y
            distance = math.sqrt(dx * dx + dy * dy)
            strength = max(0.0, min(1.0, (distance - 0.32) / 0.68))
            alpha = int(pow(strength, 1.7) * 210)
            pixels[x, y] = (18, 14, 12, alpha)
    save_image(vignette, "art/backgrounds/vignette.png")

    panel = paper_texture((96, 96), (50, 45, 42), variance=8)
    rectangle(panel, (6, 6, 90, 90), CHARCOAL, alpha=165, blur=1.2)
    stroke(panel, [(10, 13), (84, 12)], PAPER_SHADE, 2, alpha=105)
    stroke(panel, [(12, 84), (86, 83)], PAPER_SHADE, 2, alpha=88)
    stroke(panel, [(12, 12), (12, 84)], PAPER_SHADE, 2, alpha=96)
    stroke(panel, [(84, 12), (84, 84)], PAPER_SHADE, 2, alpha=96)
    for y in range(20, 80, 9):
        stroke(panel, [(16, y), (80, y + rng.randint(-2, 2))], (92, 83, 74), 1, alpha=42)
    add_seal_mark(panel, (64, 18, 84, 38))
    save_image(panel, "art/backgrounds/panel_tile.png")


def make_player_direction(direction: str) -> Image.Image:
    image = transparent_canvas((64, 64))
    params = {
        "down": (0, 1),
        "down_right": (1, 1),
        "right": (1, 0),
        "up_right": (1, -1),
        "up": (0, -1),
    }
    if direction.endswith("left"):
        mirrored = make_player_direction(direction.replace("left", "right"))
        return ImageOps.mirror(mirrored)

    dx, dy = params[direction]
    center_x = 32 + dx * 3
    head_y = 18 + max(dy, 0) * 1 - max(-dy, 0) * 2
    robe_top = 24
    robe_bottom = 52
    shoulder = 11 - abs(dx) * 2
    hem_shift = dx * 5

    polygon(
        image,
        [
            (center_x - shoulder, robe_top),
            (center_x + shoulder, robe_top + 1),
            (center_x + 16 + hem_shift, robe_bottom - 3),
            (center_x, robe_bottom),
            (center_x - 15 + hem_shift, robe_bottom - 4),
        ],
        INK,
        alpha=238,
        blur=1.4,
    )
    polygon(
        image,
        [
            (center_x - shoulder + 2, robe_top + 3),
            (center_x + shoulder - 1, robe_top + 4),
            (center_x + 10 + hem_shift, robe_bottom - 8),
            (center_x, robe_bottom - 5),
            (center_x - 11 + hem_shift, robe_bottom - 8),
        ],
        PAPER,
        alpha=170,
        blur=1.0,
    )
    blob(image, (center_x - 8, head_y - 6, center_x + 8, head_y + 10), CHARCOAL, alpha=230, blur=1.0)
    polygon(
        image,
        [
            (center_x - 10, head_y - 1),
            (center_x + 10, head_y - 2),
            (center_x + 7, head_y - 8),
            (center_x - 7, head_y - 9),
        ],
        INK,
        alpha=246,
        blur=0.8,
    )
    blob(image, (center_x - 5, head_y - 1, center_x + 5, head_y + 6), PAPER_SHADE, alpha=120, blur=0.6)
    stroke(
        image,
        [
            (center_x - dx * 3, robe_top + 6),
            (center_x - dx * 9, robe_top + 10 + dy * 2),
            (center_x - dx * 12, robe_top + 18 + dy * 2),
        ],
        CINNABAR,
        4,
        alpha=210,
        blur=1.2,
    )
    stroke(image, [(center_x - 6, robe_bottom - 1), (center_x - 8, 58)], INK, 4, alpha=220, blur=0.5)
    stroke(image, [(center_x + 4, robe_bottom - 3), (center_x + 7, 58)], INK, 4, alpha=220, blur=0.5)
    if direction == "up":
        stroke(image, [(center_x - 8, 22), (center_x + 8, 22)], PAPER, 2, alpha=100)
    else:
        blob(image, (center_x + dx * 2 - 2, head_y + 2, center_x + dx * 2 + 2, head_y + 5), GOLD, alpha=210, blur=0.0)
    return image


def make_player_sprite() -> Image.Image:
    return make_player_direction("down_right")


def make_wolf_sprite() -> Image.Image:
    image = transparent_canvas((64, 64))
    blob(image, (16, 24, 45, 43), CHARCOAL, alpha=235, blur=1.3)
    polygon(image, [(40, 23), (53, 28), (47, 37), (36, 34)], INK, alpha=245, blur=1.0)
    polygon(image, [(43, 23), (46, 16), (49, 24)], INK, alpha=240, blur=0.8)
    polygon(image, [(18, 28), (10, 24), (9, 31), (18, 34)], CHARCOAL, alpha=220, blur=0.8)
    stroke(image, [(17, 38), (14, 52)], INK, 5, alpha=225, blur=0.5)
    stroke(image, [(31, 39), (28, 54)], INK, 5, alpha=225, blur=0.5)
    stroke(image, [(36, 39), (36, 55)], INK, 5, alpha=225, blur=0.5)
    stroke(image, [(46, 37), (49, 52)], INK, 5, alpha=225, blur=0.5)
    stroke(image, [(14, 27), (8, 19), (5, 15)], INK, 4, alpha=195, blur=1.0)
    blob(image, (27, 25, 39, 31), PAPER_SHADE, alpha=80, blur=2.2)
    blob(image, (46, 28, 50, 32), CINNABAR, alpha=235, blur=0.4)
    return image


def make_bat_sprite() -> Image.Image:
    image = transparent_canvas((64, 64))
    polygon(image, [(8, 30), (20, 20), (28, 28), (20, 36)], INK, alpha=232, blur=1.0)
    polygon(image, [(56, 30), (44, 20), (36, 28), (44, 36)], INK, alpha=232, blur=1.0)
    polygon(image, [(16, 30), (27, 24), (32, 31), (26, 40)], CHARCOAL, alpha=220, blur=1.0)
    polygon(image, [(48, 30), (37, 24), (32, 31), (38, 40)], CHARCOAL, alpha=220, blur=1.0)
    blob(image, (24, 26, 40, 41), PLUM, alpha=215, blur=0.8)
    polygon(image, [(26, 24), (29, 18), (31, 24)], INK, alpha=255)
    polygon(image, [(33, 24), (35, 18), (38, 25)], INK, alpha=255)
    blob(image, (28, 30, 31, 33), CINNABAR, alpha=220)
    blob(image, (34, 30, 37, 33), CINNABAR, alpha=220)
    return image


def make_archer_sprite() -> Image.Image:
    image = transparent_canvas((64, 64))
    polygon(image, [(22, 22), (40, 23), (44, 49), (18, 49)], INK, alpha=235, blur=1.2)
    polygon(image, [(24, 25), (38, 26), (39, 44), (22, 44)], PAPER, alpha=125, blur=0.8)
    blob(image, (24, 12, 39, 26), CHARCOAL, alpha=240, blur=0.9)
    polygon(image, [(21, 18), (41, 18), (35, 12), (26, 12)], INK, alpha=250, blur=0.4)
    stroke(image, [(42, 25), (50, 22), (53, 36), (45, 46)], MOSS, 4, alpha=215, blur=0.8)
    stroke(image, [(20, 28), (12, 36), (16, 44)], GOLD, 3, alpha=170, blur=0.7)
    stroke(image, [(27, 48), (24, 58)], INK, 4, alpha=230)
    stroke(image, [(37, 48), (39, 58)], INK, 4, alpha=230)
    blob(image, (30, 19, 34, 22), GOLD, alpha=180)
    return image


def make_mushroom_sprite() -> Image.Image:
    image = transparent_canvas((64, 64))
    blob(image, (12, 10, 52, 34), CINNABAR, alpha=210, blur=2.6)
    blob(image, (18, 16, 46, 31), PAPER, alpha=120, blur=3.4)
    blob(image, (16, 14, 48, 30), INK, alpha=120, blur=5.0)
    polygon(image, [(24, 26), (40, 26), (44, 46), (20, 46)], PAPER_SHADE, alpha=220, blur=0.8)
    polygon(image, [(26, 28), (38, 28), (39, 44), (25, 44)], PAPER, alpha=120, blur=0.4)
    stroke(image, [(30, 46), (28, 58)], INK, 4, alpha=230)
    stroke(image, [(35, 46), (37, 58)], INK, 4, alpha=230)
    blob(image, (24, 16, 28, 20), PAPER, alpha=180, blur=0.8)
    blob(image, (36, 18, 40, 22), PAPER, alpha=180, blur=0.8)
    return image


def make_treant_sprite() -> Image.Image:
    image = transparent_canvas((64, 64))
    polygon(image, [(24, 18), (39, 18), (46, 44), (18, 44)], CHARCOAL, alpha=228, blur=1.1)
    stroke(image, [(18, 28), (10, 22), (8, 15)], INK, 4, alpha=225, blur=0.6)
    stroke(image, [(46, 26), (54, 21), (57, 14)], INK, 4, alpha=225, blur=0.6)
    stroke(image, [(30, 44), (27, 58)], INK, 5, alpha=230)
    stroke(image, [(36, 44), (39, 58)], INK, 5, alpha=230)
    blob(image, (18, 9, 46, 28), MOSS, alpha=170, blur=4.0)
    blob(image, (25, 20, 30, 25), GOLD, alpha=210)
    blob(image, (34, 20, 39, 25), GOLD, alpha=210)
    stroke(image, [(30, 30), (35, 36)], PAPER_SHADE, 2, alpha=120)
    return image


def make_mage_sprite() -> Image.Image:
    image = transparent_canvas((64, 64))
    polygon(image, [(22, 22), (40, 22), (44, 50), (18, 50)], INK, alpha=235, blur=1.1)
    polygon(image, [(25, 24), (37, 24), (39, 45), (23, 45)], PLUM, alpha=150, blur=0.9)
    polygon(image, [(24, 18), (39, 18), (34, 6), (28, 8)], CHARCOAL, alpha=240, blur=0.8)
    blob(image, (26, 15, 38, 25), PAPER_SHADE, alpha=150, blur=0.6)
    stroke(image, [(42, 24), (49, 16), (52, 44)], GOLD, 4, alpha=180, blur=0.6)
    blob(image, (47, 12, 55, 20), JADE, alpha=210, blur=1.5)
    blob(image, (30, 21, 33, 24), JADE, alpha=220)
    blob(image, (35, 21, 38, 24), JADE, alpha=220)
    stroke(image, [(27, 49), (24, 58)], INK, 4, alpha=230)
    stroke(image, [(37, 49), (40, 58)], INK, 4, alpha=230)
    return image


def make_bee_sprite() -> Image.Image:
    image = transparent_canvas((64, 64))
    blob(image, (18, 22, 46, 42), GOLD, alpha=205, blur=1.8)
    stroke(image, [(22, 24), (19, 17), (16, 13)], PAPER, 3, alpha=160, blur=1.4)
    stroke(image, [(42, 24), (45, 17), (48, 13)], PAPER, 3, alpha=160, blur=1.4)
    stroke(image, [(18, 28), (46, 28)], INK, 4, alpha=215)
    stroke(image, [(18, 34), (46, 34)], INK, 4, alpha=215)
    blob(image, (22, 18, 42, 31), PAPER, alpha=130, blur=2.1)
    stroke(image, [(24, 42), (18, 52)], INK, 3, alpha=220)
    stroke(image, [(40, 42), (46, 52)], INK, 3, alpha=220)
    blob(image, (25, 27, 28, 30), CINNABAR, alpha=230)
    blob(image, (36, 27, 39, 30), CINNABAR, alpha=230)
    return image


def make_wisp_sprite() -> Image.Image:
    image = transparent_canvas((64, 64))
    blob(image, (16, 16, 48, 46), JADE, alpha=120, blur=7.0)
    blob(image, (20, 20, 44, 40), PAPER, alpha=150, blur=4.0)
    blob(image, (24, 24, 40, 36), PAPER, alpha=210, blur=1.4)
    stroke(image, [(30, 38), (24, 50), (20, 58)], CHARCOAL, 4, alpha=110, blur=2.0)
    stroke(image, [(34, 38), (39, 50), (44, 58)], CHARCOAL, 4, alpha=110, blur=2.0)
    blob(image, (27, 27, 30, 30), JADE, alpha=220)
    blob(image, (34, 27, 37, 30), JADE, alpha=220)
    return image


def make_spider_boss_sprite() -> Image.Image:
    image = transparent_canvas((80, 80))
    blob(image, (24, 22, 56, 50), CHARCOAL, alpha=235, blur=1.5)
    blob(image, (29, 24, 51, 42), CINNABAR, alpha=150, blur=4.0)
    polygon(image, [(30, 26), (50, 26), (55, 40), (25, 40)], INK, alpha=205, blur=1.0)
    for start, end in [
        ((26, 36), (10, 18)),
        ((24, 41), (8, 34)),
        ((26, 46), (10, 54)),
        ((54, 36), (70, 18)),
        ((56, 41), (72, 34)),
        ((54, 46), (70, 54)),
    ]:
        stroke(image, [start, ((start[0] + end[0]) // 2, (start[1] + end[1]) // 2), end], INK, 5, alpha=225, blur=0.9)
    blob(image, (34, 31, 38, 35), PAPER, alpha=210)
    blob(image, (42, 31, 46, 35), PAPER, alpha=210)
    stroke(image, [(38, 38), (42, 42)], PAPER_SHADE, 2, alpha=100)
    return image


def make_elite_sprite() -> Image.Image:
    image = transparent_canvas((64, 64))
    polygon(image, [(20, 18), (44, 18), (48, 48), (16, 48)], INK, alpha=236, blur=1.2)
    polygon(image, [(23, 20), (41, 21), (43, 42), (21, 42)], PAPER_SHADE, alpha=135, blur=0.9)
    polygon(image, [(24, 15), (40, 15), (37, 8), (27, 8)], GOLD, alpha=180, blur=1.0)
    blob(image, (24, 20, 31, 29), PAPER, alpha=145, blur=1.0)
    blob(image, (33, 20, 40, 29), PAPER, alpha=145, blur=1.0)
    blob(image, (27, 23, 30, 26), CINNABAR, alpha=235)
    blob(image, (34, 23, 37, 26), CINNABAR, alpha=235)
    stroke(image, [(23, 35), (19, 58)], INK, 4, alpha=225)
    stroke(image, [(41, 35), (45, 58)], INK, 4, alpha=225)
    return image


def make_player_projectile_sprite() -> Image.Image:
    image = transparent_canvas((32, 32))
    stroke(image, [(8, 20), (16, 6), (24, 13)], CINNABAR, 8, alpha=165, blur=2.0)
    stroke(image, [(10, 20), (16, 9), (22, 14)], PAPER, 4, alpha=215, blur=1.0)
    stroke(image, [(12, 22), (16, 12)], INK, 2, alpha=140, blur=0.4)
    return image


def make_enemy_projectile_sprite() -> Image.Image:
    image = transparent_canvas((32, 32))
    blob(image, (8, 8, 24, 24), CHARCOAL, alpha=150, blur=3.0)
    blob(image, (11, 11, 21, 21), JADE, alpha=210, blur=1.0)
    blob(image, (14, 14, 18, 18), PAPER, alpha=210)
    return image


def make_experience_orb_sprite() -> Image.Image:
    image = transparent_canvas((48, 48))
    blob(image, (10, 10, 38, 38), GOLD, alpha=120, blur=5.0)
    polygon(image, [(24, 8), (34, 24), (24, 40), (14, 24)], PAPER, alpha=200, blur=0.8)
    blob(image, (18, 18, 30, 30), CINNABAR, alpha=175, blur=1.2)
    return image


def make_weapon_blaster_sprite() -> Image.Image:
    image = transparent_canvas((64, 48))
    polygon(image, [(14, 30), (36, 22), (48, 23), (50, 28), (36, 34), (18, 36)], INK, alpha=230, blur=0.8)
    polygon(image, [(18, 29), (35, 24), (45, 25), (35, 31), (22, 33)], PAPER_SHADE, alpha=120, blur=0.7)
    stroke(image, [(17, 31), (14, 38)], CINNABAR, 3, alpha=215, blur=0.8)
    blob(image, (42, 24, 50, 30), PAPER, alpha=215, blur=0.5)
    return image


def make_weapon_flash_sprite() -> Image.Image:
    image = transparent_canvas((64, 48))
    stroke(image, [(18, 28), (35, 22), (51, 20)], PAPER, 8, alpha=180, blur=1.5)
    stroke(image, [(18, 28), (35, 22), (52, 20)], GOLD, 4, alpha=205, blur=0.8)
    stroke(image, [(26, 18), (34, 26), (45, 31)], PAPER, 3, alpha=170, blur=0.8)
    return image


def make_card_pickup_sprite() -> Image.Image:
    image = transparent_canvas((64, 48))
    rectangle(image, (12, 8, 52, 40), CHARCOAL, alpha=228, blur=0.9)
    rectangle(image, (16, 11, 48, 37), PAPER_SHADE, alpha=140, blur=0.8)
    stroke(image, [(22, 16), (42, 16)], PAPER, 2, alpha=120)
    stroke(image, [(22, 24), (42, 24)], CINNABAR, 3, alpha=165, blur=0.5)
    stroke(image, [(22, 32), (42, 32)], PAPER, 2, alpha=120)
    return image


def make_card_icon_sprite(icon_type: str) -> Image.Image:
    image = transparent_canvas((64, 48))
    rectangle(image, (10, 8, 54, 40), INK, alpha=220, blur=1.0)
    rectangle(image, (14, 11, 50, 37), PAPER_SHADE, alpha=125, blur=0.8)
    if icon_type == "buff":
        stroke(image, [(21, 31), (31, 15), (42, 31)], MOSS, 4, alpha=210, blur=0.8)
        stroke(image, [(28, 25), (38, 20)], MOSS, 3, alpha=170)
    elif icon_type == "risk":
        stroke(image, [(22, 15), (42, 34)], CINNABAR, 5, alpha=225, blur=0.6)
        stroke(image, [(40, 15), (22, 33)], INK, 3, alpha=180, blur=0.5)
    else:
        blob(image, (23, 15, 41, 33), JADE, alpha=150, blur=2.8)
        stroke(image, [(23, 25), (31, 18), (40, 24), (33, 33), (24, 28)], PAPER, 3, alpha=185, blur=0.7)
    return image


def make_tree_sprite(giant: bool = False, twisted: bool = False, compact: bool = False) -> Image.Image:
    size = (256, 256) if giant else ((192, 256) if twisted else (224, 224))
    image = transparent_canvas(size)
    width, height = size
    trunk_center = width // 2 + (-10 if twisted else 0)
    canopy_top = 24 if giant else 34
    canopy_bottom = 160 if giant else 144
    for _ in range(7 if giant else 5):
        radius_x = rng.randint(34, 56 if giant else 42)
        radius_y = rng.randint(26, 38 if giant else 34)
        cx = trunk_center + rng.randint(-56, 56)
        cy = rng.randint(canopy_top, canopy_bottom)
        blob(
            image,
            (cx - radius_x, cy - radius_y, cx + radius_x, cy + radius_y),
            MOSS if not compact else JADE,
            alpha=160,
            blur=8.0,
        )
        blob(
            image,
            (cx - radius_x + 10, cy - radius_y + 8, cx + radius_x - 8, cy + radius_y - 8),
            PAPER,
            alpha=48,
            blur=9.0,
        )

    trunk_points = [
        (trunk_center - 18, height - 44),
        (trunk_center - 28, height - 112),
        (trunk_center - 14 if not twisted else trunk_center - 36, height - 170),
        (trunk_center + 6 if not twisted else trunk_center + 18, height - 188),
        (trunk_center + 30, height - 108),
        (trunk_center + 22, height - 44),
    ]
    polygon(image, trunk_points, CHARCOAL, alpha=235, blur=1.2)
    stroke(image, [(trunk_center - 6, height - 182), (trunk_center - 22, height - 110), (trunk_center - 18, height - 44)], GOLD, 8, alpha=110, blur=1.7)
    stroke(image, [(trunk_center + 8, height - 184), (trunk_center + 18, height - 108), (trunk_center + 20, height - 46)], GOLD, 7, alpha=90, blur=1.5)

    if twisted:
        stroke(image, [(trunk_center - 4, height - 158), (trunk_center + 38, height - 138), (trunk_center + 60, height - 170)], INK, 7, alpha=165, blur=1.0)
    else:
        stroke(image, [(trunk_center + 8, height - 152), (trunk_center + 46, height - 136), (trunk_center + 70, height - 150)], INK, 6, alpha=150, blur=1.0)
    stroke(image, [(trunk_center - 16, height - 142), (trunk_center - 56, height - 132), (trunk_center - 76, height - 156)], INK, 6, alpha=150, blur=1.0)

    for _ in range(12):
        blob(image, (rng.randint(trunk_center - 40, trunk_center + 40), height - rng.randint(32, 62), rng.randint(trunk_center - 10, trunk_center + 70), height - rng.randint(10, 22)), PAPER_SHADE, alpha=55, blur=3.0)
    return image


def make_rock_sprite(width: int, height: int, tall: bool = False) -> Image.Image:
    image = transparent_canvas((width, height))
    margin = 14
    points = [
        (margin + rng.randint(0, 18), height - 32),
        (width * 0.28, rng.randint(height // 3, height // 2)),
        (width * 0.52, rng.randint(10, height // 3)),
        (width - margin - rng.randint(0, 20), height // 3 + rng.randint(0, 22)),
        (width - margin, height - 30),
        (margin + 8, height - 14),
    ]
    polygon(image, [(int(x), int(y)) for x, y in points], CHARCOAL, alpha=230, blur=1.4)
    polygon(
        image,
        [(int(points[0][0] + 10), int(points[0][1] - 12)), (int(width * 0.33), int(height // 2)), (int(width * 0.52), int(height // 4 + 8)), (int(width - margin - 18), int(height // 2 + 8)), (int(width - margin - 14), int(height - 34)), (int(margin + 20), int(height - 26))],
        PAPER_SHADE,
        alpha=115,
        blur=1.1,
    )
    for _ in range(4 if not tall else 6):
        stroke(
            image,
            [
                (rng.randint(width // 5, width - width // 5), rng.randint(height // 4, height - 22)),
                (rng.randint(width // 6, width - width // 6), rng.randint(height // 5, height - 12)),
            ],
            INK,
            rng.randint(2, 4),
            alpha=120,
            blur=0.7,
        )
    return image


def make_grass_sprite() -> Image.Image:
    image = transparent_canvas((128, 96))
    for x in range(18, 110, 12):
        stroke(
            image,
            [(x, 92), (x + rng.randint(-8, 8), rng.randint(36, 58)), (x + rng.randint(-12, 12), rng.randint(14, 34))],
            MOSS,
            rng.randint(5, 7),
            alpha=175,
            blur=1.2,
        )
    stroke(image, [(26, 82), (44, 52), (58, 28)], PAPER, 3, alpha=110, blur=1.0)
    return image


def make_vine_sprite() -> Image.Image:
    image = transparent_canvas((128, 192))
    stroke(image, [(64, 0), (52, 42), (68, 94), (56, 148), (72, 190)], INK, 7, alpha=180, blur=1.1)
    for index in range(6):
        y = 24 + index * 28
        direction = -1 if index % 2 == 0 else 1
        stroke(image, [(64, y), (64 + 24 * direction, y + 10), (64 + 36 * direction, y + 18)], MOSS, 5, alpha=160, blur=1.0)
        blob(image, (64 + 20 * direction, y + 2, 64 + 46 * direction, y + 24), PAPER, alpha=75, blur=2.6)
    return image


def paste_center(base: Image.Image, overlay: Image.Image, offset: tuple[int, int] = (0, 0)) -> Image.Image:
    canvas = transparent_canvas(base.size)
    x = (base.width - overlay.width) // 2 + offset[0]
    y = (base.height - overlay.height) // 2 + offset[1]
    canvas.alpha_composite(overlay, (x, y))
    return canvas


def make_sword_base() -> Image.Image:
    image = transparent_canvas((28, 56))
    polygon(image, [(11, 6), (17, 6), (20, 36), (14, 52), (8, 36)], PAPER, alpha=205, blur=0.7)
    polygon(image, [(11, 10), (17, 10), (18, 36), (14, 45), (10, 36)], INK, alpha=155, blur=0.5)
    rectangle(image, (6, 34, 22, 39), GOLD, alpha=185, blur=0.4)
    stroke(image, [(14, 39), (14, 51)], CHARCOAL, 5, alpha=220)
    stroke(image, [(14, 48), (8, 54)], CINNABAR, 3, alpha=205, blur=0.7)
    return image


def make_staff_base() -> Image.Image:
    image = transparent_canvas((28, 58))
    stroke(image, [(14, 6), (14, 52)], CHARCOAL, 6, alpha=220, blur=0.4)
    blob(image, (6, 4, 22, 20), MOSS, alpha=160, blur=2.0)
    blob(image, (9, 7, 19, 17), PAPER, alpha=185, blur=0.6)
    stroke(image, [(6, 24), (22, 20)], CINNABAR, 3, alpha=180, blur=0.8)
    return image


def make_relay_base() -> Image.Image:
    image = transparent_canvas((30, 56))
    rectangle(image, (7, 16, 23, 38), INK, alpha=225, blur=0.8)
    rectangle(image, (10, 20, 20, 34), PAPER_SHADE, alpha=120, blur=0.5)
    blob(image, (9, 6, 21, 18), JADE, alpha=165, blur=1.5)
    blob(image, (12, 9, 18, 15), PAPER, alpha=205, blur=0.4)
    stroke(image, [(15, 38), (15, 52)], CHARCOAL, 5, alpha=220)
    stroke(image, [(10, 24), (20, 24)], CINNABAR, 2, alpha=150)
    return image


def rotate_frame(base: Image.Image, angle: float, canvas_size: tuple[int, int], offset: tuple[int, int]) -> Image.Image:
    rotated = base.rotate(angle, resample=Image.Resampling.BICUBIC, expand=True)
    canvas = transparent_canvas(canvas_size)
    x = (canvas.width - rotated.width) // 2 + offset[0]
    y = (canvas.height - rotated.height) // 2 + offset[1]
    canvas.alpha_composite(rotated, (x, y))
    return canvas


def make_tank_blade_idle() -> Image.Image:
    return rotate_frame(make_sword_base(), 18, (64, 64), (0, 6))


def make_tank_blade_windup() -> Image.Image:
    return rotate_frame(make_sword_base(), -28, (64, 64), (-8, 6))


def make_tank_blade_swing() -> Image.Image:
    return rotate_frame(make_sword_base(), 62, (64, 64), (8, 4))


def make_tank_blade_recover() -> Image.Image:
    return rotate_frame(make_sword_base(), 44, (64, 64), (6, 6))


def make_tank_slash_a() -> Image.Image:
    image = transparent_canvas((64, 64))
    stroke(image, [(12, 48), (28, 28), (50, 18)], PAPER, 10, alpha=165, blur=2.0)
    stroke(image, [(12, 48), (28, 28), (50, 18)], GOLD, 5, alpha=220, blur=0.9)
    return image


def make_tank_slash_b() -> Image.Image:
    image = transparent_canvas((64, 64))
    stroke(image, [(16, 50), (32, 30), (54, 20)], PAPER, 8, alpha=150, blur=2.0)
    stroke(image, [(16, 50), (32, 30), (54, 20)], CINNABAR, 4, alpha=160, blur=0.8)
    return image


def make_debuff_staff_idle() -> Image.Image:
    return rotate_frame(make_staff_base(), 8, (64, 64), (0, 5))


def make_debuff_staff_cast() -> Image.Image:
    return rotate_frame(make_staff_base(), -14, (64, 64), (-4, 3))


def make_debuff_staff_release() -> Image.Image:
    return rotate_frame(make_staff_base(), 28, (64, 64), (6, 3))


def make_debuff_cast_a() -> Image.Image:
    image = transparent_canvas((64, 64))
    blob(image, (18, 18, 46, 46), CINNABAR, alpha=120, blur=6.0)
    stroke(image, [(22, 38), (32, 22), (42, 30), (34, 42), (24, 34)], PAPER, 4, alpha=205, blur=0.8)
    return image


def make_debuff_cast_b() -> Image.Image:
    image = transparent_canvas((64, 64))
    blob(image, (16, 16, 48, 48), CHARCOAL, alpha=95, blur=7.0)
    stroke(image, [(20, 42), (30, 20), (46, 24), (40, 44), (24, 36)], CINNABAR, 5, alpha=180, blur=1.1)
    stroke(image, [(24, 40), (31, 24), (42, 28), (37, 39), (27, 35)], PAPER, 2, alpha=195, blur=0.5)
    return image


def make_debuff_orb() -> Image.Image:
    image = transparent_canvas((64, 64))
    blob(image, (16, 16, 48, 48), CINNABAR, alpha=120, blur=6.0)
    blob(image, (22, 22, 42, 42), GOLD, alpha=140, blur=2.0)
    stroke(image, [(18, 34), (30, 20), (45, 31), (34, 46), (21, 36)], PAPER, 3, alpha=180, blur=0.8)
    return image


def make_building_relay_idle() -> Image.Image:
    return rotate_frame(make_relay_base(), 0, (64, 64), (0, 6))


def make_building_relay_charge() -> Image.Image:
    return rotate_frame(make_relay_base(), -10, (64, 64), (-2, 5))


def make_building_relay_release() -> Image.Image:
    return rotate_frame(make_relay_base(), 16, (64, 64), (3, 5))


def make_building_signal_a() -> Image.Image:
    image = transparent_canvas((64, 64))
    blob(image, (18, 18, 46, 46), JADE, alpha=90, blur=6.0)
    stroke(image, [(22, 32), (32, 20), (42, 32), (32, 44), (22, 32)], PAPER, 3, alpha=195, blur=0.6)
    return image


def make_building_signal_b() -> Image.Image:
    image = transparent_canvas((64, 64))
    blob(image, (16, 16, 48, 48), JADE, alpha=105, blur=7.0)
    stroke(image, [(18, 32), (32, 18), (46, 32), (32, 46), (18, 32)], PAPER, 4, alpha=180, blur=0.8)
    stroke(image, [(22, 32), (32, 22), (42, 32), (32, 42), (22, 32)], CINNABAR, 2, alpha=150, blur=0.5)
    return image


def make_building_bolt() -> Image.Image:
    image = transparent_canvas((64, 64))
    stroke(image, [(24, 14), (34, 26), (28, 34), (40, 50)], PAPER, 8, alpha=155, blur=2.0)
    stroke(image, [(24, 14), (34, 26), (28, 34), (40, 50)], JADE, 4, alpha=210, blur=0.7)
    return image


def create_core_assets() -> None:
    create_backgrounds()

    save_image(make_player_sprite(), "art/sprites/player.png")
    for direction in ["down", "down_right", "right", "up_right", "up", "up_left", "left", "down_left"]:
        save_image(make_player_direction(direction), f"art/sprites/player_dirs/player_{direction}.png")

    save_image(make_archer_sprite(), "art/enemies/archer.png")
    save_image(make_mushroom_sprite(), "art/enemies/mushroom.png")
    save_image(make_bat_sprite(), "art/enemies/bat.png")
    save_image(make_wolf_sprite(), "art/enemies/wolf.png")
    save_image(make_treant_sprite(), "art/enemies/treant.png")
    save_image(make_mage_sprite(), "art/enemies/mage.png")
    save_image(make_bee_sprite(), "art/enemies/bee.png")
    save_image(make_wisp_sprite(), "art/enemies/wisp.png")
    save_image(make_spider_boss_sprite(), "art/enemies/spider_boss.png")
    save_image(make_elite_sprite(), "art/enemies/elite.png")
    save_image(make_enemy_projectile_sprite(), "art/enemies/projectile_enemy.png")

    save_image(make_player_projectile_sprite(), "art/sprites/projectile_player.png")
    save_image(make_experience_orb_sprite(), "art/sprites/experience_orb.png")
    save_image(make_weapon_blaster_sprite(), "art/sprites/weapon_blaster.png")
    save_image(make_weapon_flash_sprite(), "art/sprites/weapon_flash.png")
    save_image(make_card_pickup_sprite(), "art/sprites/card_pickup.png")
    save_image(make_card_icon_sprite("buff"), "art/sprites/card_buff.png")
    save_image(make_card_icon_sprite("risk"), "art/sprites/card_risk.png")
    save_image(make_card_icon_sprite("unknown"), "art/sprites/card_unknown.png")

    save_image(make_tree_sprite(giant=True), "art/themes/forest_temple/props/forest_tree_giant.png")
    save_image(make_tree_sprite(twisted=True), "art/themes/forest_temple/props/forest_tree_twisted.png")
    save_image(make_tree_sprite(compact=True), "art/themes/forest_temple/props/forest_tree.png")
    save_image(make_rock_sprite(144, 112), "art/themes/forest_temple/props/forest_rock.png")
    save_image(make_rock_sprite(176, 112), "art/themes/forest_temple/props/forest_rock_broad.png")
    save_image(make_rock_sprite(120, 176, tall=True), "art/themes/forest_temple/props/forest_rock_monolith.png")
    save_image(make_grass_sprite(), "art/themes/forest_temple/props/forest_grass.png")
    save_image(make_vine_sprite(), "art/themes/forest_temple/props/forest_vine.png")


def create_branch_assets() -> None:
    save_image(make_tank_blade_idle(), "art/sprites/branch_weapons/tank_blade_idle.png")
    save_image(make_tank_blade_windup(), "art/sprites/branch_weapons/tank_blade_windup.png")
    save_image(make_tank_blade_swing(), "art/sprites/branch_weapons/tank_blade_swing.png")
    save_image(make_tank_blade_recover(), "art/sprites/branch_weapons/tank_blade_recover.png")
    save_image(make_tank_slash_a(), "art/sprites/branch_weapons/tank_slash_a.png")
    save_image(make_tank_slash_b(), "art/sprites/branch_weapons/tank_slash_b.png")

    save_image(make_debuff_staff_idle(), "art/sprites/branch_weapons/debuff_staff_idle.png")
    save_image(make_debuff_staff_cast(), "art/sprites/branch_weapons/debuff_staff_cast.png")
    save_image(make_debuff_staff_release(), "art/sprites/branch_weapons/debuff_staff_release.png")
    save_image(make_debuff_cast_a(), "art/sprites/branch_weapons/debuff_cast_a.png")
    save_image(make_debuff_cast_b(), "art/sprites/branch_weapons/debuff_cast_b.png")
    save_image(make_debuff_orb(), "art/sprites/branch_weapons/debuff_orb.png")

    save_image(make_building_relay_idle(), "art/sprites/branch_weapons/building_relay_idle.png")
    save_image(make_building_relay_charge(), "art/sprites/branch_weapons/building_relay_charge.png")
    save_image(make_building_relay_release(), "art/sprites/branch_weapons/building_relay_release.png")
    save_image(make_building_signal_a(), "art/sprites/branch_weapons/building_signal_a.png")
    save_image(make_building_signal_b(), "art/sprites/branch_weapons/building_signal_b.png")
    save_image(make_building_bolt(), "art/sprites/branch_weapons/building_bolt.png")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate ink-wash themed art assets.")
    parser.add_argument(
        "--group",
        choices=("all", "core", "branch"),
        default="all",
        help="Asset group to generate.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    if args.group in {"all", "core"}:
        create_core_assets()
    if args.group in {"all", "branch"}:
        create_branch_assets()


if __name__ == "__main__":
    main()
