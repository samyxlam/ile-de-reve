"""Génère les tableaux de la cinématique par IA, sans clé ni compte.

Le modèle FLUX.1-schnell est appelé via son Space public Hugging Face (API Gradio).
Aucun filigrane, aucune inscription. Si le Space est saturé, on retente avec un délai.

    python outils/generer_images.py            # (re)génère les 5 tableaux
    python outils/generer_images.py --essai 2  # seulement le tableau n°2

Style visé : cel-anime rétro 1984-89, chibi, cozy. Les prompts décrivent l'esthétique
(contours d'encre bruns, aplats plats, proportions chibi, lumière chaude) sans nommer
de licence.
"""
import argparse
import os
import shutil
import time

from PIL import Image

LARGEUR, HAUTEUR = 720, 1280
ESPACE = "black-forest-labs/FLUX.1-schnell"

STYLE = ("retro 1980s anime background art, hand-painted cel animation style, warm "
         "nostalgic evening light, soft pastel sky, clean defined shapes, cozy "
         "heartwarming mood, subtle film grain, no text")

TABLEAUX = [
    ("cine_1_mer.png", 11,
     "calm sea at dusk, pastel sunset sky with soft stars, distant dark island silhouette "
     "on the horizon, shimmering reflections on the water, empty scene, wide shot, " + STYLE),
    ("cine_2_barque.png", 22,
     "a small chibi child with spiky dark hair seen from behind, sitting in a little wooden "
     "boat on a calm pastel sea at sunset, a glowing paper lantern on the bow, big head and "
     "tiny body, cozy adventure mood, " + STYLE),
    ("cine_3_ile.png", 33,
     "a small cozy island at dawn seen from the sea, a little pagoda on a green hill, cherry "
     "trees, paper lanterns glowing along the shore, a tiny boat approaching in the foreground, "
     "clean cel colors, dreamy, " + STYLE),
    ("cine_4_lanternes.png", 44,
     "close view of glowing paper lanterns hanging from a cherry blossom branch at dusk, "
     "pink petals falling, warm bokeh, dark cozy background, " + STYLE),
    ("cine_5_titre.png", 55,
     "dreamy dusk sky over a dark island silhouette, glowing paper lanterns scattered at the "
     "bottom, large empty soft area in the middle for a title, calm and inviting, " + STYLE),
]


def generer(client, nom, graine, prompt, dossier, tentatives=3):
    dest = os.path.join(dossier, nom)
    for essai in range(1, tentatives + 1):
        try:
            resultat = client.predict(
                prompt=prompt, seed=graine, randomize_seed=False,
                width=LARGEUR, height=HAUTEUR, num_inference_steps=4, api_name="/infer")
            chemin = resultat[0] if isinstance(resultat, (tuple, list)) else resultat
            im = Image.open(chemin).convert("RGB")
            if im.size != (LARGEUR, HAUTEUR):
                im = im.resize((LARGEUR, HAUTEUR), Image.LANCZOS)
            im.save(dest, quality=93)
            print("  ok  %s  (%dx%d)" % (nom, im.size[0], im.size[1]))
            return True
        except Exception as e:
            print("  ..  %s essai %d : %s" % (nom, essai, e))
            time.sleep(6 * essai)
    print("  KO  %s" % nom)
    return False


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--essai", type=int, default=0, help="numéro du tableau à générer seul")
    args = ap.parse_args()

    from gradio_client import Client

    dossier = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "cine")
    os.makedirs(dossier, exist_ok=True)
    client = Client(ESPACE, verbose=False)
    cibles = TABLEAUX if args.essai <= 0 else [TABLEAUX[args.essai - 1]]
    for nom, graine, prompt in cibles:
        generer(client, nom, graine, prompt, dossier)


if __name__ == "__main__":
    main()
