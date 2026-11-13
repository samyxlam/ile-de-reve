"""Génère les 30 icônes d'objets (5 chaînes × 6 niveaux) avec l'API Agnes.

Sortie : assets/objets/<chaine>-<niveau>.jpg, 256×256, fond crème.
Le fond crème est voulu : l'icône remplace la pastille colorée, elle n'a pas besoin
d'être détourée. Un JPEG de 256 px pèse ~30 Ko, contre 1,4 Mo pour le PNG 512 d'origine.

    python outils/agnes_icones.py --plage 0 15
    python outils/agnes_icones.py --plage 15 30
"""
import argparse
import os
import time
import urllib.request

from PIL import Image

from agnes_images import charger_env, demander

TAILLE = "1K"               # palier de résolution
RATIO = "1:1"
MODELE = "agnes-image-2.0-flash"   # plus droit et centré que 2.1 : meilleur pour une grille
SORTIE_PX = 256             # taille finale dans le jeu

GABARIT = ("game item icon, one single object centered, {}, retro 1980s cel anime "
           "style, vintage hand-drawn cartoon, clean thick ink outlines in warm brown, "
           "flat cel shading with one soft shadow tone, chibi proportions, cozy warm "
           "color palette, cream paper background, gentle drop shadow, no text, no "
           "border, no frame")

# id -> description anglaise (les noms français sont trop imprécis pour le modèle)
OBJETS = [
    ("bois-1", "a small weathered piece of driftwood, pale grey wood"),
    ("bois-2", "a neat stack of smooth planed wooden planks"),
    ("bois-3", "a long carved wooden crossbeam"),
    ("bois-4", "a wooden scaffolding frame with a small ladder"),
    ("bois-5", "a small wooden work hut with a tiled roof"),
    ("bois-6", "an ornate chinese wooden temple gate"),
    ("ferme-1", "a tiny seed sprouting from dark soil"),
    ("ferme-2", "a tender green sprout with two leaves"),
    ("ferme-3", "a sweet orange carrot with fresh green leaves"),
    ("ferme-4", "a round red tomato on a small vine"),
    ("ferme-5", "a woven wicker basket full of vegetables"),
    ("ferme-6", "a festive platter with roasted meat and garnish"),
    ("forge-1", "a rough grey stone block"),
    ("forge-2", "a short iron chain with three links"),
    ("forge-3", "a blacksmith hammer with a wooden handle"),
    ("forge-4", "a heavy iron anvil"),
    ("forge-5", "a glowing brass lantern"),
    ("forge-6", "a curved ceremonial sword blade"),
    ("tissu-1", "a spool of fine silk thread"),
    ("tissu-2", "a red chinese lucky knot with tassels"),
    ("tissu-3", "a ball of colorful yarn"),
    ("tissu-4", "a folded warm wool winter cloth"),
    ("tissu-5", "a folded embroidered festival robe"),
    ("tissu-6", "a tall ceremonial banner on a pole"),
    ("ceramique-1", "a small cup of clear spring water"),
    ("ceramique-2", "a small ceramic tea cup"),
    ("ceramique-3", "a round ceramic teapot"),
    ("ceramique-4", "a tin jug with a handle"),
    ("ceramique-5", "an ancient blue ceramic vase"),
    ("ceramique-6", "a glowing brass oil lamp"),
    # Générateurs posés sur le plateau (un par chaîne)
    ("gen-bois", "a small woodcutter axe stuck in a wooden stump"),
    ("gen-ferme", "a small vegetable garden plot with a watering can"),
    ("gen-forge", "a small blacksmith forge with glowing coals"),
    ("gen-tissu", "a small wooden weaving loom with colorful threads"),
    ("gen-ceramique", "a small pottery kiln with clay pots"),
]


def generer(env, cle, description, dossier, tentatives=3):
    dest = os.path.join(dossier, cle + ".jpg")
    if os.path.exists(dest) and os.path.getsize(dest) > 8000:
        print("  =   %-12s déjà là" % cle)
        return True
    for essai in range(1, tentatives + 1):
        try:
            url = demander(env, GABARIT.format(description), TAILLE, RATIO, modele=MODELE)
            with urllib.request.urlopen(url, timeout=180) as r:
                data = r.read()
            tmp = dest + ".tmp.png"
            with open(tmp, "wb") as f:
                f.write(data)
            im = Image.open(tmp).convert("RGB").resize((SORTIE_PX, SORTIE_PX), Image.LANCZOS)
            im.save(dest, quality=90)
            os.remove(tmp)
            print("  ok  %-12s %d Ko" % (cle, os.path.getsize(dest) // 1024))
            time.sleep(0.8)
            return True
        except Exception as e:
            print("  ..  %s essai %d : %s" % (cle, essai, str(e)[:80]))
            time.sleep(3)
    print("  KO  %s" % cle)
    return False


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--plage", nargs=2, type=int, default=[0, len(OBJETS)])
    args = ap.parse_args()

    env = charger_env()
    dossier = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "objets")
    os.makedirs(dossier, exist_ok=True)
    debut, fin = args.plage
    for cle, description in OBJETS[debut:fin]:
        generer(env, cle, description, dossier)


if __name__ == "__main__":
    main()
