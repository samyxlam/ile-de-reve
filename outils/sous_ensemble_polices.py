# -*- coding: utf-8 -*-
"""Sous-ensemble les polices du jeu pour alléger le build (40 Mo → ~6-8 Mo).

Les polices complètes restent dans fonts/source/ (avec .gdignore : jamais
exportées) ; le jeu charge les sous-ensembles via ui_kit.gd.

- CJK  : tous les caractères réellement présents dans les chaînes des
         scripts .gd + ASCII + latin étendu + ponctuations CJK/fullwidth.
- Emoji: uniquement les emoji dont le glyphe existe dans NotoColorEmoji
         (les caractères BMP comme ✔ ou ← viennent de la police CJK).

Régénérer : python outils/sous_ensemble_polices.py
"""
import re
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont

RACINE = Path(__file__).resolve().parent.parent
FONTS = RACINE / "fonts"
SOURCE = FONTS / "source"

def caracteres_utilises() -> set:
    """Extrait tous les caractères des littéraux de chaîne des scripts .gd."""
    sorties = set()
    motif = re.compile(r'"([^"\\\n]*)"|\'([^\'\\\n]*)\'')
    for gd in (RACINE / "scripts").glob("*.gd"):
        texte = gd.read_text(encoding="utf-8", errors="ignore")
        for groupe in motif.findall(texte):
            sorties.update(groupe[0] or groupe[1])
    # Garanties de lisibilité, indépendantes du contenu actuel des scripts.
    sorties.update(chr(c) for c in range(0x20, 0x7F))          # ASCII imprimable
    sorties.update(chr(c) for c in range(0x00A0, 0x0180))      # latin étendu (é è ï î …)
    sorties.update(chr(c) for c in range(0x2000, 0x2070))      # tirets, guillemets, …
    sorties.update(chr(c) for c in range(0x3000, 0x3040))      # ponctuation CJK
    sorties.update(chr(c) for c in range(0xFF01, 0xFFF0))      # formes pleine largeur
    return sorties


def couverture(chemin: Path, demandes: set) -> tuple:
    """Renvoie (cmap du fichier, caractères demandés absents de la police)."""
    fonte = TTFont(str(chemin), lazy=True)
    cmap = set()
    for table in fonte["cmap"].tables:
        if table.isUnicode():
            cmap.update(table.cmap.keys())
    fonte.close()
    demandes_cp = {ord(c) for c in demandes}
    return cmap, {c for c in demandes if ord(c) not in cmap}


def sous_ensemble(chemin: Path, sortie: Path, garder: set) -> None:
    options = subset.Options()
    options.layout_features = ["*"]
    options.name_IDs = ["*"]
    options.notdef_outline = True
    options.recalc_bounds = True
    ss = subset.Subsetter(options)
    ss.populate(unicodes=[ord(c) for c in garder])
    fonte = subset.load_font(str(chemin), options)
    ss.subset(fonte)
    fonte.save(str(sortie))
    fonte.close()  # laisser Windows débloquer le fichier pour le déplacement


def main() -> None:
    tout = caracteres_utilises()
    SOURCE.mkdir(exist_ok=True)

    def original(nom: str) -> Path:
        """L'original peut être à la racine de fonts/ (première passe) ou déjà
        déplacé dans fonts/source/ (régénérations suivantes)."""
        racine = FONTS / nom
        return racine if racine.exists() else SOURCE / nom

    # ------------------------------------------------- police CJK
    cjk_src = original("NotoSansCJKsc-Regular.otf")
    cjk_cmap, manquants = couverture(cjk_src, tout)
    garder = {c for c in tout if ord(c) in cjk_cmap}
    sortie_cjk = FONTS / "cjk-sous-ensemble.otf"
    sous_ensemble(cjk_src, sortie_cjk, garder)
    if manquants:
        print("AVERTISSEMENT — glyphes absents de la police CJK :",
              " ".join(sorted(manquants))[:400])

    # ------------------------------------------------- police emoji
    emoji_src = original("NotoColorEmoji.ttf")
    emoji_cmap, emoji_manquants = couverture(emoji_src, tout)
    garder_emoji = {c for c in tout if ord(c) in emoji_cmap}
    # Sélecteur de variation : collé aux emoji, présent dans la police.
    garder_emoji.add(chr(0xFE0F))
    sortie_emoji = FONTS / "emoji-sous-ensemble.ttf"
    sous_ensemble(emoji_src, sortie_emoji, garder_emoji)

    # ------------------------------------------------- origines hors export
    deplacements = {
        cjk_src: SOURCE / cjk_src.name,
        emoji_src: SOURCE / emoji_src.name,
    }
    for src, dest in deplacements.items():
        if src.exists():
            src.replace(dest)
    import_files = list(FONTS.glob("*.import"))
    for imp in import_files:
        imp.unlink()
    (SOURCE / ".gdignore").write_text("", encoding="utf-8")

    print("CJK     : %d glyphes gardés → %s (%.1f Ko)" % (
        len(garder), sortie_cjk.name, sortie_cjk.stat().st_size / 1024))
    print("Emoji   : %d glyphes gardés → %s (%.1f Ko)" % (
        len(garder_emoji), sortie_emoji.name, sortie_emoji.stat().st_size / 1024))
    if emoji_manquants:
        print("emoji sans glyphe (rendus par la police CJK ou ignorés) :",
              " ".join(sorted(emoji_manquants))[:300])


if __name__ == "__main__":
    main()
