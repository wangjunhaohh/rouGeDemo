from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
SOURCE_PATH = ROOT / "art" / "reference" / "chinese_village_sheet.png"
OUTPUT_DIR = ROOT / "art" / "themes" / "forest_temple" / "decor"


CROP_DEFINITIONS: dict[str, tuple[int, int, int, int]] = {
    "watchtower": (50, 12, 305, 282),
    "shrine_hut": (285, 40, 553, 195),
    "stall_small": (265, 198, 462, 300),
    "stone_lantern_small": (448, 196, 560, 304),
    "market_stall": (18, 292, 310, 464),
    "market_stall_wide": (290, 298, 620, 470),
    "barrel_stack": (585, 315, 845, 455),
    "gate_arch": (530, 8, 1010, 305),
    "temple_hall": (1002, 8, 1534, 310),
    "riverside_bridge": (888, 315, 1530, 526),
    "shop_house": (18, 470, 360, 662),
    "inn_row": (330, 472, 950, 674),
    "shed_cluster": (925, 520, 1435, 679),
    "lantern_post_tall": (1432, 528, 1501, 684),
    "cart": (35, 690, 258, 875),
    "well": (238, 684, 472, 853),
    "crate_stack": (454, 722, 772, 822),
    "banner_gate": (770, 708, 985, 839),
    "cookfire": (995, 705, 1221, 875),
    "stone_lantern": (1195, 708, 1248, 816),
    "shrine_stone": (1258, 697, 1424, 840),
    "lantern_post_small": (1408, 693, 1478, 857),
    "rope_gate_rocks": (574, 860, 1008, 972),
    "lion_statue": (472, 862, 602, 981),
    "pots_and_stools": (28, 883, 470, 972),
    "blossom_tree": (1000, 885, 1149, 975),
    "rock_bamboo_garden": (1130, 846, 1532, 979),
}


def clamp_alpha(value: int) -> int:
    return max(0, min(255, value))


def remove_white_background(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            brightness = (r + g + b) / 3.0
            channel_spread = max(r, g, b) - min(r, g, b)
            if brightness > 249 and channel_spread < 8:
                pixels[x, y] = (255, 255, 255, 0)
                continue
            if brightness > 242 and channel_spread < 12:
                softened_alpha = clamp_alpha(int((255.0 - brightness) * 18.0))
                pixels[x, y] = (r, g, b, min(a, softened_alpha))
    return rgba


def extract_crop(source: Image.Image, bounds: tuple[int, int, int, int]) -> Image.Image:
    crop = source.crop(bounds)
    crop = remove_white_background(crop)
    alpha_bbox = crop.getchannel("A").getbbox()
    if alpha_bbox is None:
        return crop
    left, top, right, bottom = alpha_bbox
    padding = 8
    padded = (
        max(0, left - padding),
        max(0, top - padding),
        min(crop.width, right + padding),
        min(crop.height, bottom + padding),
    )
    return crop.crop(padded)


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    source = Image.open(SOURCE_PATH).convert("RGBA")
    for name, bounds in CROP_DEFINITIONS.items():
        extracted = extract_crop(source, bounds)
        extracted.save(OUTPUT_DIR / f"{name}.png")


if __name__ == "__main__":
    main()
