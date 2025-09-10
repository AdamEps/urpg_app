#!/usr/bin/env python3
import os
from math import cos, sin, radians
from random import Random

from PIL import Image, ImageDraw, ImageFilter


def ensure_dir(path: str) -> None:
    if not os.path.isdir(path):
        os.makedirs(path, exist_ok=True)


def generate_radial_gradient(size: int, inner_color, outer_color) -> Image.Image:
    cx = cy = size // 2
    max_dist = (2 * (cx ** 2)) ** 0.5
    gradient = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = gradient.load()
    for y in range(size):
        for x in range(size):
            dx = x - cx
            dy = y - cy
            dist = (dx * dx + dy * dy) ** 0.5
            t = min(1.0, dist / max_dist)
            r = int(inner_color[0] * (1 - t) + outer_color[0] * t)
            g = int(inner_color[1] * (1 - t) + outer_color[1] * t)
            b = int(inner_color[2] * (1 - t) + outer_color[2] * t)
            a = 255
            px[x, y] = (r, g, b, a)
    return gradient


def generate_noise(size: int, seed: int, low: int = 0, high: int = 55) -> Image.Image:
    rnd = Random(seed)
    noise = Image.new("L", (size, size))
    p = noise.load()
    for y in range(size):
        for x in range(size):
            p[x, y] = rnd.randint(low, high)
    noise = noise.filter(ImageFilter.GaussianBlur(radius=1.4))
    return noise


def draw_planet_base(size: int) -> Image.Image:
    # Base gradient: icy blue to white
    base = generate_radial_gradient(size, (180, 210, 255), (235, 245, 255))

    # Add subtle blue-white banding via overlay gradients
    overlay = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    odraw = ImageDraw.Draw(overlay)
    for i in range(6):
        y0 = int(size * (0.15 + 0.12 * i))
        y1 = y0 + int(size * 0.04)
        color = (180, 200, 240, 36)
        odraw.rectangle([0, y0, size, y1], fill=color)
    base = Image.alpha_composite(base, overlay)

    # Add bluish-brown patches
    patches = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    pdraw = ImageDraw.Draw(patches)
    rnd = Random(1337)
    for _ in range(18):
        cx = rnd.randint(int(size * 0.2), int(size * 0.8))
        cy = rnd.randint(int(size * 0.2), int(size * 0.8))
        rx = rnd.randint(int(size * 0.04), int(size * 0.12))
        ry = rnd.randint(int(size * 0.03), int(size * 0.10))
        hue = rnd.random()
        # mix bluish-brown palette
        if hue < 0.5:
            color = (120, 150, 180, rnd.randint(40, 80))
        else:
            color = (150, 130, 110, rnd.randint(40, 80))
        bbox = [cx - rx, cy - ry, cx + rx, cy + ry]
        pdraw.ellipse(bbox, fill=color)
    patches = patches.filter(ImageFilter.GaussianBlur(radius=3))
    base = Image.alpha_composite(base, patches)

    # Subtle noise texture
    noise = generate_noise(size, seed=4242)
    noise_rgba = Image.merge("RGBA", (noise, noise, noise, noise.point(lambda a: int(a * 0.7))))
    base = Image.alpha_composite(base, noise_rgba)

    return base


def mask_circle(img: Image.Image, diameter: int) -> Image.Image:
    mask = Image.new("L", img.size, 0)
    draw = ImageDraw.Draw(mask)
    cx = cy = img.size[0] // 2
    r = diameter // 2
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)
    circ = img.copy()
    circ.putalpha(mask)
    return circ


def add_terminator_shadow(img: Image.Image, diameter: int, angle_deg: float = 30.0) -> Image.Image:
    # Create a left-to-right shadow gradient, then rotate
    w, h = img.size
    grad = Image.new("L", (w, h))
    px = grad.load()
    for y in range(h):
        for x in range(w):
            t = x / (w - 1)
            # Darken right side
            val = int(255 * (0.25 + 0.75 * (1 - t)))
            px[x, y] = val
    grad = grad.rotate(angle_deg, resample=Image.BICUBIC, expand=False)
    shade = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    shade.putalpha(grad.point(lambda a: int(a * 0.6)))
    shaded = Image.alpha_composite(img, shade)
    # Keep within the circle
    shaded = mask_circle(shaded, diameter)
    return shaded


def render_rings(canvas_size: int, outer_radius: int, inner_radius: int, tilt_deg: float = 20.0) -> Image.Image:
    rings = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(rings)
    cx = cy = canvas_size // 2

    # Draw outer ellipse
    bbox_outer = [cx - outer_radius, cy - int(outer_radius * 0.38),
                  cx + outer_radius, cy + int(outer_radius * 0.38)]
    draw.ellipse(bbox_outer, fill=(210, 220, 230, 90))

    # Cut inner ellipse to make a ring
    bbox_inner = [cx - inner_radius, cy - int(inner_radius * 0.36),
                  cx + inner_radius, cy + int(inner_radius * 0.36)]
    inner = Image.new("L", (canvas_size, canvas_size), 0)
    ImageDraw.Draw(inner).ellipse(bbox_inner, fill=255)
    rings.putalpha(ImageChops.subtract(rings.split()[3], inner))

    # Add faint ring banding
    bands = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    bdraw = ImageDraw.Draw(bands)
    for i in range(6):
        r = inner_radius + int((outer_radius - inner_radius) * (i + 0.5) / 6)
        bbox = [cx - r, cy - int(r * 0.38), cx + r, cy + int(r * 0.38)]
        alpha = 26 if i % 2 == 0 else 14
        bdraw.ellipse(bbox, outline=(185, 195, 210, alpha), width=2)
    rings = Image.alpha_composite(rings, bands)

    # Rotate for tilt
    rings = rings.rotate(tilt_deg, resample=Image.BICUBIC, expand=False)
    rings = rings.filter(ImageFilter.GaussianBlur(radius=0.8))
    return rings


def main():
    project_root = "/Users/adamepstein/Desktop/urpg_app"
    out_png = os.path.join(project_root, "Locations", "Taragam-3.png")
    assets_dir = os.path.join(project_root, "UniverseRPG", "UniverseRPG", "Assets.xcassets")
    imageset_dir = os.path.join(assets_dir, "Taragam3.imageset")
    imageset_png = os.path.join(imageset_dir, "Taragam-3.png")

    ensure_dir(os.path.dirname(out_png))
    ensure_dir(imageset_dir)

    canvas_size = 1024
    planet_diameter = 720

    # Transparent canvas
    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))

    # Planet base with texture
    base = draw_planet_base(canvas_size)
    planet = mask_circle(base, planet_diameter)
    planet = add_terminator_shadow(planet, planet_diameter, angle_deg=30)

    # Rings
    rings = render_rings(canvas_size, outer_radius=470, inner_radius=380, tilt_deg=20)

    # Composite: backside of rings, then planet, then front-side rings (simple hack by splitting)
    # We'll assume ring centerline passes behind center of planet for a partial occlusion effect
    # Create a mask that hides middle band where planet sits (front-side effect)
    cx = cy = canvas_size // 2
    occlusion_mask = Image.new("L", (canvas_size, canvas_size), 0)
    ImageDraw.Draw(occlusion_mask).ellipse([cx - planet_diameter // 2, cy - planet_diameter // 2,
                                            cx + planet_diameter // 2, cy + planet_diameter // 2], fill=255)

    # Back rings: subtract occlusion where planet sits
    back_alpha = ImageChops.subtract(rings.split()[3], occlusion_mask)
    back_rings = rings.copy()
    back_rings.putalpha(back_alpha)

    # Front rings: intersect with a tightened band to simulate front overlap
    front_alpha = ImageChops.multiply(rings.split()[3], occlusion_mask.filter(ImageFilter.GaussianBlur(4)))
    front_rings = rings.copy()
    front_rings.putalpha(front_alpha)

    # Composite all
    composed = Image.alpha_composite(canvas, back_rings)
    composed = Image.alpha_composite(composed, planet)
    composed = Image.alpha_composite(composed, front_rings)

    # Save outputs
    composed.save(out_png, "PNG")

    # Save into imageset
    composed.save(imageset_png, "PNG")
    contents_json = {
        "images": [
            {"filename": "Taragam-3.png", "idiom": "universal", "scale": "1x"}
        ],
        "info": {"author": "xcode", "version": 1}
    }

    import json
    with open(os.path.join(imageset_dir, "Contents.json"), "w") as f:
        json.dump(contents_json, f, indent=2)

    print(f"✅ Generated {out_png} and added asset set at {imageset_dir}")


if __name__ == "__main__":
    # Pillow is required
    try:
        from PIL import ImageChops  # noqa: F401
    except Exception:
        raise SystemExit("Pillow (PIL) is required. Install with: pip3 install pillow")
    main()


