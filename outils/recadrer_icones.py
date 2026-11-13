"""Recadre les icônes générées sur l'objet, pour qu'il remplisse la case du plateau.

L'API renvoie un carré 512 avec beaucoup de fond crème : l'objet n'occupe que la moitié
centrale. On détecte sa boîte par différence avec la couleur de fond, on recadre avec
une marge, on remet au carré et on réexporte en 256 px.

    python outils/recadrer_icones.py
"""
import glob
import os

from PIL import Image, ImageChops

PX = 256
MARGE = 0.14        # marge autour de l'objet, en fraction de sa plus grande dimension
SEUIL = 16


def boite(im):
    fond = Image.new("RGB", im.size, im.getpixel((2, 2)))
    diff = ImageChops.difference(im, fond).convert("L")
    masque = diff.point(lambda v: 255 if v > SEUIL else 0)
    return masque.getbbox()


def main():
    dossier = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "objets")
    fichiers = sorted(glob.glob(os.path.join(dossier, "*.jpg")))
    if not fichiers:
        print("aucune icône à traiter")
        return
    for chemin in fichiers:
        im = Image.open(chemin).convert("RGB")
        b = boite(im)
        if b is None:
            print("  ??  %s : fond uniforme" % os.path.basename(chemin))
            continue
        x0, y0, x1, y1 = b
        cote = max(x1 - x0, y1 - y0)
        cote = int(cote * (1 + 2 * MARGE))
        cx, cy = (x0 + x1) // 2, (y0 + y1) // 2
        gauche, haut = cx - cote // 2, cy - cote // 2
        # on reste dans l'image : on complète avec la couleur de fond si on dépasse
        fond = im.getpixel((2, 2))
        carre = Image.new("RGB", (cote, cote), fond)
        carre.paste(im.crop((max(0, gauche), max(0, haut), min(im.width, gauche + cote), min(im.height, haut + cote))),
                    (max(0, -gauche), max(0, -haut)))
        carre.resize((PX, PX), Image.LANCZOS).save(chemin, quality=90)
        print("  ok  %-14s objet %dx%d" % (os.path.basename(chemin), x1 - x0, y1 - y0))


if __name__ == "__main__":
    main()
