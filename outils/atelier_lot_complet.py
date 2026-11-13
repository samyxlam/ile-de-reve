# -*- coding: utf-8 -*-
"""Post-traitement du lot d'assets généré le 07/11/2026.

Sources : outils/lot_2026-11-07/*.png (générateur d'images IA, fond transparent
pour sprites, opaque pour décors). Le mapping source → destination se fait par
l'horodatage dans le nom de fichier.

Sorties :
  assets/batiments/<cle>.png       24 bâtiments, 256 px, fond transparent
  assets/activites/act_<i>.png      6 icônes d'activités, 256 px, fond transparent
  assets/sprites/pose_<n>.png       4 poses du personnage, 384 px, fond transparent
  assets/sprites/insulaire_poses.png  feuille de poses 2×2 (768×768)
  assets/store/logo_embleme.png     emblème rond détouré
  assets/store/icone_app_1024.png   icône application
  assets/store/banniere_1024x500.png bannière store avec titre composé
  assets/cine/cine_*.png            5 tableaux de cinématique 720×1280 (remplace)
  outils/planche_batiments.png      planche de contrôle QA (bâtiments + activités)
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

RACINE = Path(__file__).resolve().parent.parent
LOT = RACINE / "outils" / "lot_2026-11-07"

# --------------------------------------------------------------- mapping
BATIMENTS = {
    # printemps
    "spr1": "15-21-54", "spr2": "15-58-39", "spr3": "15-22-30",
    "spr4": "15-22-46", "spr5": "15-23-01", "spr6": "15-23-16",
    # été
    "sum1": "15-24-00", "sum2": "15-24-16", "sum3": "15-24-32",
    "sum4": "15-59-46", "sum5": "15-25-06", "sum6": "15-25-24",
    # automne
    "aut1": "15-26-06", "aut2": "15-26-25", "aut3": "15-26-45",
    "aut4": "15-58-54", "aut5": "15-27-20", "aut6": "15-27-37",
    # hiver
    "win1": "15-28-15", "win2": "15-28-29", "win3": "15-28-43",
    "win4": "15-59-13", "win5": "15-59-30", "win6": "15-29-31",
}
ACTIVITES = {
    0: "15-30-32",  # fouille : loupe sur carte
    1: "15-30-50",  # pass lunaire : croissant + lanterne
    2: "15-31-07",  # classement : trophée
    3: "15-31-23",  # cadeaux : boîte cadeau
    4: "15-31-40",  # roue de la fortune
    5: "15-31-55",  # don : coffre lumineux
}
POSES = {
    0: "15-32-46",  # salut
    1: "15-33-01",  # joie
    2: "15-33-18",  # réflexion
    3: "15-33-36",  # pièce
}
CINE = {
    "cine_1_mer.png": "15-35-37",
    "cine_2_barque.png": "15-35-56",
    "cine_3_ile.png": "15-36-17",
    "cine_4_lanternes.png": "16-03-45",
    "cine_5_titre.png": "15-36-51",
}
LOGO = "16-04-07"
ICONE_APP = "15-34-07"
BANNIERE = "15-34-31"


def detourage(img: Image.Image, seuil: int = 14) -> Image.Image:
    """Rend transparent le fond uni (même légèrement dégradé) d'une image.

    Segmentation par composantes connexes : les pixels « lisses » (faible
    variation locale) forment des régions ; celles qui touchent le bord de
    l'image sont le fond — même s'il dégradent —, le reste est l'objet, dont
    les blancs internes sont protégés par le contour d'encre. Deuxièeme passe
    à seuil large si le fond est texturé. Un filtre de 1 px + flou court
    adoucit l'anti-aliasing du contour.
    """
    import numpy as np
    from scipy import ndimage

    rgb = np.asarray(img.convert("RGB")).astype(np.int16)
    alpha_final = None
    meilleur = None
    for essai in (seuil, 22, 45):
        dx = np.abs(rgb - np.roll(rgb, 1, axis=1)).max(axis=2)
        dy = np.abs(rgb - np.roll(rgb, 1, axis=0)).max(axis=2)
        lisse = (dx < essai) & (dy < essai)
        lisse[0, :] = lisse[-1, :] = lisse[:, 0] = lisse[:, -1] = True
        etiquette, _ = ndimage.label(lisse)
        bords = set(etiquette[0, :]) | set(etiquette[-1, :]) | \
            set(etiquette[:, 0]) | set(etiquette[:, -1])
        bords.discard(0)
        fond = np.isin(etiquette, list(bords))
        alpha = np.where(fond, 0, 255).astype(np.uint8)
        ratio = alpha.mean() / 255.0
        # L'objet doit couvrir entre 12 % et 78 % de l'image : en dessous,
        # le seuil a mangé l'objet ; au-dessus, le fond reste collé.
        if 0.12 <= ratio <= 0.78:
            alpha_final = alpha
            break
        if meilleur is None or abs(ratio - 0.45) < abs(meilleur[1] - 0.45):
            meilleur = (alpha, ratio)
    if alpha_final is None:
        alpha_final = meilleur[0] if meilleur else np.full(rgb.shape[:2], 255, np.uint8)
    masque = Image.fromarray(alpha_final, "L")
    masque = masque.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.8))
    out = img.convert("RGBA")
    out.putalpha(masque)
    return out


def source(horodatage: str) -> Image.Image:
    """Ouvre la source du lot par son horodatage, quel que soit son préfixe."""
    for f in LOT.glob("*.png"):
        if horodatage in f.name:
            return Image.open(f).convert("RGBA")
    raise FileNotFoundError(horodatage)


def cadrer_alpha(img: Image.Image, marge: float = 0.06, taille: int = 256) -> Image.Image:
    """Recadre sur la boîte englobante de l'alpha, met en carré avec marge, redimensionne."""
    boite = img.getbbox()
    if boite:
        img = img.crop(boite)
    cote = max(img.size)
    pad = int(cote * marge)
    carree = Image.new("RGBA", (cote + pad * 2, cote + pad * 2), (0, 0, 0, 0))
    carree.paste(img, (pad, pad), img)
    return carree.resize((taille, taille), Image.LANCZOS)


def ecris_titre(banniere: Image.Image) -> Image.Image:
    """Compose le titre du jeu sur la zone de ciel libre (moitié gauche)."""
    fnt_dir = RACINE / "fonts"
    chemins = sorted(fnt_dir.glob("*.otf")) + sorted(fnt_dir.glob("*.ttf"))
    fnt = None
    for c in chemins:
        try:
            fnt = ImageFont.truetype(str(c), 118)
            break
        except OSError:
            continue
    if fnt is None:
        fnt = ImageFont.load_default()

    calque = Image.new("RGBA", banniere.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(calque)
    titre = "Île de Rêve"
    # Ombre portée douce puis texte crème avec liseré encre : lisibilité sur ciel clair.
    d.text((72, 96), titre, font=fnt, fill=(74, 58, 40, 150),
           stroke_width=10, stroke_fill=(74, 58, 40, 150))
    d.text((66, 88), titre, font=fnt, fill=(255, 248, 234, 255),
           stroke_width=8, stroke_fill=(74, 58, 40, 255))
    sous = ImageFont.truetype(str(chemins[0]), 34) if chemins else fnt
    d.text((74, 250), "cozy island · merge · 1984 cel anime", font=sous,
           fill=(255, 248, 234, 220), stroke_width=4, stroke_fill=(74, 58, 40, 220))
    calque = calque.filter(ImageFilter.GaussianBlur(0.4))
    out = banniere.convert("RGBA")
    out.alpha_composite(calque)
    return out


def main() -> None:
    rep_bat = RACINE / "assets" / "batiments"
    rep_act = RACINE / "assets" / "activites"
    rep_spr = RACINE / "assets" / "sprites"
    rep_store = RACINE / "assets" / "store"
    rep_cine = RACINE / "assets" / "cine"
    for rep in (rep_bat, rep_act, rep_store):
        rep.mkdir(parents=True, exist_ok=True)

    # 1. bâtiments --------------------------------------------------------
    for cle, h in BATIMENTS.items():
        cadrer_alpha(detourage(source(h))).save(rep_bat / f"{cle}.png", optimize=True)
    print(f"bâtiments : {len(BATIMENTS)} écrits dans {rep_bat}")

    # 2. activités --------------------------------------------------------
    for i, h in ACTIVITES.items():
        cadrer_alpha(detourage(source(h))).save(rep_act / f"act_{i}.png", optimize=True)
    print(f"activités : {len(ACTIVITES)} écrites dans {rep_act}")

    # 3. poses du personnage + feuille 2×2 --------------------------------
    poses = []
    for n, h in POSES.items():
        p = cadrer_alpha(detourage(source(h)), marge=0.04, taille=384)
        p.save(rep_spr / f"pose_{n}.png", optimize=True)
        poses.append(p)
    feuille = Image.new("RGBA", (768, 768), (0, 0, 0, 0))
    for n, p in enumerate(poses):
        feuille.paste(p, ((n % 2) * 384, (n // 2) * 384), p)
    feuille.save(rep_spr / "insulaire_poses.png", optimize=True)
    print("poses : 4 individuelles + feuille 2×2")

    # 4. store ------------------------------------------------------------
    cadrer_alpha(detourage(source(LOGO)), marge=0.02, taille=1024).save(
        rep_store / "logo_embleme.png", optimize=True)
    source(ICONE_APP).convert("RGB").resize((1024, 1024), Image.LANCZOS).save(
        rep_store / "icone_app_1024.png", optimize=True)
    br = source(BANNIERE).convert("RGB")
    # 1536×1024 → ratio 2.048 : on garde 750 px de haut, centré un peu bas
    # pour laisser le ciel au titre.
    haut = 750
    haut_ = br.height - haut
    decoupe = br.crop((0, int(haut_ * 0.45), br.width, int(haut_ * 0.45) + haut))
    banniere = decoupe.resize((1024, 500), Image.LANCZOS)
    ecris_titre(banniere).save(rep_store / "banniere_1024x500.png", optimize=True)
    print("store : logo, icône app, bannière 1024×500")

    # 5. cinématique : 1024×1536 → 720×1280 (recadrage latéral + bande bas
    #    rognée : le filigrane du générateur vit dans les 100 px du bas) -----
    for nom, h in CINE.items():
        img = source(h).convert("RGB")
        img = img.crop((0, 0, img.width, img.height - 100))
        largeur = int(img.height * 720 / 1280)
        x = (img.width - largeur) // 2
        img.crop((x, 0, x + largeur, img.height)).resize(
            (720, 1280), Image.LANCZOS).save(rep_cine / nom, optimize=True)
    print("cinématique : 5 tableaux 720×1280 remplacés")

    # 6. planche QA : bâtiments sur fond de leur saison + activités --------
    couleurs = {
        "spr": (182, 212, 140), "sum": (143, 208, 199),
        "aut": (224, 183, 106), "win": (174, 198, 218),
    }
    cell, marg = 128, 10
    colonnes = 6
    lignes = (len(BATIMENTS) + colonnes - 1) // colonnes + 1
    planche = Image.new("RGB", (colonnes * (cell + marg) + marg,
                                lignes * (cell + marg) + marg), (247, 237, 218))
    couleurs = {"spr": (182, 212, 140), "sum": (143, 208, 199),
                "aut": (224, 183, 106), "win": (174, 198, 218)}
    icone_taille = cell - 16

    def poser(fond_rgb, ic_img, x, y):
        """Colle une icône réduite sur un fond de cellule solide."""
        fond = Image.new("RGBA", (cell, cell), fond_rgb + (255,))
        petit = ic_img.copy()
        petit.thumbnail((icone_taille, icone_taille), Image.LANCZOS)
        fond.alpha_composite(petit, ((cell - petit.width) // 2, (cell - petit.height) // 2))
        planche.paste(fond.convert("RGB"), (x, y))

    for i, (cle, _) in enumerate(BATIMENTS.items()):
        ic = Image.open(rep_bat / f"{cle}.png")
        x = marg + (i % colonnes) * (cell + marg)
        y = marg + (i // colonnes) * (cell + marg)
        poser(couleurs[cle[:3]], ic, x, y)
    for i in range(len(ACTIVITES)):
        ic = Image.open(rep_act / f"act_{i}.png")
        k = len(BATIMENTS) + i
        x = marg + (k % colonnes) * (cell + marg)
        y = marg + (k // colonnes) * (cell + marg)
        poser((243, 226, 182), ic, x, y)
    planche.save(RACINE / "outils" / "planche_lot_complet.png")
    print("planche QA : outils/planche_lot_complet.png")


if __name__ == "__main__":
    main()
