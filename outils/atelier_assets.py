import marimo

__generated_with = "0.25.2"
app = marimo.App(width="medium")


@app.cell
def _():
    import marimo as mo

    return (mo,)


@app.cell
def _():
    """Atelier d'assets — cadres d'interface et cinématique, en aquarelle pastel.

    Direction artistique : chibi rond, couleurs pastel, bords d'aquarelle (formes
    légèrement floutées et irrégulières), grain de papier. Aucun personnage existant
    n'est reproduit : le chibi est un petit insulaire original.

    Lancement en script :  python outils/atelier_assets.py
    Édition interactive  :  marimo edit outils/atelier_assets.py
    """
    import math
    import os
    import random

    from PIL import Image, ImageDraw, ImageFilter

    try:
        RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    except NameError:
        RACINE = os.getcwd()
    SORTIE_UI = os.path.join(RACINE, "assets", "ui")
    SORTIE_CINE = os.path.join(RACINE, "assets", "cine")
    os.makedirs(SORTIE_UI, exist_ok=True)
    os.makedirs(SORTIE_CINE, exist_ok=True)

    # ---- palette pastel (désaturée, chaude, proche de l'aquarelle)
    PEAU = (246, 216, 194)
    CHEVEU = (86, 62, 62)
    TUNIQUE = (232, 158, 132)
    TUNIQUE_B = (150, 196, 168)
    PANTALON = (128, 146, 176)
    NUIT_HAUT = (58, 52, 84)
    NUIT_MILIEU = (124, 106, 146)
    AURORE = (240, 178, 164)
    SOLEIL = (255, 228, 190)
    MER_HAUT = (168, 198, 214)
    MER_BAS = (108, 146, 172)
    ILE = (168, 206, 164)
    ILE_OMBRE = (126, 170, 130)
    TERRE = (198, 158, 128)
    LANTERNE = (242, 160, 122)
    BOIS_UI = (207, 161, 122)
    BOIS_UI_BORD = (143, 106, 76)
    PARCH = (253, 246, 233)
    PARCH_BORD = (224, 203, 176)
    JADE_UI = (183, 217, 154)
    JADE_BORD = (124, 162, 104)
    OR_UI = (243, 207, 134)
    OR_BORD = (186, 148, 74)

    def cercle_pts(cx, cy, rad, n=30, amp=0.0, r=None):
        pts = []
        for i in range(n):
            a = 2 * math.pi * i / n
            rr = rad + (r.uniform(-amp, amp) if (r is not None and amp) else 0.0)
            pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr))
        return pts

    def _pose(img, pts, couleur, alpha, flou):
        couche = Image.new("RGBA", img.size, (0, 0, 0, 0))
        ImageDraw.Draw(couche).polygon(pts, fill=tuple(couleur) + (alpha,))
        img.alpha_composite(couche.filter(ImageFilter.GaussianBlur(flou)))

    def tache(img, pts, couleur, alpha=205, flou=1.7, r=None, amp=0.0):
        """Forme pleine légèrement floue et irrégulière : le geste d'aquarelle."""
        if r is not None and amp:
            pts = [(x + r.uniform(-amp, amp), y + r.uniform(-amp, amp)) for x, y in pts]
        _pose(img, pts, couleur, alpha, flou)

    def disque(img, cx, cy, rad, couleur, alpha=205, flou=1.6, r=None, amp=0.0):
        tache(img, cercle_pts(cx, cy, rad, 30, amp, r), couleur, alpha, flou)

    def trait(img, pts, couleur, largeur=3, alpha=170, flou=1.1):
        couche = Image.new("RGBA", img.size, (0, 0, 0, 0))
        ImageDraw.Draw(couche).line(pts, fill=tuple(couleur) + (alpha,), width=largeur, joint="curve")
        img.alpha_composite(couche.filter(ImageFilter.GaussianBlur(flou)))

    def degrade_vertical(w, h, stops):
        img = Image.new("RGB", (w, h))
        d = ImageDraw.Draw(img)
        for y in range(h):
            t = y / max(1, h - 1)
            for i in range(len(stops) - 1):
                p0, c0 = stops[i]
                p1, c1 = stops[i + 1]
                if p0 <= t <= p1:
                    k = 0.0 if p1 == p0 else (t - p0) / (p1 - p0)
                    c = tuple(int(c0[j] + (c1[j] - c0[j]) * k) for j in range(3))
                    d.line([(0, y), (w, y)], fill=c)
                    break
        return img

    def papier(img, alpha=13, force=20):
        """Grain de papier : bruit fin, très peu contrasté."""
        bruit = Image.effect_noise(img.size, force).convert("L")
        couche = Image.merge("RGBA", (bruit, bruit, bruit, Image.new("L", img.size, alpha)))
        img.alpha_composite(couche)

    def halo(img, cx, cy, rayon, couleur, force=0.5, marches=22):
        couche = Image.new("RGBA", img.size, (0, 0, 0, 0))
        d = ImageDraw.Draw(couche)
        for i in range(marches, 0, -1):
            rad = rayon * i / marches
            a = int(255 * force * (1.0 - i / marches) ** 1.8)
            d.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=tuple(couleur) + (max(0, min(255, a)),))
        img.alpha_composite(couche)

    def etoiles(img, n, y_max, graine=7):
        r = random.Random(graine)
        for _ in range(n):
            x = r.uniform(0, img.size[0])
            y = r.uniform(0, y_max)
            disque(img, x, y, r.choice([1.2, 1.6, 2.2]), (255, 250, 232), r.randint(70, 190), 0.8)

    def chibi(img, cx, cy, h, dos=False, graine=1, lanterne=False):
        """Petit insulaire chibi : grosse tête ronde, cheveux en pointes, membres courts."""
        r = random.Random(graine)
        tete = h * 0.27
        corps_h = h * 0.42
        bas = cy + h * 0.50

        # jambes et bras, avant le corps
        disque(img, cx - h * 0.10, bas - h * 0.04, h * 0.055, PANTALON, 225, 1.5)
        disque(img, cx + h * 0.10, bas - h * 0.04, h * 0.055, PANTALON, 225, 1.5)
        disque(img, cx - h * 0.21, cy + h * 0.22, h * 0.045, PEAU, 225, 1.5)
        disque(img, cx + h * 0.21, cy + h * 0.22, h * 0.045, PEAU, 225, 1.5)

        # corps : tunique trapèze
        tache(img, [(cx - h * 0.155, cy + h * 0.10), (cx + h * 0.155, cy + h * 0.10),
                    (cx + h * 0.19, bas), (cx - h * 0.19, bas)],
              TUNIQUE_B if dos else TUNIQUE, 220, 2.0, r, 1.2)

        # tête
        disque(img, cx, cy, tete, PEAU, 235, 1.6, r, 0.9)

        # cheveux : calotte + pointes
        calotte = [(cx + math.cos(a) * tete * 1.02, cy + math.sin(a) * tete * 1.02)
                   for a in [math.pi + math.pi * i / 12 for i in range(13)]]
        tache(img, calotte, CHEVEU, 235, 1.8, r, 1.0)
        for i in range(7):
            a = math.pi + math.pi * (0.06 + 0.13 * i)
            bx = cx + math.cos(a) * tete * 0.92
            by = cy + math.sin(a) * tete * 0.92
            tip = (cx + math.cos(a) * tete * 1.62, cy + math.sin(a) * tete * 1.62)
            tache(img, [(bx - tete * 0.16, by + tete * 0.10), (bx + tete * 0.16, by + tete * 0.10), tip],
                  CHEVEU, 230, 1.6)

        if dos:
            return

        # visage : gros yeux ronds, reflet, joues rosées
        for sx in (-1, 1):
            ex = cx + sx * tete * 0.36
            ey = cy + tete * 0.16
            disque(img, ex, ey, tete * 0.17, (58, 46, 50), 235, 1.1)
            disque(img, ex - tete * 0.05, ey - tete * 0.06, tete * 0.055, (255, 255, 255), 235, 0.6)
        disque(img, cx - tete * 0.60, cy + tete * 0.40, tete * 0.11, (246, 170, 158), 120, 1.8)
        disque(img, cx + tete * 0.60, cy + tete * 0.40, tete * 0.11, (246, 170, 158), 120, 1.8)
        trait(img, [(cx - tete * 0.10, cy + tete * 0.44), (cx + tete * 0.10, cy + tete * 0.44)],
              (120, 78, 74), 3, 200, 0.8)

        if lanterne:
            lx, ly = cx + h * 0.34, cy - h * 0.02
            halo(img, lx, ly, h * 0.30, (255, 196, 140), 0.55)
            disque(img, lx, ly, h * 0.075, LANTERNE, 235, 1.4)
            trait(img, [(cx + h * 0.16, cy + h * 0.16), (lx, ly - h * 0.07)], (110, 80, 70), 2, 160, 0.8)

    return (
        math, os, random, Image, ImageDraw, ImageFilter,
        RACINE, SORTIE_UI, SORTIE_CINE,
        PEAU, CHEVEU, TUNIQUE, TUNIQUE_B, PANTALON, NUIT_HAUT, NUIT_MILIEU, AURORE, SOLEIL,
        MER_HAUT, MER_BAS, ILE, ILE_OMBRE, TERRE, LANTERNE,
        BOIS_UI, BOIS_UI_BORD, PARCH, PARCH_BORD, JADE_UI, JADE_BORD, OR_UI, OR_BORD,
        cercle_pts, tache, disque, trait, degrade_vertical, papier, halo, etoiles, chibi,
    )


@app.cell
def _(Image, ImageDraw, ImageFilter, os, random, SORTIE_UI, cercle_pts, tache, disque,
      BOIS_UI, BOIS_UI_BORD, PARCH, PARCH_BORD, JADE_UI, JADE_BORD, OR_UI, OR_BORD):
    """Cadres d'interface en aquarelle, prévus pour le 9-slice (marge 22 sur 104)."""

    TAILLE = 104

    def cadre(nom, fond, bord, lueur, graine=1, veines=False):
        r = random.Random(graine)
        img = Image.new("RGBA", (TAILLE, TAILLE), (0, 0, 0, 0))
        masque = Image.new("L", (TAILLE, TAILLE), 0)
        ImageDraw.Draw(masque).rounded_rectangle([1, 1, TAILLE - 2, TAILLE - 2], 20, fill=255)

        # fond : dégradé doux puis taches d'aquarelle plus claires
        fond_img = Image.new("RGBA", (TAILLE, TAILLE), (0, 0, 0, 0))
        d = ImageDraw.Draw(fond_img)
        for y in range(TAILLE):
            k = y / (TAILLE - 1)
            c = tuple(max(0, min(255, int(fond[j] * (1.0 + 0.16 * (0.5 - k))))) for j in range(3))
            d.line([(0, y), (TAILLE, y)], fill=c + (255,))
        fond_img.putalpha(masque)
        img.alpha_composite(fond_img)

        taches = Image.new("RGBA", (TAILLE, TAILLE), (0, 0, 0, 0))
        for _ in range(9):
            cx, cy = r.uniform(10, TAILLE - 10), r.uniform(10, TAILLE - 10)
            disque(taches, cx, cy, r.uniform(8, 20), lueur, r.randint(10, 22), 4.0)
        taches.putalpha(Image.composite(taches.getchannel("A"), Image.new("L", (TAILLE, TAILLE), 0), masque))
        img.alpha_composite(taches)

        if veines:
            veines_img = Image.new("RGBA", (TAILLE, TAILLE), (0, 0, 0, 0))
            dv = ImageDraw.Draw(veines_img)
            for _ in range(7):
                x = r.uniform(12, TAILLE - 12)
                pts = [(x + r.uniform(-2, 2), y) for y in range(10, TAILLE - 10, 9)]
                dv.line(pts, fill=BOIS_UI_BORD + (26,), width=1)
            veines_img.putalpha(Image.composite(veines_img.getchannel("A"), Image.new("L", (TAILLE, TAILLE), 0), masque))
            img.alpha_composite(veines_img)

        # bord : trait irrégulier, comme un liseré au pinceau
        bord_img = Image.new("RGBA", (TAILLE, TAILLE), (0, 0, 0, 0))
        db = ImageDraw.Draw(bord_img)
        db.rounded_rectangle([2, 2, TAILLE - 3, TAILLE - 3], 19, outline=bord + (255,), width=5)
        img.alpha_composite(bord_img.filter(ImageFilter.GaussianBlur(0.7)))
        img.save(os.path.join(SORTIE_UI, nom))

    cadre("cadre_bois.png", BOIS_UI, BOIS_UI_BORD, (255, 236, 208), graine=2, veines=True)
    cadre("cadre_parchemin.png", PARCH, PARCH_BORD, (255, 255, 255), graine=4)
    cadre("cadre_parchemin_fonce.png", (243, 232, 212), PARCH_BORD, (255, 250, 238), graine=5)
    cadre("cadre_jade.png", JADE_UI, JADE_BORD, (226, 246, 206), graine=6)
    cadre("cadre_or.png", OR_UI, OR_BORD, (255, 244, 206), graine=7)
    cadre("cadre_encens.png", (150, 126, 112), (92, 70, 60), (196, 170, 150), graine=8)

    print("cadres :", len([f for f in os.listdir(SORTIE_UI) if f.endswith(".png")]))
    return (TAILLE,)


@app.cell
def _(Image, ImageDraw, ImageFilter, math, os, random, SORTIE_CINE,
      NUIT_HAUT, NUIT_MILIEU, AURORE, SOLEIL, MER_HAUT, MER_BAS, ILE, ILE_OMBRE, TERRE, LANTERNE,
      PEAU, CHEVEU, degrade_vertical, papier, halo, etoiles, tache, disque, trait, chibi,
      cercle_pts):
    """Cinématique d'intro : cinq tableaux aquarelle, du large au titre."""

    L, H = 720, 1280

    def fond(stops):
        return degrade_vertical(L, H, stops).convert("RGBA")

    # ---- 1. Mer au crépuscule
    img = fond([(0.00, NUIT_HAUT), (0.26, (86, 78, 116)), (0.46, (168, 132, 152)),
                (0.54, AURORE), (0.56, (252, 214, 186)), (0.58, (146, 176, 198)), (1.00, MER_BAS)])
    etoiles(img, 120, H * 0.32, graine=5)
    halo(img, L * 0.60, H * 0.545, 210, SOLEIL, 0.55)
    disque(img, L * 0.60, H * 0.545, 52, SOLEIL, 245, 3.0)
    for i in range(90):
        r = random.Random(100 + i)
        y = r.uniform(H * 0.57, H)
        prof = (y - H * 0.57) / (H * 0.43)
        longueur = r.uniform(6, 44) * (0.4 + prof * 1.6)
        x = L * 0.60 + r.gauss(0, 44 + prof * 90) - longueur / 2
        tache(img, [(x, y), (x + longueur, y), (x + longueur, y + 2.2), (x, y + 2.2)],
              (255, 232, 200), int(70 * (1 - prof * 0.5)), 1.2)
    tache(img, [(0, H * 0.56), (L * 0.10, H * 0.50), (L * 0.20, H * 0.545),
                (L * 0.31, H * 0.475), (L * 0.42, H * 0.56), (L, H * 0.56), (L, H * 0.575), (0, H * 0.575)],
          (92, 86, 118), 210, 2.4)
    papier(img, 12)
    img.convert("RGB").save(os.path.join(SORTIE_CINE, "cine_1_mer.png"))

    # ---- 2. La barque et l'enfant
    img = fond([(0.00, (52, 48, 78)), (0.28, (104, 92, 132)), (0.48, (186, 148, 160)),
                (0.55, (248, 196, 172)), (0.57, (150, 178, 198)), (1.00, (96, 132, 160))])
    etoiles(img, 70, H * 0.28, graine=12)
    halo(img, L * 0.28, H * 0.50, 170, SOLEIL, 0.40)
    for i in range(60):
        r = random.Random(200 + i)
        y = r.uniform(H * 0.58, H)
        prof = (y - H * 0.58) / (H * 0.42)
        longueur = r.uniform(5, 36) * (0.4 + prof * 1.5)
        x = L * 0.36 + r.gauss(0, 40 + prof * 80) - longueur / 2
        tache(img, [(x, y), (x + longueur, y), (x + longueur, y + 2), (x, y + 2)],
              (255, 230, 198), int(60 * (1 - prof * 0.5)), 1.2)
    # coque
    cx, cy = L * 0.46, H * 0.665
    tache(img, [(cx - 150, cy - 22), (cx + 150, cy - 22), (cx + 112, cy + 40), (cx - 112, cy + 40)],
          (146, 104, 84), 235, 2.4)
    tache(img, [(cx - 150, cy - 22), (cx + 150, cy - 22), (cx + 146, cy - 10), (cx - 146, cy - 10)],
          (186, 140, 108), 235, 2.0)
    # mât et voile
    trait(img, [(cx - 6, cy - 26), (cx - 6, cy - 250)], (120, 86, 70), 7, 210, 1.2)
    tache(img, [(cx - 2, cy - 240), (cx + 104, cy - 104), (cx - 2, cy - 46)], (252, 238, 214), 225, 2.6)
    # l'enfant, de dos, assis au fond de la barque
    chibi(img, cx - 26, cy - 96, 190, dos=True, graine=3)
    # lanterne de proue
    halo(img, cx + 126, cy - 52, 96, (255, 198, 146), 0.75)
    disque(img, cx + 126, cy - 52, 17, LANTERNE, 240, 1.8)
    trait(img, [(cx + 126, cy - 26), (cx + 126, cy - 20)], (120, 80, 68), 3, 180, 0.8)
    papier(img, 11)
    img.convert("RGB").save(os.path.join(SORTIE_CINE, "cine_2_barque.png"))

    # ---- 3. L'île
    img = fond([(0.00, (252, 228, 208)), (0.20, (250, 206, 184)), (0.40, (252, 222, 190)),
                (0.55, (253, 240, 216)), (0.615, (214, 228, 214)),
                (0.62, MER_HAUT), (0.82, (136, 172, 190)), (1.00, MER_BAS)])
    halo(img, L * 0.30, H * 0.22, 320, (255, 244, 214), 0.55)
    base = H * 0.615
    tache(img, [(0, base), (L * 0.16, base - 116), (L * 0.30, base - 66), (L * 0.42, base - 146),
                (L * 0.56, base - 80), (L * 0.70, base - 128), (L * 0.84, base - 62), (L, base - 106),
                (L, base), (0, base)], (200, 214, 196), 220, 3.0)
    profil = [(0.08, 0), (0.15, 46), (0.23, 34), (0.30, 126), (0.38, 192),
              (0.45, 156), (0.53, 214), (0.61, 126), (0.69, 94), (0.78, 44), (0.90, 0)]
    pts = [(L * x, base - y) for x, y in profil] + [(L * 0.90, base + 6), (L * 0.08, base + 6)]
    tache(img, pts, ILE, 240, 2.6)
    rr = random.Random(63)
    for _ in range(24):
        tx = L * rr.uniform(0.12, 0.86)
        ty = base - rr.uniform(8, 66)
        rad = rr.uniform(9, 18)
        trait(img, [(tx, ty + rad * 0.5), (tx, ty + rad * 1.4)], (128, 96, 74), 3, 170, 1.0)
        disque(img, tx, ty, rad, (108, 152, 116), 215, 2.2)
    # pagode pastel
    px, py = L * 0.53, base - 210
    for i in range(3):
        w0 = 52 - i * 12
        y0 = py + i * 30
        tache(img, [(px - w0, y0), (px + w0, y0), (px + w0 * 0.60, y0 - 18), (px - w0 * 0.60, y0 - 18)],
              (176, 118, 104), 235, 1.8)
        tache(img, [(px - w0 * 0.48, y0), (px + w0 * 0.48, y0), (px + w0 * 0.48, y0 + 30), (px - w0 * 0.48, y0 + 30)],
              TERRE, 235, 1.8)
    trait(img, [(px, py - 18), (px, py - 40)], (140, 96, 82), 3, 200, 0.8)
    # reflet
    HAUT = 220
    bande = img.crop((0, int(base - HAUT), L, int(base))).transpose(Image.FLIP_TOP_BOTTOM)
    bande = bande.filter(ImageFilter.GaussianBlur(3.0))
    masque = Image.linear_gradient("L").resize((L, HAUT), Image.BILINEAR)
    masque = masque.transpose(Image.FLIP_TOP_BOTTOM).point(lambda v: int(v * 0.42))
    bande.putalpha(masque)
    img.alpha_composite(bande, (0, int(base)))
    # barque au loin, avec l'enfant
    bx, by = L * 0.19, base + 22
    tache(img, [(bx - 42, by), (bx + 42, by), (bx + 32, by + 14), (bx - 32, by + 14)], (146, 104, 84), 225, 1.6)
    chibi(img, bx, by - 34, 74, dos=True, graine=9)
    # lanternes du rivage
    for i in range(8):
        lx = L * (0.10 + i * 0.112) + ((i % 2) - 0.5) * 16
        ly = base - 10 + (i % 3) * 5
        halo(img, lx, ly, 56, (255, 190, 140), 0.70)
        disque(img, lx, ly, 10, LANTERNE, 238, 1.4)
        disque(img, lx, ly - 13, 5, (150, 92, 70), 225, 1.0)
    papier(img, 12)
    img.convert("RGB").save(os.path.join(SORTIE_CINE, "cine_3_ile.png"))

    # ---- 4. Lanternes et cerisier
    img = fond([(0.00, (66, 56, 82)), (0.34, (108, 82, 100)), (0.62, (172, 122, 118)),
                (0.80, (206, 152, 132)), (1.00, (108, 78, 82))])
    halo(img, L * 0.50, H * 0.40, 320, (255, 186, 150), 0.28)
    branche = [(L * 0.02, H * 0.15), (L * 0.26, H * 0.19), (L * 0.48, H * 0.14), (L * 0.74, H * 0.21)]
    trait(img, branche, (98, 68, 62), 15, 220, 2.0)
    trait(img, branche, (140, 100, 88), 7, 190, 1.6)
    r = random.Random(31)
    for _ in range(130):
        t = r.random()
        idx = min(len(branche) - 2, int(t * (len(branche) - 1)))
        bx = branche[idx][0] + (branche[idx + 1][0] - branche[idx][0]) * (t * (len(branche) - 1) - idx)
        by = branche[idx][1] + (branche[idx + 1][1] - branche[idx][1]) * (t * (len(branche) - 1) - idx)
        disque(img, bx + r.uniform(-46, 46), by + r.uniform(-40, 40), r.uniform(5, 10),
               (250, 198, 208), r.randint(120, 210), 1.8)
    for i in range(4):
        lx = L * (0.16 + i * 0.22)
        ly = H * (0.33 + (i % 2) * 0.07)
        trait(img, [(lx, H * 0.16), (lx, ly - 30)], (110, 76, 66), 2, 150, 0.9)
        halo(img, lx, ly, 110, (255, 180, 130), 0.72)
        tache(img, [(lx - 20, ly - 28), (lx + 20, ly - 28), (lx + 24, ly + 28), (lx - 24, ly + 28)],
              LANTERNE, 238, 2.0)
        tache(img, [(lx - 12, ly - 34), (lx + 12, ly - 34), (lx + 12, ly - 26), (lx - 12, ly - 26)],
              (150, 92, 70), 230, 1.4)
    # bas du cadre : colline, eau, brume
    tache(img, [(0, H * 0.72), (L * 0.18, H * 0.66), (L * 0.36, H * 0.71),
                (L * 0.55, H * 0.63), (L * 0.74, H * 0.70), (L, H * 0.65), (L, H), (0, H)],
          (96, 72, 84), 235, 2.8)
    tache(img, [(0, H * 0.86), (L, H * 0.86), (L, H), (0, H)], (74, 58, 72), 240, 2.2)
    brume = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(brume).rectangle([0, H * 0.83, L, H * 0.90], fill=(226, 176, 164, 46))
    img.alpha_composite(brume.filter(ImageFilter.GaussianBlur(16)))
    for i in range(6):
        halo(img, L * (0.10 + i * 0.16), H * 0.74 + (i % 2) * 22, 40, (255, 170, 120), 0.45)
    papier(img, 13)
    img.convert("RGB").save(os.path.join(SORTIE_CINE, "cine_4_lanternes.png"))

    # ---- 5. Fond de titre (le texte est posé par Godot, donc traduisible)
    img = fond([(0.00, (58, 54, 88)), (0.38, (98, 88, 124)), (0.64, (172, 138, 148)),
                (0.84, (228, 178, 152)), (1.00, (246, 206, 172))])
    etoiles(img, 150, H * 0.46, graine=44)
    halo(img, L * 0.5, H * 0.62, 360, (255, 214, 170), 0.30)
    tache(img, [(0, H * 0.80), (L * 0.16, H * 0.72), (L * 0.34, H * 0.78),
                (L * 0.54, H * 0.70), (L * 0.74, H * 0.77), (L, H * 0.71), (L, H), (0, H)],
          (78, 64, 80), 240, 2.8)
    for i in range(9):
        lx = L * (0.06 + i * 0.11)
        ly = H * (0.745 + (i % 3) * 0.028)
        halo(img, lx, ly, 46, (255, 180, 130), 0.55)
        disque(img, lx, ly, 7, LANTERNE, 235, 1.3)
    papier(img, 11)
    img.convert("RGB").save(os.path.join(SORTIE_CINE, "cine_5_titre.png"))

    print("cinematique :", len([f for f in os.listdir(SORTIE_CINE) if f.endswith(".png")]))
    return ()


@app.cell
def _(mo, os, SORTIE_CINE, SORTIE_UI):
    """Aperçu — visible dans marimo, sans effet en exécution script."""
    fichiers = [os.path.join(SORTIE_UI, f) for f in sorted(os.listdir(SORTIE_UI)) if f.endswith(".png")]
    fichiers += [os.path.join(SORTIE_CINE, f) for f in sorted(os.listdir(SORTIE_CINE)) if f.endswith(".png")]
    mo.vstack([mo.hstack([mo.image(f, width=110) for f in fichiers[:6]]),
               mo.hstack([mo.image(f, width=140) for f in fichiers[6:11]])])
    return (fichiers,)


if __name__ == "__main__":
    app.run()
