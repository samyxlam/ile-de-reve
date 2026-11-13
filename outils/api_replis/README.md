# Archive — anciennes voies de génération par API

> Placé en réserve le 6 novembre 2026. Ces scripts ne font plus partie du
> pipeline : toute génération passe désormais par les notebooks molab
> (`outils/molab_icones.py`, `outils/molab_images.py`), qui portent eux-mêmes
> le gabarit de prompt cel-anime retenu dans `DIRECTION_ARTISTIQUE.md`.

| Script | Ancienne voie | Pourquoi archivé |
|---|---|---|
| `agnes_icones.py` | API Agnes (`agnes-image-2.0-flash`) | remplacé par `molab_icones.py` (un seul prompt-source, pas de compte d'API) |
| `agnes_images.py` | API Agnes (`agnes-image-2.1-flash`) | remplacé par `molab_images.py` |
| `completer_cine.py` | API Pollinations (sans clé) | service instable, style non contrôlé — les tableaux se refont dans `molab_images.py` |
| `generer_images.py` | FLUX CPU local (diffusers) | plusieurs minutes par image sans GPU ; le même pipeline tourne en GPU sur molab |

**Faire une régénération aujourd'hui** : suivre `outils/SESSION_MOLAB.md`
(notebook + GPU molab + post-traitement local `harmoniser_fonds.py` /
`controle_icones.py`).

Ne supprime pas ces fichiers : le gabarit historique d'`agnes_icones.py` a
servi de référence aux prompts du notebook, et ils restent un point de comparaison.
