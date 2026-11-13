# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "marimo>=0.16,<1",
#   "diffusers>=0.35,<1",
#   "transformers>=4.44,<5",
#   "accelerate>=0.34,<2",
#   "safetensors>=0.4,<1",
#   "pillow>=10,<13",
# ]
# ///

import marimo

__generated_with = "0.25.2"
app = marimo.App(width="medium")


@app.cell
def _():
    import marimo as mo

    return (mo,)


@app.cell
def _(mo):
    mo.md(
        """
        # Île de Rêve — atelier **batch** Molab

        Génère **tout le lot d'assets en un seul clic** sur le GPU gratuit de Molab :
        24 bâtiments, 6 activités, 4 poses du personnage, logo, icône app, bannière
        et les 5 tableaux de cinématique — le tout en un seul ZIP avec manifeste.

        **Reprise sur interruption :** chaque image déjà présente dans
        `generated_images/` est sautée. Tu peux arrêter la session et revenir :
        seules les images manquantes seront générées.

        **Procédure :** *Notebook settings → Compute → RTX Pro 6000*, attendre le
        démarrage, puis cliquer **Générer le lot restant** (~25 min pour 43 images,
        + 3 min de téléchargement du modèle au premier lancement).

        **Moteur :** `cagliostrolab/animagine-xl-4.0` (Diffusers, Euler Ancestral,
        28 étapes, CFG 5). Licence CreativeML Open RAIL++-M — usage commercial
        autorisé sous ses conditions ; conserver la notice avec le jeu.
        """
    )
    return


@app.cell
def _(mo):
    import torch

    if torch.cuda.is_available():
        mo.md(
            "**GPU actif :** %s — %.1f Go VRAM"
            % (
                torch.cuda.get_device_name(0),
                torch.cuda.get_device_properties(0).total_memory / 1e9,
            )
        )
    else:
        mo.callout(
            mo.md(
                "Aucun GPU CUDA détecté. Dans Molab : *Notebook settings* → *Compute* → **RTX Pro 6000**, puis *Try again*."
            ),
            kind="warn",
        )
    return (torch,)


@app.cell
def _():
    # ------------------------------------------------- gabarits de style
    # Source de vérité : DIRECTION_ARTISTIQUE.md §5.1 et §11. Les prompts sont
    # des tags compacts (Animagine est entraîné en tags) ; la qualité est
    # ajoutée à la fin, le négatif chasse les fonds à damier et les filigranes.
    QUALITE = "safe, masterpiece, best quality, high score, great score"
    NEGATIF = (
        "lowres, bad anatomy, bad hands, text, error, cropped, worst quality, "
        "low quality, low score, bad score, signature, watermark, username, "
        "blurry, checkered background, transparency checkerboard, "
        "halftone background, pattern background, depth of field, bokeh"
    )
    STYLES = {
        "icone": (
            "1980s cel anime, warm-brown ink outlines, flat colors, "
            "two-tone cel shading, cozy island mood, chibi scale, "
            "plain white background, no text, no watermark"
        ),
        "pose": (
            "1980s cel anime, warm-brown ink outlines, flat colors, "
            "two-tone cel shading, plain white background, "
            "no text, no watermark"
        ),
        "decor": (
            "anime background art, hand-painted 1980s cel animation, "
            "warm-brown ink outlines, crisp flat color fields, "
            "soft cel shading, no text, no watermark"
        ),
    }

    # ------------------------------------------------- sujets (validés QA 07/11)
    BATIMENTS = {
        "spr1": "wooden pavilion house, curved tiled roof, round window, hanging wooden sign",
        "spr2": "ancient blooming cherry tree, wide pink blossom canopy, thick brown trunk, grass tuft",
        "spr3": "round wooden gazebo, misty blue curved roof, wooden posts, small bench",
        "spr4": "wooden market stall, striped awning, fruit baskets, clay jars",
        "spr5": "cozy tea house, sloped tiled roof, glowing paper lantern, steaming teapot sign",
        "spr6": "two-story wooden waystation inn, curved roof, banner flags, warm lit windows",
        "sum1": "thatched hut, round lotus-leaf roof, tiny pond patch",
        "sum2": "small wooden rowboat, pink and white flowers along the edge, tiny oar",
        "sum3": "arched jade-green wooden bridge over a small strip of blue water",
        "sum4": "vertical wooden lantern pole, three glowing orange paper lanterns, leafy vines",
        "sum5": "small candy shop stall, glass jars of colorful sweets, striped awning",
        "sum6": "elegant wooden pleasure boat, small round sail, lotus flowers on deck",
        "aut1": "golden maple tree, warm orange and red foliage, small pile of fallen leaves",
        "aut2": "embroidery hall pavilion, colorful fabric banners, curved roof",
        "aut3": "low wooden table, stack of round mooncakes, teapot, two cups",
        "aut4": "small stone wine cellar hut, arched doorway, two wooden barrels, green vines, no moon",
        "aut5": "tall wooden watch tower, balcony, small telescope, flag on top",
        "aut6": "small museum building, warm sunset mural on the wall, arched doorway",
        "win1": "small round pavilion, soft blue curved roof, thick snow layer, icicles",
        "win2": "friendly round snowman, warm red scarf, twig arms, happy smile",
        "win3": "tiny wooden ski hut, snow on roof, pair of skis leaning on the wall",
        "win4": "wooden sledge, red runner straps, green scarf, no snow, no ground, no trees",
        "win5": "wooden lantern stand, three glowing orange paper lanterns, light snow on top",
        "win6": "grand winter palace, snow-curved blue roofs, warm glowing windows",
    }
    ACTIVITES = {
        "act_0": "large magnifying glass over a folded treasure map",
        "act_1": "glowing golden crescent moon, small hanging paper lantern, drifting cherry petals",
        "act_2": "golden trophy cup, jade-green ribbon, small sparkles",
        "act_3": "round gift box tied with a warm red ribbon bow",
        "act_4": "colorful fortune wheel, eight warm-colored sectors, small wooden pointer",
        "act_5": "open treasure chest, soft golden light, tiny sparkles",
    }
    POSES = {
        "pose_0": "waving hello with one hand, cheerful smile",
        "pose_1": "cheering with both arms raised, joyful open-mouth smile",
        "pose_2": "thinking pose, one finger on chin, curious expression",
        "pose_3": "holding up a big golden coin in both hands, proud smile",
    }
    PERSONNAGE = (
        "1boy, solo, chibi, full body, front view, centered, "
        "original island adventurer, spiky chestnut hair, large brown eyes, "
        "jade green tunic, shell brooch, ochre shorts, simple sandals"
    )
    CINE = {
        "cine_1_mer": (
            "calm open sea at dusk, distant tiny island silhouette on the horizon, "
            "pink and orange clouds reflecting on gentle waves, no humans"
        ),
        "cine_2_barque": (
            "small chibi child seen from behind sitting in a tiny wooden boat, "
            "holding a glowing paper lantern, calm sea at dusk, warm lantern light "
            "reflecting on the water, pink clouds"
        ),
        "cine_3_ile": (
            "dreamy island in morning mist seen from far across the sea, "
            "soft green hills, tiny pavilion roofs, pale golden light, calm water"
        ),
        "cine_4_lanternes": (
            "glowing orange paper lanterns strung across a cozy island street at dusk, "
            "drifting pink cherry blossom petals, sharp focus, flat cel shading, "
            "no depth of field, no bokeh"
        ),
        "cine_5_titre": (
            "serene twilight sky, layered pink lavender and cream clouds above a calm sea, "
            "distant island silhouette with tiny warm lantern lights at the bottom edge, "
            "large calm empty sky area, no humans"
        ),
    }

    def _job(nom, type_, sujet, w=1024, h=1024, seed=None, i=0):
        return {
            "nom": nom,
            "type": type_,
            "sujet": sujet,
            "w": w,
            "h": h,
            "steps": 28,
            "cfg": 5.0,
            "seed": seed if seed is not None else 4187 + i * 137,
        }

    JOBS = []
    for i, (cle, sujet) in enumerate(BATIMENTS.items()):
        JOBS.append(_job(cle, "icone", sujet, i=i))
    for i, (cle, sujet) in enumerate(ACTIVITES.items()):
        JOBS.append(_job(cle, "icone", sujet, seed=9001 + i * 91, i=100 + i))
    for i, (cle, extra) in enumerate(POSES.items()):
        JOBS.append(_job(cle, "pose", "%s, %s" % (PERSONNAGE, extra), seed=7501 + i * 57, i=200 + i))
    JOBS.append(_job(
        "logo", "icone",
        "round emblem badge, cozy tropical island inside, sandy beach, jade palm groves, "
        "tiny wooden pavilion, glowing paper lanterns, small wooden boat, calm blue sea, "
        "warm sunset sky, thick dark-brown circular ring border, plain white background "
        "outside the ring", seed=3110, i=300,
    ))
    JOBS.append(_job(
        "icone_app", "icone",
        "mobile game app icon, cozy tropical island, tiny wooden pavilion, glowing paper "
        "lanterns, small boat on calm sea, warm sunset sky, bold simple shapes readable "
        "at small size", seed=3111, i=301,
    ))
    JOBS.append(_job(
        "banniere", "decor",
        "wide panorama, cozy tropical island at warm dusk, sandy coast, jade groves, "
        "small wooden pavilion, paper lanterns strung between trees, tiny wooden boat, "
        "calm reflective sea, pink and orange clouds, generous empty sky area on the left",
        w=1536, h=1024, seed=3112, i=302,
    ))
    for i, (cle, sujet) in enumerate(CINE.items()):
        JOBS.append(_job(cle, "decor", sujet, w=768, h=1344, seed=5500 + i * 73, i=400 + i))

    # Prompt complet par job (assemblé une fois, lu tel quel par la génération).
    for j in JOBS:
        j["prompt"] = "%s, %s, %s" % (j["sujet"], STYLES[j["type"]], QUALITE)

    return JOBS, NEGATIF


@app.cell
def _(mo):
    @mo.cache
    def charger_modele(model_id: str):
        import torch
        from diffusers import DiffusionPipeline, EulerAncestralDiscreteScheduler

        pipe = DiffusionPipeline.from_pretrained(
            model_id,
            torch_dtype=torch.float16,
            use_safetensors=True,
            add_watermarker=False,
        )
        pipe.scheduler = EulerAncestralDiscreteScheduler.from_config(pipe.scheduler.config)
        pipe.to("cuda")
        pipe.set_progress_bar_config(disable=True)
        return pipe

    return (charger_modele,)


@app.cell
def _(JOBS, mo):
    from pathlib import Path

    _rep = Path("generated_images")
    restants = [j for j in JOBS if not (_rep / ("%s.png" % j["nom"])).exists()]
    GO = mo.ui.run_button(
        label="Générer le lot restant (%d image%s)" % (len(restants), "s" if len(restants) > 1 else "")
    )
    mo.vstack([GO, mo.md("%d / %d images déjà générées dans cette session." % (len(JOBS) - len(restants), len(JOBS)))])
    return GO, restants


@app.cell
def _(GO, JOBS, NEGATIF, charger_modele, mo, restants, torch):
    import hashlib
    import io
    import json
    import zipfile
    from datetime import datetime, timezone
    from pathlib import Path

    mo.stop(
        not GO.value,
        mo.md("Choisis le GPU **RTX Pro 6000**, puis clique **Générer le lot restant**."),
    )
    if not torch.cuda.is_available():
        mo.stop(True, mo.callout(mo.md("Génération arrêtée : active le GPU Molab d'abord."), kind="warn"))

    rep = Path("generated_images")
    rep.mkdir(parents=True, exist_ok=True)
    taches = restants if restants else []
    if not taches:
        mo.output.append(mo.md("Tout le lot est déjà généré — récupère le ZIP ci-dessous."))
    else:
        mo.output.append(mo.md("Modèle en cours de chargement (2-3 min au premier lancement)…"))
    pipe = charger_modele("cagliostrolab/animagine-xl-4.0")

    manifeste = []
    for k, j in enumerate(taches):
        generateur = torch.Generator(device="cuda").manual_seed(int(j["seed"]))
        image = pipe(
            prompt=j["prompt"],
            negative_prompt=NEGATIF,
            width=int(j["w"]),
            height=int(j["h"]),
            num_inference_steps=int(j["steps"]),
            guidance_scale=float(j["cfg"]),
            generator=generateur,
        ).images[0]
        chemin = rep / ("%s.png" % j["nom"])
        image.save(chemin, format="PNG", optimize=True)
        octets = chemin.read_bytes()
        manifeste.append(
            {
                "nom": j["nom"],
                "type": j["type"],
                "prompt": j["prompt"],
                "negative_prompt": NEGATIF,
                "seed": int(j["seed"]),
                "steps": int(j["steps"]),
                "cfg": float(j["cfg"]),
                "w": int(j["w"]),
                "h": int(j["h"]),
                "sha256": hashlib.sha256(octets).hexdigest(),
                "licence": "CreativeML Open RAIL++-M — conserver la notice",
            }
        )
        mo.output.append(
            mo.md("**%d / %d** · `%s` · graine %d" % (k + 1, len(taches), j["nom"], j["seed"]))
        )
        mo.output.append(mo.image(src=chemin.resolve(), width=380, alt=j["nom"]))

    horodatage = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    paquet = io.BytesIO()
    with zipfile.ZipFile(paquet, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for j in JOBS:
            chemin = rep / ("%s.png" % j["nom"])
            if chemin.exists():
                archive.write(chemin, arcname=chemin.name)
        archive.writestr(
            "manifeste_lot_molab.json",
            json.dumps(
                {
                    "projet": "Ile de Reve",
                    "modele": "cagliostrolab/animagine-xl-4.0",
                    "genere_le": horodatage,
                    "images": manifeste,
                },
                ensure_ascii=False,
                indent=2,
            ),
        )
    mo.output.append(
        mo.download(
            data=paquet.getvalue(),
            filename="ile-de-reve-lot-molab-%s.zip" % horodatage,
            mimetype="application/zip",
            label="Télécharger le LOT COMPLET (ZIP PNG + manifeste)",
        )
    )
    return


if __name__ == "__main__":
    app.run()
