"""Fond du carton de titre : dégradé crépuscule pastel, étoiles, silhouette et lanternes.

Dessiné par code plutôt que généré, pour rester raccord avec les tableaux IA sans
dépendre d'un service externe.

    python outils/titre_fond.py
"""
import math
import os
import random

from PIL import Image, ImageDraw, ImageFilter

L, H = 720, 1280
SORTIE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "cine")


def degrade(stops):
    img = Image.new("RGB", (L, H))
    d = ImageDraw.Draw(img)
    for y in range(H):
        t = y / (H - 1)
        for i in range(len(stops) - 1):
            p0, c0 = stops[i]
            p1, c1 = stops[i + 1]
            if p0 <= t <= p1:
                k = 0.0 if p1 == p0 else (t - p0) / (p1 - p0)
                d.line([(0, y), (L, y)], fill=tuple(int(c0[j] + (c1[j] - c0[j]) * k) for j in range(3)))
                break
    return img.convert("RGBA")


def disque(img, cx, cy, rad, couleur, alpha=220, flou=1.4):
    couche = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(couche).ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=tuple(couleur) + (alpha,))
    img.alpha_composite(couche.filter(ImageFilter.GaussianBlur(flou)))


def halo(img, cx, cy, rayon, couleur, force=0.5, marches=20):
    couche = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(couche)
    for i in range(marches, 0, -1):
        rad = rayon * i / marches
        a = int(255 * force * (1.0 - i / marches) ** 1.8)
        d.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=tuple(couleur) + (max(0, min(255, a)),))
    img.alpha_composite(couche)


def main():
    os.makedirs(SORTIE, exist_ok=True)
    img = degrade([(0.00, (58, 54, 88)), (0.38, (98, 88, 124)), (0.64, (172, 138, 148)),
                   (0.84, (228, 178, 152)), (1.00, (246, 206, 172))])

    r = random.Random(44)
    for _ in range(150):
        disque(img, r.uniform(0, L), r.uniform(0, H * 0.46), r.choice([1.2, 1.6, 2.2]),
               (255, 250, 232), r.randint(70, 180), 0.7)

    halo(img, L * 0.5, H * 0.62, 360, (255, 214, 170), 0.28)

    # silhouette d'île, très basse : le titre se pose au centre
    pts = [(0, H * 0.80), (L * 0.16, H * 0.72), (L * 0.34, H * 0.78),
           (L * 0.54, H * 0.70), (L * 0.74, H * 0.77), (L, H * 0.71), (L, H), (0, H)]
    couche = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(couche).polygon(pts, fill=(78, 64, 80, 245))
    img.alpha_composite(couche.filter(ImageFilter.GaussianBlur(1.6)))

    for i in range(9):
        lx = L * (0.06 + i * 0.11)
        ly = H * (0.745 + (i % 3) * 0.028)
        halo(img, lx, ly, 46, (255, 180, 130), 0.55)
        disque(img, lx, ly, 7, (242, 160, 122), 235, 1.2)

    # grain de papier
    bruit = Image.effect_noise(img.size, 20).convert("L")
    img.alpha_composite(Image.merge("RGBA", (bruit, bruit, bruit, Image.new("L", img.size, 11))))

    img.convert("RGB").save(os.path.join(SORTIE, "cine_5_titre.png"), quality=93)
    print("ok cine_5_titre.png")


if __name__ == "__main__":
    main()
