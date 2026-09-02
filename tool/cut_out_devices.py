"""Cuts the three device photographs out of their backgrounds.

Run from the repository root, with Pillow installed:

    python3 tool/cut_out_devices.py

Reads `device-images/*.png` — the renders as they were delivered, each on a
flat backdrop — and writes `assets/devices/*.png`, cropped to the machine and
transparent around it, which is what lets a machine sit on the window's own
surface instead of in a white box.

The background is taken by flood fill from the border rather than by matching
a colour across the whole picture: the CD player is photographed on black and
is itself nearly black in places, and a global match would punch holes in its
own speaker cloth. Only pixels reachable from the edge are removed — which is
also why the turntable's dust cover comes out transparent, and rightly so:
what was behind it in the photograph is the backdrop.

Kept in the repository so the assets can be made again from the originals,
rather than being a one-off nobody can reproduce.
"""

from PIL import Image, ImageFilter
from collections import deque
import sys

def cutout(name, tol, maxw):
    im = Image.open(f'device-images/{name}.png').convert('RGB')
    w, h = im.size
    px = im.load()
    bg = px[0, 0]

    # Flood fill from every border pixel: connected background only, so a
    # dark part *inside* the device is never punched out.
    mask = bytearray(w * h)          # 1 = background
    q = deque()
    def near(c):
        return abs(c[0]-bg[0]) + abs(c[1]-bg[1]) + abs(c[2]-bg[2]) <= tol
    for x in range(w):
        for y in (0, h-1):
            if not mask[y*w+x] and near(px[x, y]):
                mask[y*w+x] = 1; q.append((x, y))
    for y in range(h):
        for x in (0, w-1):
            if not mask[y*w+x] and near(px[x, y]):
                mask[y*w+x] = 1; q.append((x, y))
    while q:
        x, y = q.popleft()
        for dx, dy in ((1,0),(-1,0),(0,1),(0,-1)):
            nx, ny = x+dx, y+dy
            if 0 <= nx < w and 0 <= ny < h and not mask[ny*w+nx] and near(px[nx, ny]):
                mask[ny*w+nx] = 1
                q.append((nx, ny))

    alpha = Image.frombytes('L', (w, h), bytes(255 - 255*b for b in mask))
    # A whisker of feather so the edge does not stair-step.
    alpha = alpha.filter(ImageFilter.GaussianBlur(0.6))
    out = im.copy(); out.putalpha(alpha)
    box = out.getbbox()
    out = out.crop(box)
    if out.width > maxw:
        out = out.resize((maxw, round(out.height * maxw / out.width)), Image.LANCZOS)
    out.save(f'assets/devices/{name}.png')
    print(name, 'cropped to', out.size, 'from', (w, h), 'box', box)

cutout('vinyl-player', 30, 1200)
cutout('cassette-player', 30, 1400)
cutout('cd-player', 24, 1600)
