# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "marimo>=0.16",
#   "diffusers>=0.35,<1",
#   "transformers>=4.44,<5",
#   "accelerate>=0.34",
#   "safetensors>=0.4",
#   "pillow>=10",
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
        # Île de Rêve — atelier d’images IA

        Générateur d’illustrations pour le jeu Godot : icônes, personnages,
        décors d’île, textures et tableaux de cinématique. Le modèle ne se charge
        **qu’après le clic sur Générer**, pour laisser l’interface marimo démarrer.

        **Moteur :** `Lykon/dreamshaper-xl-v2-turbo` · Diffusers · GPU CUDA si disponible.
        La première génération télécharge les poids du modèle dans la session Molab.
        **Image générée :** aperçu dans le notebook et bouton de téléchargement PNG.

        Le modèle est déclaré `openrail++` sur Hugging Face. Conserve les restrictions
        de sa licence et audite chaque image avant une diffusion commerciale.
        """
    )
    return


@app.cell
def _(mo):
    import torch

    if torch.cuda.is_available():
        gpu_info = "**GPU actif :** %s — %.1f Go VRAM" % (
            torch.cuda.get_device_name(0),
            torch.cuda.get_device_properties(0).total_memory / 1e9,
        )
        mo.md(gpu_info)
    else:
        mo.callout(
            mo.md("Aucun GPU CUDA détecté. Dans Molab, active **RTX Pro 6000** via *Notebook settings* → *Compute* avant de générer."),
            kind="warn",
        )
    return (torch,)


@app.cell
def _(mo):
    PRESETS = {
        "Icône d’objet (carré)": (
            "one single game item, centered, isolated, fully visible, readable silhouette, "
            "retro 1980s hand-painted anime cel illustration, warm dark-brown ink outline, "
            "flat colors, one soft cel-shadow, cozy pastel palette, cream background, "
            "no lettering, no watermark, no border"
        ),
        "Personnage chibi (carré)": (
            "original small island villager character, full body, front three-quarter view, "
            "spiky chestnut hair, jade-green tunic, ochre shorts, tiny boots, friendly face, "
            "retro 1980s anime cel character design, warm brown ink outline, flat colors, "
            "one soft cel-shadow, cream background, no text, no watermark"
        ),
        "Décor d’île (portrait)": (
            "cozy tropical fantasy island seen from a high three-quarter top-down view, "
            "winding cream footpath, layered green groves, small pond, detailed sandy coast, "
            "blue calm sea, original retro 1980s anime background painting, warm evening light, "
            "clean shapes, no buildings with text, no interface, no watermark"
        ),
        "Cinématique (portrait)": (
            "a tiny wooden boat arriving at a peaceful island at dusk, glowing paper lanterns, "
            "soft pink clouds, warm reflections over calm water, original nostalgic 1980s "
            "Japanese cel-anime background painting, cinematic composition, no text, no logo"
        ),
        "Texture ou tuile (carré)": (
            "seamless repeating hand-painted game terrain texture, soft jade grass mixed with "
            "small warm cream flowers and subtle stones, top-down orthographic, evenly lit, "
            "retro 1980s cel-animation background style, no perspective, no text, no border"
        ),
        "Interface / panneau (carré)": (
            "ornate empty parchment-and-warm-wood mobile game interface panel, centered "
            "rectangular frame with large clean blank center, carved corner details, jade and "
            "ochre accents, retro 1980s anime game art, symmetrical, no text, no watermark"
        ),
    }
    PRESET = mo.ui.dropdown(
        options=list(PRESETS), value="Icône d’objet (carré)", label="Type d’image"
    )
    DESCRIPTION = mo.ui.text_area(
        value="a carved wooden birdhouse with tiny blossoms",
        label="Objet / détails à illustrer",
        rows=2,
    )
    FORME = mo.ui.dropdown(
        options=["Carré 768×768", "Carré 1024×1024", "Portrait 768×1344"],
        value="Carré 768×768",
        label="Format",
    )
    SEED = mo.ui.number(value=4187, label="Graine", step=1)
    STEPS = mo.ui.slider(4, 12, value=6, label="Étapes (DreamShaper Turbo)")
    GO = mo.ui.run_button(label="Générer une image")
    mo.vstack(
        [
            mo.hstack([PRESET, FORME], justify="start", gap=1),
            DESCRIPTION,
            mo.hstack([STEPS, SEED, GO], justify="start", gap=1),
        ],
        gap=1,
    )
    return DESCRIPTION, FORME, GO, PRESET, PRESETS, SEED, STEPS


@app.cell
def _(mo):
    @mo.cache
    def charger_modele(model_id: str):
        import torch
        from diffusers import AutoPipelineForText2Image, DPMSolverMultistepScheduler

        pipe = AutoPipelineForText2Image.from_pretrained(
            model_id,
            torch_dtype=torch.float16,
            use_safetensors=True,
        )
        pipe.scheduler = DPMSolverMultistepScheduler.from_config(pipe.scheduler.config)
        pipe.to("cuda")
        pipe.set_progress_bar_config(disable=True)
        return pipe

    return (charger_modele,)


@app.cell
def _(DESCRIPTION, FORME, GO, PRESET, PRESETS, SEED, STEPS, charger_modele, mo, torch):
    import io

    mo.stop(not GO.value, mo.md("Choisis un type d’image, ajoute ta description, puis clique **Générer une image**."))
    if not torch.cuda.is_available():
        mo.stop(True, mo.callout(mo.md("La génération est arrêtée : active le GPU dans les réglages Molab."), kind="warn"))

    largeur_hauteur = {
        "Carré 768×768": (768, 768),
        "Carré 1024×1024": (1024, 1024),
        "Portrait 768×1344": (768, 1344),
    }
    largeur, hauteur = largeur_hauteur[FORME.value]
    sujet = DESCRIPTION.value.strip() or "cozy island village"
    prompt = "%s, %s" % (sujet, PRESETS[PRESET.value])
    negatif = (
        "text, letters, watermark, signature, frame, cropped object, extra limbs, "
        "photorealistic, neon, watercolor wash, blurry, cluttered background"
    )
    pipe = charger_modele("Lykon/dreamshaper-xl-v2-turbo")
    generator = torch.Generator(device="cuda").manual_seed(int(SEED.value))
    result = pipe(
        prompt=prompt,
        negative_prompt=negatif,
        width=largeur,
        height=hauteur,
        num_inference_steps=int(STEPS.value),
        guidance_scale=2.0,
        generator=generator,
    ).images[0]
    result_bytes = io.BytesIO()
    result.save(result_bytes, format="PNG", optimize=True)
    mo.vstack(
        [
            mo.md("**Image générée** · %d×%d · graine %d" % (largeur, hauteur, int(SEED.value))),
            mo.image(result, width=420),
            mo.download(
                data=result_bytes.getvalue(),
                filename="ile-de-reve-%s.png" % int(SEED.value),
                label="Télécharger le PNG",
                mimetype="image/png",
            ),
        ]
    )
    return


if __name__ == "__main__":
    app.run()
