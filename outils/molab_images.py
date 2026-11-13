import marimo

__generated_with = "0.25.2"
app = marimo.App(width="medium")


@app.cell
def _(mo):
    mo.md(
        """
        # Générateur d'images — Île de Rêve

        **Avant de lancer :** bouton *notebook specs* en haut → active le **GPU**.
        Sans GPU, la génération prendra plusieurs minutes par image.

        Ce notebook produit les 5 tableaux de la cinématique en 720×1280, style visé
        **cel-anime rétro 1984-89 / chibi cozy**. À la fin,
        un bouton télécharge un `cine.zip` :
        décompresse-le dans `assets/cine/` du projet.

        Modèle : `Lykon/dreamshaper-xl-v2-turbo` (SDXL turbo, non soumis à licence,
        6 étapes). Si le téléchargement échoue, passe à `Lykon/dreamshaper-xl-1-0`
        et monte `ETAPES` à 30.
        """
    )
    return


@app.cell
def _(mo):
    MODELE = mo.ui.dropdown(
        options=["Lykon/dreamshaper-xl-v2-turbo", "Lykon/dreamshaper-xl-1-0"],
        value="Lykon/dreamshaper-xl-v2-turbo",
        label="Modèle",
    )
    ETAPES = mo.ui.slider(4, 40, value=6, label="Étapes")
    GRAINE = mo.ui.number(0, 999999, value=11, label="Graine de base")
    mo.hstack([MODELE, ETAPES, GRAINE], justify="start", gap=1)
    return ETAPES, GRAINE, MODELE


@app.cell
def _(mo):
    import torch

    if torch.cuda.is_available():
        infos = "**GPU :** %s — %.1f Go" % (
            torch.cuda.get_device_name(0),
            torch.cuda.get_device_properties(0).total_memory / 1e9,
        )
        mo.md(infos)
    else:
        mo.callout(
            mo.md("Aucun GPU détecté. Active-le via *notebook specs* avant de lancer la génération."),
            kind="warn",
        )
    return (torch,)


@app.cell
def _(MODELE, torch):
    from diffusers import AutoPipelineForText2Image

    pipe = AutoPipelineForText2Image.from_pretrained(
        MODELE.value,
        torch_dtype=torch.float16,
        variant="fp16",
        use_safetensors=True,
    )
    if torch.cuda.is_available():
        pipe.to("cuda")
    pipe.set_progress_bar_config(disable=True)
    return (pipe,)


@app.cell
def _(mo):
    STYLE = (
        "retro 1980s anime background art, hand-painted cel animation style, warm "
        "nostalgic evening light, soft pastel sky, clean defined shapes, cozy "
        "heartwarming mood, subtle film grain, no text"
    )

    TABLEAUX = [
        (
            "cine_1_mer.png",
            "calm sea at dusk, pastel sunset sky with soft stars, distant dark island "
            "silhouette on the horizon, shimmering reflections on the water, empty scene, "
            "wide shot, " + STYLE,
        ),
        (
            "cine_2_barque.png",
            "a small chibi child with spiky dark hair seen from behind, sitting in a little "
            "wooden boat on a calm pastel sea at sunset, a glowing paper lantern on the bow, "
            "big head and tiny body, cozy adventure mood, " + STYLE,
        ),
        (
            "cine_3_ile.png",
            "a small cozy island at dawn seen from the sea, a little pagoda on a green hill, "
            "cherry trees, paper lanterns glowing along the shore, a tiny boat approaching "
            "in the foreground, clean cel colors, dreamy, " + STYLE,
        ),
        (
            "cine_4_lanternes.png",
            "close view of glowing paper lanterns hanging from a cherry blossom branch at "
            "dusk, pink petals falling, warm bokeh, dark cozy background, " + STYLE,
        ),
        (
            "cine_5_titre.png",
            "dreamy dusk sky over a dark island silhouette, glowing paper lanterns scattered "
            "at the bottom, large empty soft area in the middle for a title, calm and "
            "inviting, " + STYLE,
        ),
    ]
    mo.md("**%d tableaux** en file d'attente." % len(TABLEAUX))
    return TABLEAUX, STYLE


@app.cell
def _(ETAPES, GRAINE, TABLEAUX, pipe, torch):
    from PIL import Image

    # 768×1344 : multiples de 64, ce que SDXL préfère. On redimensionne ensuite en 720×1280.
    images = {}
    for i, (nom, prompt) in enumerate(TABLEAUX):
        generateur = torch.Generator("cuda" if torch.cuda.is_available() else "cpu")
        generateur.manual_seed(int(GRAINE.value) + i * 11)
        img = pipe(
            prompt=prompt,
            num_inference_steps=int(ETAPES.value),
            guidance_scale=1.6 if ETAPES.value <= 8 else 6.0,
            width=768,
            height=1344,
            generator=generateur,
        ).images[0]
        images[nom] = img.resize((720, 1280), Image.LANCZOS)
        print("généré :", nom)
    return (images,)


@app.cell
def _(images, mo):
    import io
    import zipfile

    if not images:
        mo.md("Rien à afficher.")
    else:
        mo.vstack([mo.image(img, width=260) for img in images.values()])

        tampon = io.BytesIO()
        with zipfile.ZipFile(tampon, "w", zipfile.ZIP_DEFLATED) as z:
            for nom, img in images.items():
                b = io.BytesIO()
                img.save(b, format="PNG")
                z.writestr(nom, b.getvalue())
        mo.download(
            data=tampon.getvalue(),
            filename="cine.zip",
            label="Télécharger cine.zip (5 tableaux)",
            mimetype="application/zip",
        )
    return


if __name__ == "__main__":
    app.run()
