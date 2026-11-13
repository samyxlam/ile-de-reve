"""Complète la cinématique via l'endpoint public Pollinations (sans clé).

Corrige trois défauts constatés : bandes blanches laissées par le service,
filigrane en bas à droite, et prompts ambigus qui partent sur un autre sujet.

    python outils/completer_cine.py
"""
import os
import time
import urllib.parse
import urllib.request

from PIL import Image, ImageChops

L, H = 720, 1280
STYLE = ("retro 1980s anime background art, hand-painted cel animation style, warm "
         "nostalgic evening light, soft pastel sky, clean defined shapes, cozy "
         "heartwarming mood, subtle film grain, no text")

# Numéro, graine, prompt. Volontairement descriptif et sans objet ambigu.
A_REFAIRE = [
    (3, 33,
     "wide establishing shot of a tiny island far away on a calm pastel sea at dawn, "
     "small pagoda and cherry trees on a low green hill, thin mist, lots of sky, " + STYLE),
    (4, 44,
     "a row of glowing paper lanterns hanging on a string at dusk, soft warm halos, "
     "cherry blossom petals in the air, cozy and calm, " + STYLE),
    (5, 55,
     "empty dreamy dusk sky, soft pastel gradient from mauve to peach, thin clouds, "
     "a very dark island silhouette along the bottom edge, nothing else, " + STYLE),
]


def rogner(im):
    """Retire les bandes uniformes ajoutées par le service (blanches ou noires)."""
    im = im.convert("RGB")
    fond = Image.new("RGB", im.size, im.getpixel((0, 0)))
    bbox = ImageChops.difference(im, fond).getbbox()
    return im.crop(bbox) if bbox else im


def cadrer(im):
    """Recadre au centre au format 720×1280 sans déformer."""
    r = max(L / im.width, H / im.height)
    im = im.resize((int(im.width * r + 1), int(im.height * r + 1)), Image.LANCZOS)
    x = (im.width - L) // 2
    y = (im.height - H) // 2
    return im.crop((x, y, x + L, y + H))


def main():
    dossier = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "cine")
    for num, graine, prompt in A_REFAIRE:
        nom = "cine_%d_%s.png" % (num, {3: "ile", 4: "lanternes", 5: "titre"}[num])
        url = ("https://image.pollinations.ai/prompt/" + urllib.parse.quote(prompt)
               + f"?width={L}&height={H}&seed={graine}&nologo=true")
        for essai in range(1, 4):
            try:
                data = urllib.request.urlopen(url, timeout=180).read()
                if len(data) < 8000:
                    raise ValueError("image trop petite")
                tmp = os.path.join(dossier, "_tmp.jpg")
                with open(tmp, "wb") as f:
                    f.write(data)
                im = cadrer(rogner(Image.open(tmp)))
                im.save(os.path.join(dossier, nom), quality=93)
                os.remove(tmp)
                print("  ok  %s" % nom)
                break
            except Exception as e:
                print("  ..  %s essai %d : %s" % (nom, essai, e))
                time.sleep(5 * essai)
        else:
            print("  KO  %s" % nom)


if __name__ == "__main__":
    main()
