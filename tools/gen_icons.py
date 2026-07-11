from PIL import Image, ImageDraw
import math

SS = 4  # supersample

INDIGO = (99, 102, 241)   # #6366F1
VIOLET = (124, 58, 237)   # #7C3AED

def lerp(a, b, t):
    return tuple(int(a[i] + (b[i]-a[i])*t) for i in range(3))

def gradient(size, c1, c2):
    """Diagonal (top-left -> bottom-right) gradient."""
    img = Image.new("RGB", (size, size), c1)
    px = img.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2*(size-1))
            px[x, y] = lerp(c1, c2, t)
    return img

def rounded_mask(size, radius):
    m = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(m)
    d.rounded_rectangle([0, 0, size-1, size-1], radius=radius, fill=255)
    return m

def draw_cap(draw, cx, cy, k, color=(255, 255, 255, 255)):
    """Draw a graduation cap (mortarboard) centered near (cx,cy). k = scale."""
    def P(dx, dy):
        return (cx + dx*k, cy + dy*k)

    # Cap band (the part on the head) — rounded trapezoid under the board
    band = [P(-165, -30), P(-150, 95), P(-95, 150), P(0, 168),
            P(95, 150), P(150, 95), P(165, -30)]
    draw.polygon(band, fill=color)
    # round the bottom of the band
    draw.pieslice([P(-150, 60)[0], P(-150, 60)[1], P(150, 200)[0], P(150, 200)[1]],
                  start=0, end=180, fill=color)

    # Mortarboard (flattened diamond)
    board = [P(0, -205), P(315, -70), P(0, 65), P(-315, -70)]
    draw.polygon(board, fill=color)

    # Tassel: cord from board centre to the right, then hanging down + bead
    lw = int(16*k)
    draw.line([P(0, -78), P(232, -78)], fill=color, width=lw)
    draw.line([P(232, -78), P(232, 120)], fill=color, width=lw)
    # button knob at board centre
    r = 24*k
    draw.ellipse([P(0,-78)[0]-r, P(0,-78)[1]-r, P(0,-78)[0]+r, P(0,-78)[1]+r], fill=color)
    # bead at tassel end
    rb = 34*k
    draw.ellipse([P(232,120)[0]-rb, P(232,120)[1]-rb, P(232,120)[0]+rb, P(232,120)[1]+rb], fill=color)

def make_full_icon(path, size=1024, cap_k=1.0, rounded=False):
    S = size*SS
    bg = gradient(S, INDIGO, VIOLET).convert("RGBA")
    d = ImageDraw.Draw(bg)
    draw_cap(d, S/2, S/2 + 10*SS, cap_k*SS)
    if rounded:
        mask = rounded_mask(S, int(S*0.22))
        bg.putalpha(mask)
    out = bg.resize((size, size), Image.LANCZOS)
    out.save(path)

def make_foreground(path, size=1024, cap_k=0.62):
    S = size*SS
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    draw_cap(d, S/2, S/2 + 10*SS, cap_k*SS)
    out = img.resize((size, size), Image.LANCZOS)
    out.save(path)

def make_bg(path, size=1024):
    S = size*SS
    bg = gradient(S, INDIGO, VIOLET).convert("RGBA")
    out = bg.resize((size, size), Image.LANCZOS)
    out.save(path)

def make_splash_logo(path, size=512, cap_k=0.72):
    """Rounded gradient badge + white cap on transparent — reads on light & dark."""
    S = size*SS
    badge = gradient(S, INDIGO, VIOLET).convert("RGBA")
    mask = rounded_mask(S, int(S*0.26))
    badge.putalpha(mask)
    d = ImageDraw.Draw(badge)
    draw_cap(d, S/2, S/2 + 8*SS, cap_k*SS)
    out = badge.resize((size, size), Image.LANCZOS)
    out.save(path)

make_full_icon("assets/icon/icon.png", 1024, cap_k=0.62)          # iOS + legacy Android
make_foreground("assets/icon/icon_foreground.png", 1024, cap_k=0.55)  # adaptive fg (safe zone)
make_bg("assets/icon/icon_background.png", 1024)                   # adaptive bg (gradient)
make_splash_logo("assets/splash/splash_logo.png", 512, cap_k=0.72)

print("generated:")
import os
for f in ["assets/icon/icon.png","assets/icon/icon_foreground.png","assets/icon/icon_background.png","assets/splash/splash_logo.png"]:
    print(" ", f, os.path.getsize(f), "bytes")
