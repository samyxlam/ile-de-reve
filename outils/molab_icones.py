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
        # Atelier d'icônes — Île de Rêve (molab, GPU gratuit)

        Génère les **35 icônes d'objets** (5 chaînes × 6 niveaux + 5 générateurs) aux
        specs exactes de la direction artistique (`DIRECTION_ARTISTIQUE.md` §5.1) :
        style **cel-anime 1984-89, chibi cozy** (contours d'encre bruns, aplats plats,
        un seul ton d'ombre), fond crème `#f8f2e4`, cadrage centré avec 14 % de marge,
        256 px, JPEG q90.

        **Comment faire, sur molab** (https://molab.marimo.io) :

        1. téléverse ce fichier (`outils/molab_icones.py`) dans un nouveau notebook ;
        2. bouton *notebook specs* en haut → active le **GPU**. Sans GPU, une image
           prend plusieurs minutes et la stratégie molab recommande des lots courts ;
        3. lance les cellules dans l'ordre : diagnostic → modèle → réglages ;
        4. appuie sur **Générer le lot** (les fichiers déjà produits sont sautés, un
           deuxième appui ne refait que les manquants) ;
        5. regarde la **planche de contrôle** : chaque objet doit se lire à 90 px et
           se distinguer de son voisin de niveau ;
        6. si une icône %sp ère pas, mets son id dans « Régénérer » et appuie à
           nouveau — et change le prompt (§11.2), pas la graine ;
        7. télécharge **`objets.zip`** et décompresse-le dans `assets/objets/`.

        Règles molab (voir `lumo_tools/molab-strategy.md`) : lots de 15-20 max, pause
        entre lots, export immédiat — les fichiers ne survivent pas à la session.
        """
    )
    return


@app.cell
def _(mo):
    import torch

    if torch.cuda.is_available():
        mo.md(
            "**GPU :** %s — %.1f Go de VRAM."
            % (
                torch.cuda.get_device_name(0),
                torch.cuda.get_device_properties(0).total_memory / 1e9,
            )
        )
    else:
        mo.callout(
            mo.md(
                "Aucun GPU détecté. Sur molab : *notebook specs* → GPU avant de "
                "générer. Sans GPU, FLUX.1-schnell en CPU prend plusieurs minutes "
                "par image."
            ),
            kind="warn",
        )
    return (torch,)


@app.cell
def _(mo):
    """Réglages. Rien ne part sans le bouton **Générer le lot** : chaque appui ne
    génère que les icônes manquantes du lot choisi."""
    MODELE = mo.ui.dropdown(
        options=[
            "Lykon/dreamshaper-xl-v2-turbo",
            "black-forest-labs/FLUX.1-schnell",
            "Lykon/dreamshaper-xl-1-0",
        ],
        value="Lykon/dreamshaper-xl-v2-turbo",
        label="Modèle",
    )
    ETAPES = mo.ui.slider(2, 40, value=25, label="Étapes")
    GRAINE = mo.ui.number(0, 999999, value=11, label="Graine de base")
    LOT = mo.ui.dropdown(
        options=["tout", "bois", "ferme", "forge", "tissu", "ceramique", "generateurs"],
        value="tout",
        label="Lot",
    )
    REGEN = mo.ui.text(
        value="",
        label="Régénérer ces ids (remplace le lot)",
        placeholder="ex. : forge-5 ceramique-2 gen-tissu",
    )
    MARGE = mo.ui.slider(0.05, 0.30, value=0.14, label="Marge de cadrage")
    UNIFORME = mo.ui.checkbox(value=True, label="Fond crème exact #f8f2e4")
    DESAT = mo.ui.slider(0.75, 1.0, value=0.90, label="Désaturation")
    SESAM = mo.ui.run_button(label="Générer le lot")
    APP_BTN = mo.ui.run_button(label="Icône d'application 1024")
    mo.hstack(
        [mo.vstack([MODELE, ETAPES, GRAINE, LOT]),
         mo.vstack([REGEN, MARGE, UNIFORME, DESAT]),
         mo.vstack([SESAM, APP_BTN])],
        justify="start",
        gap=2,
    )
    return MODELE, ETAPES, GRAINE, LOT, REGEN, MARGE, UNIFORME, DESAT, SESAM, APP_BTN


@app.cell
def _(MODELE, torch):
    """Chargement du modèle. FLUX.1-schnell est **gated** chez Hugging Face
    (licence à accepter via un compte, impossible ici) : le défaut est donc
    `Lykon/dreamshaper-xl-v2-turbo`, libre, ~15-25 étapes. Si un modèle choisi
    venait à être gated, repli automatique sur DreamShaper."""

    # diffusers peut manquer sur l'image de base de molab : installation paresseuse.
    try:
        import diffusers  # noqa: F401
    except ImportError:
        import subprocess
        import sys

        subprocess.check_call(
            [sys.executable, "-m", "pip", "install", "-q",
             "diffusers", "transformers", "accelerate", "safetensors", "sentencepiece"]
        )

    from diffusers import AutoPipelineForText2Image, FluxPipeline
    import inspect

    dtype = torch.float16 if torch.cuda.is_available() else torch.float32

    def _charger(nom, flux):
        if flux:
            return FluxPipeline.from_pretrained(nom, torch_dtype=dtype)
        try:
            return AutoPipelineForText2Image.from_pretrained(
                nom, torch_dtype=dtype, variant="fp16", use_safetensors=True
            )
        except ValueError:
            return AutoPipelineForText2Image.from_pretrained(
                nom, torch_dtype=dtype, use_safetensors=True
            )

    est_flux = "flux" in MODELE.value.lower()
    modele_reel = MODELE.value
    try:
        pipe = _charger(MODELE.value, est_flux)
    except Exception as echec:  # gated 401, réseau, variante absente
        repli = "Lykon/dreamshaper-xl-v2-turbo"
        if MODELE.value.lower().startswith("lykon"):
            raise
        est_flux = False
        modele_reel = repli
        print("!! %s : %s — repli automatique sur %s" %
              (MODELE.value, echec.__class__.__name__, repli))
        pipe = _charger(repli, False)

    if torch.cuda.is_available():
        try:
            pipe.to("cuda")
        except Exception:
            pipe.enable_model_cpu_offload()
    pipe.set_progress_bar_config(disable=True)

    # FLUX refuse `negative_prompt` : on filtre sur les paramètres réellement acceptés.
    acceptes = set(inspect.signature(pipe.__call__).parameters)

    def generer_img(prompt, negatif, etapes, largeur, hauteur, graine):
        generateur = torch.Generator("cuda" if torch.cuda.is_available() else "cpu")
        generateur.manual_seed(graine)
        echelle = 0.0 if est_flux else (1.6 if etapes <= 10 else 6.0)
        demandes = {
            "prompt": prompt,
            "width": largeur,
            "height": hauteur,
            "num_inference_steps": etapes,
            "guidance_scale": echelle,
            "generator": generateur,
            "negative_prompt": negatif,
        }
        utile = {k: v for k, v in demandes.items() if k in acceptes}
        return pipe(**utile).images[0]

    return (est_flux, pipe, generer_img)


@app.cell
def _(mo):
    """Gabarit de prompt — le même d'une icône à l'autre, c'est ce qui garantit la
    cohérence de la série (DA §5.1). Copié d'`outils/agnes_icones.py` : une
    description floue coûte plus cher qu'une graine différente."""
    GABARIT = ("game item icon, one single object centered, {}, retro 1980s cel anime "
               "style, vintage hand-drawn cartoon, clean thick ink outlines in warm brown, "
               "flat cel shading with one soft shadow tone, chibi proportions, cozy warm "
               "color palette, cream paper background, gentle drop shadow, no text, no "
               "border, no frame")

    NEGATIF = ("text, letters, watermark, signature, frame, border, several objects, "
               "photo-realistic, neon colors, watercolor wash, paper texture, pencil "
               "sketch, blurred, cluttered")

    # id -> description anglaise, telle quelle d'`agnes_icones.py`.
    OBJETS = [
        ("bois-1", "a small weathered piece of driftwood, pale grey wood"),
        ("bois-2", "a neat stack of smooth planed wooden planks"),
        ("bois-3", "a thick carved wooden beam with ornamental notches and joints, sturdy construction timber"),
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
        ("forge-6", "a polished curved bronze ceremonial sword with an ornate golden hilt"),
        ("tissu-1", "a spool of fine silk thread"),
        ("tissu-2", "a red chinese lucky knot with tassels"),
        ("tissu-3", "a ball of colorful yarn"),
        ("tissu-4", "a folded warm wool winter cloth"),
        ("tissu-5", "a folded embroidered festival robe"),
        ("tissu-6", "a tall embroidered festival banner in red and gold on a wooden pole"),
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
    mo.md(
        "**%d icônes** au gabarit : 5 chaînes de 6 niveaux + 5 générateurs."
        % len(OBJETS)
    )
    return GABARIT, NEGATIF, OBJETS


@app.cell
def _():
    """Dossiers de travail + imports partagés. Une session molab ne conserve rien :
    on télécharge à la fin (stratégie « toujours exporter en temps réel »).
    marimo exige qu'un nom soit défini dans une seule cellule — Path, os, PIL & cie
    vivent donc ici et sont redistribués aux cellules aval via leur signature."""
    from pathlib import Path
    import os
    import io
    import csv
    import datetime
    import zipfile
    import time
    from PIL import Image, ImageChops, ImageEnhance, ImageDraw

    SORTIE = Path("molab_sortie")
    BRUTES = SORTIE / "brutes"       # PNG 1024, tels que le modèle les produit
    TRAITEES = SORTIE / "traitees"   # JPEG 256 cadrés, fond crème — la livraison
    return (
        BRUTES, TRAITEES, SORTIE, Path, os, io, csv, datetime, zipfile,
        time, Image, ImageChops, ImageEnhance, ImageDraw,
    )


@app.cell
def _(
    BRUTES, ETAPES, GABARIT, GRAINE, LOT, NEGATIF, OBJETS, REGEN, SESAM,
    generer_img, mo, torch,
):
    """Génération du lot. Sauvegarde immédiate de chaque PNG (les fichiers ne
    survivent pas à la session), 0,8 s entre images, et les manquants seulement.
    Corps enroulé dans une fonction : marimo interdit de définir un même nom
    dans deux cellules, l'enroulage isole les temporaires."""
    def _fabriquer():
        from pathlib import Path
        import time

        PREFIXES = {
            "bois": "bois-",
            "ferme": "ferme-",
            "forge": "forge-",
            "tissu": "tissu-",
            "ceramique": "ceramique-",
            "generateurs": "gen-",
        }

        mo.stop(not SESAM.value, mo.md("Réglages en haut → bouton **Générer le lot**."))
        BRUTES.mkdir(parents=True, exist_ok=True)

        descriptions = {k: d for k, d in OBJETS}
        regen = [
            s.strip()
            for s in (REGEN.value or "").replace(",", " ").split()
            if s.strip()
        ]
        regen = [r for r in regen if r in descriptions]
        if regen:
            cibles = regen
            note = "régénération ciblée : " + ", ".join(regen)
        elif LOT.value in PREFIXES:
            prefixe = PREFIXES[LOT.value]
            cibles = [k for k, _ in OBJETS if k.startswith(prefixe)]
            note = "chaîne « %s »" % LOT.value
        else:
            cibles = [k for k, _ in OBJETS]
            note = "tous les objets"

        faits = 0
        for i, cle in enumerate(cibles):
            dest = Path(BRUTES) / (cle + ".png")
            if dest.exists() and dest.stat().st_size > 8000 and not regen:
                continue
            print("%d/%d  %s" % (i + 1, len(cibles), cle))
            for essai in range(2):
                try:
                    image = generer_img(
                        GABARIT.format(descriptions[cle]),
                        NEGATIF,
                        int(ETAPES.value),
                        1024,
                        1024,
                        int(GRAINE.value) + i * 11,
                    )
                    image.save(dest)
                    faits += 1
                    time.sleep(0.8)
                    break
                except RuntimeError as echec:
                    if "out of memory" in str(echec).lower():
                        torch.cuda.empty_cache()
                        print("  VRAM pleine — réduit ETAPES ou passe à DreamShaper")
                    else:
                        print("  ..  %s essai %d : %s" % (cle, essai + 1, str(echec)[:90]))
                    time.sleep(3)
        return faits, len(cibles), note

    faits_g, total_g, note_g = _fabriquer()
    mo.md("**%d/%d générées** — %s." % (faits_g, total_g, note_g))
    return


@app.cell
def _(BRUTES, DESAT, MARGE, OBJETS, TRAITEES, UNIFORME, mo):
    """Post-traitement — l'équivalent d'`outils/recadrer_icones.py`, adapté au
    lot FLUX : détection de l'objet par différence avec le fond du coin, carré
    centré avec marge, fond crème exact, désaturation douce, 256 px.
    Corps enroulé pour isoler les temporaires (règle marimo)."""
    def _traiter():
        from PIL import Image, ImageChops, ImageEnhance

        PX, SEUIL, TOL = 256, 16, 12
        CREME = (248, 242, 228)   # #f8f2e4 — celui de la DA §5.1

        TRAITEES.mkdir(parents=True, exist_ok=True)

        n = 0
        for cle, _description in OBJETS:
            source = BRUTES / (cle + ".png")
            if not source.exists():
                continue
            im = Image.open(source).convert("RGB")

            fond = im.getpixel((2, 2))
            diff = ImageChops.difference(
                im, Image.new("RGB", im.size, fond)
            ).convert("L")
            boite = diff.point(lambda v: 255 if v > SEUIL else 0).getbbox()
            if boite is None:
                print("  ??  %s : fond uniforme" % cle)
                continue
            x0, y0, x1, y1 = boite
            cote = int(max(x1 - x0, y1 - y0) * (1 + 2 * float(MARGE.value)))
            cx, cy = (x0 + x1) // 2, (y0 + y1) // 2
            gauche, haut = cx - cote // 2, cy - cote // 2
            carre = Image.new("RGB", (cote, cote), fond)
            carre.paste(
                im.crop(
                    (max(0, gauche), max(0, haut),
                     min(im.width, gauche + cote),
                     min(im.height, haut + cote))
                ),
                (max(0, -gauche), max(0, -haut)),
            )
            icone = carre.resize((PX, PX), Image.LANCZOS)

            if UNIFORME.value:
                masque = ImageChops.difference(
                    icone, Image.new("RGB", icone.size, fond)
                ).convert("L")
                masque = masque.point(lambda v: 255 if v <= TOL else 0)
                icone.paste(Image.new("RGB", icone.size, CREME), (0, 0), masque)

            if float(DESAT.value) < 1.0:
                icone = ImageEnhance.Color(icone).enhance(float(DESAT.value))

            icone.save(TRAITEES / (cle + ".jpg"), quality=90)
            n += 1
        return n

    n_t = _traiter()
    mo.md("**%d icônes traitées** → `molab_sortie/traitees/` (256 px, JPEG q90)." % n_t)
    return


@app.cell
def _(OBJETS, TRAITEES, mo):
    """Planche de contrôle — la grille QA de la DA (§5.1 et §11.3) : vérifier le
    style, le cadrage, la progression de chaque ligne, et « l'objet se lit à 90 px,
    sans texte parasite, sans dégradé de fond »."""
    def _composer():
        from PIL import Image, ImageDraw

        TUILE, LEGENDE, COLS = 190, 26, 6

        presents = [
            cle for cle, _ in OBJETS
            if (TRAITEES / (cle + ".jpg")).exists()
        ]
        lignes = max(1, -(-len(presents) // COLS))
        planche = Image.new(
            "RGB",
            (COLS * TUILE, lignes * (TUILE + LEGENDE)),
            (248, 242, 228),
        )
        d = ImageDraw.Draw(planche)
        for idx, cle in enumerate(presents):
            x = (idx % COLS) * TUILE
            y = (idx // COLS) * (TUILE + LEGENDE)
            ic = Image.open(TRAITEES / (cle + ".jpg")).resize(
                (TUILE, TUILE), Image.LANCZOS
            )
            planche.paste(ic, (x, y))
            d.text((x + 5, y + TUILE + 6), cle, fill=(74, 58, 40))

        options = presents if presents else ["(aucune icône traitée)"]
        return planche, options, mo.ui.dropdown(options=options, label="Icône à examiner à 90 px")

    PLANCHA_IMAGE, _options, SELECTION = _composer()
    return (PLANCHA_IMAGE, SELECTION)


@app.cell
def _(PLANCHA_IMAGE, SELECTION, TRAITEES, mo):
    """Zoom de contrôle : l'icône choisie, à la vraie taille d'une case du plateau."""
    def _afficher():
        from PIL import Image

        ok = SELECTION.value and not SELECTION.value.startswith("(")
        if ok:
            ic = Image.open(TRAITEES / (SELECTION.value + ".jpg")).resize((90, 90), Image.LANCZOS)
            return mo.vstack([
                mo.md("`%s` à la taille réelle d'une case (90 px) :" % SELECTION.value),
                mo.hstack([mo.image(ic, width=90), mo.image(PLANCHA_IMAGE, width=760)]),
            ])
        return mo.image(PLANCHA_IMAGE, width=760)

    _afficher()
    return


@app.cell
def _(ETAPES, MODELE, OBJETS, TRAITEES, mo):
    """Manifest — le livre de génération (fichier, chaîne, modèle, étapes, date, statut)."""
    def _ecrire():
        import csv
        import io
        import datetime

        bande = io.StringIO()
        scribe = csv.writer(bande)
        scribe.writerow(["fichier", "chaine", "modele", "etapes", "date", "statut"])
        for cle, _d in OBJETS:
            dest = TRAITEES / (cle + ".jpg")
            scribe.writerow([
                cle + ".jpg",
                "generateur" if cle.startswith("gen-") else cle.split("-")[0],
                str(MODELE.value),
                int(ETAPES.value),
                datetime.date.today().isoformat(),
                "genere" if dest.exists() else "absent cette session",
            ])
        return bande.getvalue().encode("utf-8")

    MANIFEST = _ecrire()
    return (MANIFEST,)


@app.cell
def _(MANIFEST, PLANCHA_IMAGE, TRAITEES, mo):
    """Download final — `objets.zip` (la livraison pour `assets/objets/`), la planche
    de contrôle et le manifest."""
    def _paqueter():
        import io
        import os
        import zipfile

        n = len([f for f in os.listdir(TRAITEES) if f.endswith(".jpg")])
        zip_data = io.BytesIO()
        with zipfile.ZipFile(zip_data, "w", zipfile.ZIP_DEFLATED) as z:
            for f in sorted(os.listdir(TRAITEES)):
                if f.endswith(".jpg"):
                    z.writestr(f, open(TRAITEES / f, "rb").read())
            if PLANCHA_IMAGE is not None:
                planche_data = io.BytesIO()
                PLANCHA_IMAGE.save(planche_data, format="PNG")
                z.writestr("planche_controle.png", planche_data.getvalue())
            z.writestr("manifest.csv", MANIFEST)
        return n, zip_data.getvalue()

    n_dl, zip_dl = _paqueter()
    mo.vstack([
        mo.md(
            "**%d icônes** prêtes. Décompresse dans `E:\\mergecontinu\\assets\\objets\\`, "
            "puis passe la checklist QA (DA §11.3)." % n_dl
        ),
        mo.download(
            data=zip_dl,
            filename="objets.zip",
            label="Télécharger objets.zip (icônes + planche + manifest)",
            mimetype="application/zip",
        ),
    ])
    return


@app.cell
def _(APP_BTN, ETAPES, GRAINE, SORTIE, generer_img, mo):
    """Bonus — icône d'application 1024×1024 pour la fiche store (DA §12.3) :
    l'île rêvée, seule, centrée."""
    def _icone_app():
        if not APP_BTN.value:
            return mo.md("Bonus (bouton dédié) : icône d'application 1024 px du §12.3.")
        SORTIE.mkdir(parents=True, exist_ok=True)
        PROMPT = (
            "isometric cozy illustration of a tiny island with a small "
            "pagoda, cherry trees and glowing paper lanterns, pastel palette, warm "
            "dusk sky, dreamy storybook mood, game application icon, single centered "
            "composition, clean soft edges, no text, no border, no watermark"
        )
        image = None
        for essai in range(2):
            try:
                image = generer_img(
                    PROMPT, "", int(ETAPES.value), 1024, 1024, 700 + int(GRAINE.value)
                )
                break
            except Exception as echec:
                print("  ..  essai %d : %s" % (essai + 1, str(echec)[:90]))
        if image is None:
            return mo.callout(mo.md("Icône d'application : génération échouée, réessaie."), kind="warn")
        dest = SORTIE / "icon_store_1024.png"
        image.save(dest)
        return mo.vstack([
            mo.image(image, width=300),
            mo.download(
                data=open(dest, "rb").read(),
                filename="icon_store_1024.png",
                label="Télécharger icon_store_1024.png",
                mimetype="image/png",
            ),
        ])

    _icone_app()
    return


if __name__ == "__main__":
    app.run()
