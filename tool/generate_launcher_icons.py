#!/usr/bin/env python3
"""Regenerate Android adaptive + legacy launcher icons from art/app_icon.png."""

from __future__ import annotations

import os
import shutil
from pathlib import Path

from PIL import Image, ImageEnhance, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "art" / "app_icon.png"
RES = ROOT / "android" / "app" / "src" / "main" / "res"

DENSITIES = [
    ("mipmap-mdpi", 48, 108),
    ("mipmap-hdpi", 72, 162),
    ("mipmap-xhdpi", 96, 216),
    ("mipmap-xxhdpi", 144, 324),
    ("mipmap-xxxhdpi", 192, 432),
]


def main() -> None:
    src = Image.open(SRC).convert("RGBA")

    # Background: zoomed, darkened cave (full bleed).
    bg = src.resize((int(1024 * 1.35), int(1024 * 1.35)), Image.Resampling.LANCZOS)
    left = (bg.width - 1024) // 2
    top = (bg.height - 1024) // 2
    bg = bg.crop((left, top, left + 1024, top + 1024))
    bg = ImageEnhance.Brightness(bg).enhance(0.55)
    bg = ImageEnhance.Color(bg).enhance(0.85)
    bg = bg.filter(ImageFilter.GaussianBlur(radius=1.2))
    r, g, b, _ = bg.split()
    bg = Image.merge("RGBA", (r, g, b, Image.new("L", bg.size, 255)))
    bg.save(ROOT / "art" / "ic_launcher_background.png")

    # Foreground: slightly zoomed subject in the adaptive safe zone (~66%).
    zoom = 1.08
    zoomed = src.resize((int(1024 * zoom), int(1024 * zoom)), Image.Resampling.LANCZOS)
    zl = (zoomed.width - 1024) // 2
    zt = max(0, min((zoomed.height - 1024) // 2 - 20, zoomed.height - 1024))
    subject = zoomed.crop((zl, zt, zl + 1024, zt + 1024))
    content = int(1024 * 0.66)
    pad = (1024 - content) // 2
    fg = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    subject_resized = subject.resize((content, content), Image.Resampling.LANCZOS)
    fg.paste(subject_resized, (pad, pad), subject_resized)
    fg.save(ROOT / "art" / "ic_launcher_foreground.png")

    legacy = src.convert("RGB")
    legacy.save(ROOT / "art" / "ic_launcher.png")

    for folder, leg, adap in DENSITIES:
        d = RES / folder
        d.mkdir(parents=True, exist_ok=True)
        legacy.resize((leg, leg), Image.Resampling.LANCZOS).save(d / "ic_launcher.png")
        shutil.copyfile(d / "ic_launcher.png", d / "ic_launcher_round.png")
        fg.resize((adap, adap), Image.Resampling.LANCZOS).save(
            d / "ic_launcher_foreground.png"
        )
        bg.resize((adap, adap), Image.Resampling.LANCZOS).save(
            d / "ic_launcher_background.png"
        )
        print(folder, leg, adap)


if __name__ == "__main__":
    os.chdir(ROOT)
    main()
