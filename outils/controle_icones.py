# QA audit of existing icons: planche 6xN + background/saturation checks.
import os
from PIL import Image, ImageDraw

ROOT = r"E:\mergecontinu\assets\objets"
OUT = r"C:\Users\Isl4m\AppData\Local\Temp\opencode\planche_controle.png"

ORDER = []
for chain in ("bois", "ferme", "forge", "tissu", "ceramique"):
    for lvl in range(1, 7):
        ORDER.append("%s-%d" % (chain, lvl))
for gen in ("bois", "ferme", "forge", "tissu", "ceramique"):
    ORDER.append("gen-" + gen)

CREME = (248, 242, 228)

def bg_color(im):
    return im.getpixel((2, 2))

def uniform(im, fond, tol=20):
    w, h = im.size
    pts = [(1, 1), (w - 2, 1), (1, h - 2), (w - 2, h - 2), (2, 2), (w//2, 1), (w//2, h-2), (1, h//2), (w-2, h//2)]
    worst = 0
    for (x, y) in pts:
        p = im.getpixel((x, y))
        d = max(abs(p[i] - fond[i]) for i in range(3))
        worst = max(worst, d)
    return worst <= tol

def saturation_mean(im, fond, tol=26):
    hsv = im.convert("HSV")
    px = hsv.load()
    w, h = im.size
    tot, n = 0.0, 0
    for y in range(4, h - 4, 2):
        for x in range(4, w - 4, 2):
            p = im.getpixel((x, y))
            if max(abs(p[i] - fond[i]) for i in range(3)) > tol:
                tot += px[x, y][1] / 255.0
                n += 1
    return (tot / n) if n else 0.0

TUILE, LEGENDE, COLS = 200, 26, 6
rows = -(-len(ORDER) // COLS)
planche = Image.new("RGB", (COLS * TUILE, rows * (TUILE + LEGENDE)), CREME)
d = ImageDraw.Draw(planche)

print("icon            | bg rgb          | bord uniforme | sat. moyenne | QA")
print("----------------|-----------------|---------------|--------------|----")
issues = []
for idx, key in enumerate(ORDER):
    path = os.path.join(ROOT, key + ".jpg")
    if not os.path.exists(path):
        print("%-15s | MANQUANT" % key)
        issues.append((key, "manquant"))
        continue
    im = Image.open(path).convert("RGB")
    if im.size != (256, 256):
        print("%-15s | TAILLE %s" % (key, im.size))
    fond = bg_color(im)
    uni = uniform(im, fond)
    sat = saturation_mean(im, fond)
    sat_pv = "OK" if sat <= 0.85 else "SATUREE"
    uni_pv = "OK" if uni else "NON-UNI"
    ecarts = []
    if not uni:
        ecarts.append("fond non uniforme")
    if sat > 0.85:
        ecarts.append("trop saturée (%.0f%%)" % (sat * 100))
    v = "OK" if not ecarts else "/".join(ecarts)
    print("%-15s | %3d %3d %3d      | %-13s | %.0f%%          | %s" % (key, fond[0], fond[1], fond[2], uni_pv, sat * 100, v))
    if ecarts:
        issues.append((key, v))

    x = (idx % COLS) * TUILE
    y = (idx // COLS) * (TUILE + LEGENDE)
    planche.paste(im.resize((TUILE, TUILE), Image.LANCZOS), (x, y))
    d.text((x + 5, y + TUILE + 6), key, fill=(74, 58, 40))

planche.save(OUT) if False else None  # written below at full size
planche.save(OUT)
print()
print("problemes:", len(issues))
for k, v in issues:
    print("  -", k, ":", v)
