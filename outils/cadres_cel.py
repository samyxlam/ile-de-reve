# Cadres d'interface en style cel-anime 1984-89 (aplats plats, liser d'encre).
# Remplace la livraison aquarelle d'atelier_assets.py pour les 6 cadres 9-slice :
# meme geometrie (104 px, marge 22), meme noms de fichiers.
#
#     python outils/cadres_cel.py
import os, shutil
from PIL import Image, ImageDraw

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SORTIE = os.path.join(RACINE, "assets", "ui")
SAUVEGARDE = r"C:\Users\Isl4m\AppData\Local\Temp\opencode\ui_avant"

TAILLE, RAYON = 104, 20   # 9-slice : marge 22 > rayon 20 (DA §5.2)
ENCRE = (74, 58, 40)      # #4a3a28 — tous les contours (DA §1)

# nom : (aplat, tonne d'ombre, liser lumineux, largeur contour)
CADRES = {
    "cadre_bois":            ((198, 138, 77), (150, 97, 52),  (226, 177, 120), 5),
    "cadre_parchemin":       ((247, 237, 218), (224, 206, 174), (255, 248, 232), 4),
    "cadre_parchemin_fonce": ((234, 221, 194), (206, 188, 156), (248, 238, 218), 4),
    "cadre_jade":            ((162, 198, 110), (118, 152, 72), (210, 234, 168), 5),
    "cadre_or":              ((235, 199, 110), (186, 148, 74), (250, 226, 160), 5),
    "cadre_encens":          ((150, 126, 112), (110, 88, 76),  (182, 158, 142), 5),
}


def cadre_aplat(nom, aplat, ombre, lueur, contour_px):
    """Aplat plat + bande d'ombre interne en bas + liser lumineux haut + trait d'encre."""
    img = Image.new("RGBA", (TAILLE, TAILLE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    fond = [1, 1, TAILLE - 2, TAILLE - 2]

    # 1) fit plat (aucun degrad, aucun flou : langage cel)
    d.rounded_rectangle(fond, RAYON, fill=aplat + (255,))

    # 2) unique tonne d'ombre, en bande plate le long du bord interne du bas
    d.rounded_rectangle(fond, RAYON, fill=ombre + (255,))
    d.rounded_rectangle([1, 1, TAILLE - 2, TAILLE - 8], RAYON, fill=aplat + (255,))

    # 3) liser lesion du haut (la lumiere de fin de journee)
    d.rounded_rectangle([4, 4, TAILLE - 5, TAILLE - 5], RAYON - 3,
                        outline=lueur + (255,), width=2)

    # 4) trait d'encre rond, quasi constante
    d.rounded_rectangle([2, 2, TAILLE - 3, TAILLE - 3], RAYON - 1,
                        outline=ENCRE + (255,), width=contour_px)

    img.save(os.path.join(SORTIE, nom + ".png"))
    return nom


def main():
    os.makedirs(SORTIE, exist_ok=True)
    os.makedirs(SAUVEGARDE, exist_ok=True)
    fait = []
    for nom, (aplat, ombre, lueur, px) in CADRES.items():
        dest = os.path.join(SORTIE, nom + ".png")
        if os.path.exists(dest):
            shutil.copy2(dest, os.path.join(SAUVEGARDE, nom + ".png"))
        fait.append(cadre_aplat(nom, aplat, ombre, lueur, px))
    print("cadres cel :", ", ".join(fait))


if __name__ == "__main__":
    main()
