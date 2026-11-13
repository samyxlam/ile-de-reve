# Harmonize icon backgrounds to exact cream #f8f2e4.
# Pillow floodfill refuses to fill when the fill color is close to the seed color,
# so we fill with a magenta sentinel first, then map sentinel -> cream.
import os, shutil
from PIL import Image, ImageDraw

ROOT = r"E:\mergecontinu\assets\objets"
CREME = (248, 242, 228)
SENTINELLE = (255, 0, 255)
SEUIL = 28

n = 0
for name in sorted(f for f in os.listdir(ROOT) if f.endswith(".jpg")):
    src = os.path.join(ROOT, name)
    im = Image.open(src).convert("RGB")
    avant = im.getpixel((2, 2))
    for xy in ((1, 1), (im.width - 2, 1), (1, im.height - 2), (im.width - 2, im.height - 2)):
        ImageDraw.floodfill(im, xy, SENTINELLE, thresh=SEUIL)
    # sentinel -> cream, with a wide mask that also catches JPEG noise on flat areas
    diff = Image.new("RGB", im.size, SENTINELLE)
    mask = Image.new("L", im.size, 255)  # replaced by real mask below
    masque = im.point(lambda v: v)  # placeholder replaced below
    # build mask: pixels close to sentinel
    r, g, b = im.split()
    dr = r.point(lambda v, c=255: 255 if abs(v - c) < 2 else 0)
    dg = g.point(lambda v, c=0: 255 if abs(v - c) < 2 else 0)
    db = b.point(lambda v, c=255: 255 if abs(v - c) < 2 else 0)
    from PIL import ImageChops
    masque = ImageChops.darker(ImageChops.darker(dr, dg), db)
    # slight dilation via MaxFilter to catch antialiasing artefacts of the sentinel edge
    masque = masque.filter(__import__("PIL.ImageFilter", fromlist=["ImageFilter"]).MaxFilter(3))
    im.paste(Image.new("RGB", im.size, CREME), (0, 0), masque)
    im.save(src, quality=92)
    print("%-14s %3d %3d %3d -> %3d %3d %3d" % (name, avant[0], avant[1], avant[2], im.getpixel((2, 2))[0], im.getpixel((2, 2))[1], im.getpixel((2, 2))[2]))
    n += 1
print("termine:", n)
