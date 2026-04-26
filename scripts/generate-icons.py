"""
Generate site icon set: OG social card + favicons.

Usage:  python3 scripts/generate-icons.py    (run from repo root)

Reads:
  - assets/phone_bouquet.png  (favicon source — bouquet cropped tightly)
  - assets/tech_birdhouse.png (OG card source — full hero image)

Writes (to repo root):
  - og-card.png       1200x630   social card
  - favicon-32.png    32x32
  - favicon-180.png   180x180    apple-touch-icon
  - favicon-192.png   192x192    android
  - favicon-512.png   512x512    android / pwa
  - favicon.ico       16+32+48   legacy multi-size ico

Idempotent — overwrites prior outputs.
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets"

# Tunable favicon crop bounds, in pixels, against the 1024x1024 phone_bouquet source.
# Tightens onto the bouquet (upper-center of the source image), excluding the phone
# and the figure. Adjust if the crop feels off.
BOUQUET_CROP = (60, 10, 540, 490)  # (left, upper, right, lower) — 480x480 square, bouquet only (excludes phone + figure)

# Threshold for converting near-white pixels to transparent in the favicon.
# 245 leaves a thin off-white halo intact (avoids speckle on petal edges); raise toward
# 255 for cleaner edges if the colorful interior reads well at 16px.
WHITE_THRESHOLD = 245

OG_CANVAS = (1200, 630)
HERO_HEIGHT = 590  # leaves 20px top/bottom padding on the 630-tall canvas

FAVICON_SIZES = [32, 180, 192, 512]
ICO_SIZES = [(16, 16), (32, 32), (48, 48)]


def alpha_key_white(im: Image.Image, threshold: int) -> Image.Image:
    """Convert near-white pixels to fully transparent. Returns RGBA."""
    im = im.convert("RGBA")
    pixels = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if r >= threshold and g >= threshold and b >= threshold:
                pixels[x, y] = (r, g, b, 0)
    return im


def build_favicon_master() -> Image.Image:
    """Crop the bouquet, alpha-key white, return as RGBA at native crop size."""
    src = Image.open(ASSETS / "phone_bouquet.png").convert("RGB")
    cropped = src.crop(BOUQUET_CROP)
    return alpha_key_white(cropped, WHITE_THRESHOLD)


def build_og_card() -> Image.Image:
    """Hero centered on a 1200x630 white canvas."""
    canvas = Image.new("RGB", OG_CANVAS, (255, 255, 255))
    hero = Image.open(ASSETS / "tech_birdhouse.png").convert("RGBA")
    # Scale proportionally to HERO_HEIGHT
    scale = HERO_HEIGHT / hero.height
    new_w = int(round(hero.width * scale))
    new_h = HERO_HEIGHT
    hero_resized = hero.resize((new_w, new_h), Image.LANCZOS)
    x = (OG_CANVAS[0] - new_w) // 2
    y = (OG_CANVAS[1] - new_h) // 2
    canvas.paste(hero_resized, (x, y), hero_resized)
    return canvas


def main() -> None:
    favicon_master = build_favicon_master()
    for size in FAVICON_SIZES:
        out = favicon_master.resize((size, size), Image.LANCZOS)
        out.save(ROOT / f"favicon-{size}.png", "PNG")
        print(f"wrote favicon-{size}.png")

    favicon_master.save(ROOT / "favicon.ico", sizes=ICO_SIZES)
    print(f"wrote favicon.ico ({ICO_SIZES})")

    og = build_og_card()
    og.save(ROOT / "og-card.png", "PNG", optimize=True)
    print("wrote og-card.png")


if __name__ == "__main__":
    main()
