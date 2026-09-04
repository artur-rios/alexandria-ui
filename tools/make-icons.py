#!/usr/bin/env python3
"""Draws the application's icon and writes every packaged size of it.

The icon is generated rather than drawn by hand and pasted in, because the
same mark has to exist as a Windows `.ico` carrying six sizes, a 512-pixel
PNG for the Linux packages, and a square master for the MSIX packager — and
six files edited by hand drift into six slightly different icons. The
drawing lives here; everything else is an export of it.

Run after changing anything below, and commit what it writes:

    python3 tools/make-icons.py

Needs Pillow (`pip install pillow`); nothing else, and nothing at build
time — the outputs are committed, so a fresh checkout packages the icon
without this script ever running.

THE MARK. An A, because that is what the application has always been
badged with, over the blue the interface is themed from — and its crossbar
is a shelf, in the one warm colour anywhere in the product. That is the
whole idea: the letter says which application, the band says what kind, and
neither needs a second glance at 16 pixels, where a drawing of a library
would be four grey smudges.
"""

from pathlib import Path

from PIL import Image, ImageDraw

# Where the exports go, relative to the repository root.
ROOT = Path(__file__).resolve().parent.parent

# The Linux packages address the icon by this name: the .desktop entry names
# it, and the AppImage, Flatpak, .deb and installer each put a file of this
# name into the icon theme.
APP_ID = "io.github.artur_rios.Alexandria"

# The interface's own seed colour, lightened for the top of the plate, and a
# deep navy for the bottom. A gradient rather than a flat fill because an
# icon is looked at against both light and dark shelves of other icons, and
# the darker foot keeps it from dissolving into a pale taskbar.
BG_TOP = (62, 99, 160)
BG_BOTTOM = (28, 44, 78)

# Warm off-white rather than pure white: the same ink the placeholder used,
# and it stops the mark glaring against the blue.
INK = (244, 241, 234)

# The single warm colour, on the crossbar alone.
ACCENT = (224, 166, 75)

# Everything below is a fraction of the canvas, so the drawing is resolution
# independent and each export is the same picture at a different size.
CORNER = 0.21           # the plate's corner radius
TOP, BOTTOM = 0.185, 0.80   # where the letter starts and ends
HALF = 0.285            # how far each foot sits from the centre
STROKE = 0.092          # the letter's stroke
BAR_AT = 0.62           # how far down the legs the crossbar crosses
BAR_THICKNESS = 0.85    # of the stroke: a hair lighter, so it does not shout

# Drawn this many times larger than needed and scaled down, which is what
# gives the diagonals their clean edges — PIL has no antialiased polygon.
SUPERSAMPLE = 4


def draw(size: int) -> Image.Image:
    """The icon, at `size` pixels square."""
    n = size * SUPERSAMPLE
    img = _plate(n)
    d = ImageDraw.Draw(img)

    cx = n / 2
    top, bottom = n * TOP, n * BOTTOM
    half, stroke = n * HALF, n * STROKE

    # Each leg is a quadrilateral running from the apex out to its foot. The
    # two overlap at the top, which is what forms the flat apex — a pointed
    # one would come to nothing at 16 pixels and read as a triangle.
    for sign in (-1, 1):
        d.polygon(
            [
                (cx + sign * stroke * 0.5, top),
                (cx + sign * (half + stroke * 0.5), bottom),
                (cx + sign * (half - stroke * 0.5), bottom),
                (cx - sign * stroke * 0.5, top),
            ],
            fill=INK,
        )

    # The crossbar ends flush with the legs' outer edges, which is why its
    # length is computed from where the legs are at that height rather than
    # chosen. Set by hand, it overhung one leg and stopped short of the
    # other, and the letter looked like it was leaning.
    y = top + (bottom - top) * BAR_AT
    end = half * BAR_AT + stroke * 0.5
    thickness = stroke * BAR_THICKNESS
    d.rounded_rectangle(
        [cx - end, y - thickness / 2, cx + end, y + thickness / 2],
        radius=thickness * 0.45,
        fill=ACCENT,
    )

    return img.resize((size, size), Image.LANCZOS)


def _plate(n: int) -> Image.Image:
    """The rounded square the mark sits on, with its gradient."""
    column = Image.new("RGB", (1, n))
    for y in range(n):
        t = y / (n - 1)
        column.putpixel(
            (0, y),
            tuple(round(a + (b - a) * t) for a, b in zip(BG_TOP, BG_BOTTOM)),
        )
    gradient = column.resize((n, n))

    mask = Image.new("L", (n, n), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, n - 1, n - 1], radius=round(n * CORNER), fill=255
    )

    plate = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    plate.paste(gradient, (0, 0), mask)
    return plate


def main() -> None:
    # Windows reads whichever size fits the place it is drawing — the
    # taskbar, the title bar, Explorer's tiles — so the .ico carries all of
    # them rather than one that Windows would rescale badly.
    ico_sizes = (16, 24, 32, 48, 64, 128, 256)
    frames = {size: draw(size) for size in ico_sizes}
    ico = ROOT / "windows" / "runner" / "resources" / "app_icon.ico"
    frames[256].save(ico, format="ICO", sizes=[(s, s) for s in ico_sizes])

    # The Linux icon theme's largest standard size, which every Linux
    # package installs under this exact name.
    linux = ROOT / "packaging" / "linux" / f"{APP_ID}.png"
    draw(512).save(linux, format="PNG")

    # The MSIX packager derives every tile and store asset it needs from one
    # square master. 1240 is the size it asks for, and it is the size of the
    # largest asset it makes (a 310-pixel tile at 400% scale) — anything
    # smaller is upscaled into that tile, which is the one place the mark
    # would look soft.
    msix = ROOT / "packaging" / "windows" / "app_icon.png"
    draw(1240).save(msix, format="PNG")

    for path in (ico, linux, msix):
        print(f"wrote {path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
