"""Génère les tableaux de la cinématique avec l'API Agnes (agnes-image-2.1-flash).

La clé et l'URL sont lues dans ~/.agnes/agnes.env (jamais en dur dans le dépôt).

    python outils/agnes_images.py                 # les 5 tableaux
    python outils/agnes_images.py --seulement 4   # un seul

Format demandé : 720×1280 (portrait). Si le service refuse cette taille, on
génère en 768×1344 puis on redimensionne.
"""
import argparse
import json
import os
import time
import urllib.request

from PIL import Image

L, H = 720, 1280
L_REPLI, H_REPLI = 768, 1344

STYLE = ("retro 1980s anime background art, hand-painted cel animation style, warm "
         "nostalgic evening light, soft pastel sky, clean defined shapes, cozy "
         "heartwarming mood, subtle film grain, no text, no watermark")

TABLEAUX = [
    ("cine_1_mer.png", 11,
     "calm sea at dusk, pastel sunset sky with a few soft stars, a distant dark island "
     "silhouette on the horizon, shimmering golden reflections on the water, empty scene, "
     "wide establishing shot, " + STYLE),
    ("cine_2_barque.png", 22,
     "a small chibi child with spiky dark hair seen from behind, sitting in a little wooden "
     "boat on a calm pastel sea at sunset, a glowing paper lantern hanging on his back, big "
     "head and tiny body, cozy adventure mood, " + STYLE),
    ("cine_3_ile.png", 33,
     "wide establishing shot of a tiny island far away on a calm pastel sea at dawn, a small "
     "pagoda and cherry trees on a low green hill, thin morning mist, lots of soft sky, "
     + STYLE),
    ("cine_4_lanternes.png", 44,
     "a row of glowing paper lanterns hanging on a string at dusk, soft warm halos, cherry "
     "blossom petals floating in the air, cozy and calm, shallow depth of field, " + STYLE),
    ("cine_5_titre.png", 55,
     "empty dreamy dusk sky, soft pastel gradient from mauve to peach, thin clouds, a very "
     "dark island silhouette along the bottom edge, nothing else, lots of empty space in the "
     "middle, " + STYLE),
]


def charger_env():
    chemin = os.path.expanduser("~/.agnes/agnes.env")
    env = {}
    if os.path.exists(chemin):
        for ligne in open(chemin, encoding="utf-8"):
            if "=" in ligne:
                k, v = ligne.strip().split("=", 1)
                env[k] = v
    for k in ("AGNES_API_KEY", "AGNES_API_URL", "AGNES_MODEL"):
        if k in os.environ:
            env[k] = os.environ[k]
    if "AGNES_API_KEY" not in env:
        raise SystemExit("Clé absente : renseigne AGNES_API_KEY dans ~/.agnes/agnes.env")
    env.setdefault("AGNES_API_URL", "https://apihub.agnes-ai.com/v1/images/generations")
    env.setdefault("AGNES_MODEL", "agnes-image-2.1-flash")
    return env


def demander(env, prompt, taille="2K", ratio="9:16", modele=None):
    """Appelle l'API Agnes. `taille` accepte un palier (1K/2K/3K/4K) ou une taille exacte.

    D'après la référence API : `response_format` va dans `extra_body`, pas à la racine,
    et `ratio` n'a de sens qu'avec un palier de résolution.
    """
    corps = {
        "model": modele or env["AGNES_MODEL"],
        "prompt": prompt,
        "size": taille,
        "extra_body": {"response_format": "url"},
    }
    if taille.upper().endswith("K"):
        corps["ratio"] = ratio
    req = urllib.request.Request(
        env["AGNES_API_URL"],
        data=json.dumps(corps).encode(),
        headers={"Authorization": "Bearer " + env["AGNES_API_KEY"],
                 "Content-Type": "application/json"},
    )
    # 20 requêtes/min en gratuit : on temporise et on recule sur 429.
    for essai in range(4):
        try:
            rep = json.loads(urllib.request.urlopen(req, timeout=300).read())
            return rep["data"][0]["url"]
        except urllib.error.HTTPError as e:
            if e.code == 429:
                time.sleep(3 * (essai + 1))
                continue
            raise
    raise RuntimeError("limite de débit atteinte")


def generer(env, nom, prompt, dossier, tentatives=3):
    dest = os.path.join(dossier, nom)
    for essai in range(1, tentatives + 1):
        for taille, ratio in (("2K", "9:16"), ("%dx%d" % (L_REPLI, H_REPLI), ""), ("1024x1024", "")):
            try:
                url = demander(env, prompt, taille, ratio)
                with urllib.request.urlopen(url, timeout=180) as r:
                    data = r.read()
                tmp = dest + ".tmp.png"
                with open(tmp, "wb") as f:
                    f.write(data)
                im = Image.open(tmp).convert("RGB")
                if im.size != (L, H):
                    # recadrage centré au bon format, sans déformer
                    k = max(L / im.width, H / im.height)
                    im = im.resize((int(im.width * k + 1), int(im.height * k + 1)), Image.LANCZOS)
                    x = (im.width - L) // 2
                    y = (im.height - H) // 2
                    im = im.crop((x, y, x + L, y + H))
                im.save(dest, quality=93)
                os.remove(tmp)
                print("  ok  %-22s %s %s -> %dx%d" % (nom, taille, ratio, im.size[0], im.size[1]))
                time.sleep(1.0)
                return True
            except Exception as e:
                msg = str(e)[:90]
                if "size" in msg.lower() or "400" in msg or "invalid" in msg.lower():
                    continue          # taille refusée : on essaie la suivante
                print("  ..  %s essai %d (%s) : %s" % (nom, essai, taille, msg))
                time.sleep(3)
    print("  KO  %s" % nom)
    return False


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--seulement", type=int, default=0, help="numéro du tableau (1-5)")
    args = ap.parse_args()

    env = charger_env()
    dossier = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "cine")
    os.makedirs(dossier, exist_ok=True)
    cibles = TABLEAUX if args.seulement <= 0 else [TABLEAUX[args.seulement - 1]]
    for nom, _graine, prompt in cibles:
        generer(env, nom, prompt, dossier)


if __name__ == "__main__":
    main()
