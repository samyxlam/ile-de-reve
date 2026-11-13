# Île de Rêve — prototype Godot 4 (merge-2 inspiré de 去有梦的小岛)

> **Documentation complète** : [`PROJET.md`](PROJET.md) (état, architecture, économie,
> reste à faire) et [`DIRECTION_ARTISTIQUE.md`](DIRECTION_ARTISTIQUE.md) (palette, assets,
> animations, cinématique, exigences commerciales). Ce README est le guide de démarrage.

Prototype **jouable** inspiré du mini-jeu WeChat 去有梦的小岛 (« l'île aux rêves », édité
par 重庆聚购科技 et exploité par 深圳山海创量, approuvé le 19/11/2024, ISBN 978-7-498-14240-5).
Ce projet recrée **le cœur du jeu et quasiment tous ses événements systèmes**, entièrement en Godot 4.7,
**sans aucune asset externe** : tout l'art est généré au runtime (formes + emojis + badge de niveau),
tous les objets ont un nom, un niveau et un lore trilingues.

> **Important** : aucun sprite, son ou texte du jeu original n'est copié ici. C'est une réinterprétation
> libre des mécaniques observées dans les captures d'écran + guides publics, pour apprendre le genre.

---

## 1. Lancer le jeu

### A — Dans le navigateur (chemin principal, aucun GPU requis)
Double-clique **`JOUER.bat`** : il démarre un serveur local et ouvre le jeu dans le navigateur.
La fenêtre noire qui reste ouverte est le serveur — la fermer arrête le jeu.

Équivalent manuel :
```
python tools/jouer.py
```
ou, sans le script :
```
python -m http.server 8000
```
puis `http://localhost:8000/build/web/index.html`.

> Ouvrir `build/web/index.html` par double-clic **ne fonctionne pas** : le moteur doit récupérer
> `index.wasm` et `index.pck` par HTTP, ce que `file://` interdit.

Le rendu passe par **SwiftShader** (WebGL en logiciel) : aucun pilote graphique nécessaire.

Après une modification du code, réexporter :
```
godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-release "Web" build/web/index.html
```
Les templates d'export sont déjà installés (`%APPDATA%\Godot\export_templates\4.7.2.stable`).

Paramètres d'URL utiles : `?ecran=ile|fouille|boutique|passe|classe|cadeau` et `?nocadeau=1`.

### B — Sur le PC (nécessite une carte graphique)
`LANCER.bat` lance la version native via Mesa (rendu CPU), mais l'ouverture d'une fenêtre
OpenGL échoue sur certaines machines sans GPU. Le navigateur reste la voie fiable.

### C — Interface
- La langue se change avec le bouton **FR/EN/ZH** en haut à droite (ou dans la boutique ⚙).
- Navigation par la barre du bas : **Plateau / Île / Fouille**.

---

## 2. Ce qui est implémenté (couverture des captures)

| Système du jeu source (captures) | Ici |
|---|---|
| Barre de monnaies fixée en haut (⚡体力 / 🪙铜钱 / 🍃树叶) + niveau | ✓ |
| Plateau de fusion **7×10** (70 cases), damier clair | ✓ glisser-déposer, échange, fusion animée |
| **Générateurs posés sur le plateau** : 5 producteurs, 5 charges puis 45 s de recharge | ✓ production sur la case libre la plus proche |
| **3 commandes de lapins EN HAUT**, récompense + **minuteur de 45 min** | ✓ bouton ✔ "Livrer tout" |
| **Caisses verrouillées** en bois sur les deux rangées du bas, prix croissant | ✓ 10 cases, 60 → 900 🪙 |
| Barre du bas : coffre 🎁 / fiche objet / boutique 🛒 | ✓ |
| Tâches quotidiennes (6h / quotidien) | ✓ 4 tâches, points d'événement |
| Événement **月神节** : pass **vertical 2 colonnes** (gratuit / VIP ¥30 / 豪华 ¥45 simulés) | ✓ 10 paliers, réclamation en place |
| Événement **筑景名录** : classement par saison, onglets fonctionnels | ✓ bots + position du joueur |
| **彩色寻物** : 3 niveaux à déblocage séquentiel | ✓ 8 objets à retrouver, cooldown, **+25/40/60 ⚡** |
| **Roue de la fortune** : source d'énergie gratuite | ✓ 8 secteurs pondérés, 1 tour / 30 min |
| **Vue île** : **carte peinte** (mer, sable, rivière, bosquets), 30 parcelles décalées | ✓ déblocage progressif par prospérité |
| **Butin par bâtiment** : chaque bâtiment accumule ses pièces et affiche une bulle | ✓ on le touche pour ramasser |
| **6 activités sur la carte** (寻物 / 天赐好礼 / 月神节 / 筑景名录 / roue / cadeaux) | ✓ un clic depuis la parcelle |
| Revenu passif de l'île (prospérité ÷ 6 🪙/min par bâtiment, cumul 8 h) | ✓ bouton « Récolter tout » |
| Coffre 🎁 (60 🪙 → 3 objets aléatoires) | ✓ |
| Boutique ⚙ (énergie vs 🍃, packs simulés, VIP simulé, langue, reset, dex) | ✓ |
| Fiche objet en bas + **vendre** | ✓ nom, niveau, lore, prix |
| Cadeau quotidien | ✓ modal au démarrage |
| Régénération d'énergie hors ligne | ✓ calcul du delta à la sauvegarde |

Raccourcis internes (stockés dans `Data.PASS_PALIERS` 10 paliers, événement 14 jours).

### Économie de l'énergie
Comme dans le jeu de référence, l'énergie ne s'achète pas seulement : deux activités
gratuites la rechargent.

| Source | Gain | Rythme |
|---|---|---|
| Régénération passive | +1 | 60 s |
| Cadeau quotidien | +20 | 1 / jour |
| **Roue de la fortune** | +10 à +60 | 1 tour / 30 min |
| **彩色寻物** (niveau 1 / 2 / 3) | +25 / +40 / +60 | cooldown 60-120 s |

Réglages : `State.REGEN_ENERGIE`, `State.ROUE_ATTENTE`, `Data.ROUE` (poids des secteurs),
`Data.FOUILLES` (champ `energie`). La roue se dessine dans `scripts/roue.gd` ; ses
libellés sont contre-tournés pour rester lisibles à l'arrêt.

### L'île, comme dans le jeu de référence
La carte du jeu original est une **peinture vue de dessus** entourée d'activités minutées,
pas une grille. Reproduit ici :

- **Terrain dessiné** (`class Terrain`) : mer, anneau de sable, île, sentier sinueux,
  bosquets dans les marges, étang. Les parcelles se posent par-dessus à coordonnées fixes.
- **Parcelles décalées** : les rangées impaires sont décalées d'une demi-colonne et chaque
  parcelle est légèrement tournée — c'est ce qui casse l'effet « grille ».
- **Butin par bâtiment** : chaque bâtiment construit accumule `prospérité ÷ 6` pièces par
  minute et affiche une bulle `🪙 +N`. On le touche pour ramasser ; le bouton d'en-tête
  ramasse tout. C'est le principe des boutons ronds minutés autour de la carte.
- **Six activités** occupent des parcelles : 彩色寻物, 天赐好礼 (+50 ⚡ / +200 🪙 toutes
  les 3 h), 月神节, 筑景名录, roue de la fortune, cadeaux.

Réglages : `Data.MAP_ACTIVITES` (cellules réservées), `island.gd::_positions()` (placement),
`State.ROUE_ATTENTE`, `State.DON_ATTENTE`, `State.ILE_CAP_HEURES` (plafond de cumul).

## 3. Architecture du code

```
project.godot            # Godot 4.7, portrait 720×1280, GL Compatibility
scenes/main.tscn         # entrée unique
scripts/
  data.gd                # [autoload Data]  chaînes d'objets, générateurs, zones, tâches, fouilles, i18n
  state.gd               # [autoload State] économie, plateau, générateurs, commandes, sauvegarde JSON
  ui_kit.gd              # thème bois/parchemin, polices, modales, toasts, icônes, contenu_bouton()
  main.gd                # barre de monnaies, événements, navigation, cadeau, deep-links
  board.gd               # plateau 7×10 : commandes, générateurs, fusions, caisses, coffre
  island.gd              # île : carte 5×6, parcelles verrouillées/débloquées, chantiers, mini-jeux
  hidden_game.gd         # fouille : niveaux à déblocage séquentiel + scène générée
  event_pass.gd          # 月神节 : pass vertical 2 colonnes + tâches
  rank_board.gd          # 筑景名录 : classement par zone (onglets actifs)
  shop_ui.gd             # boutique + paramètres + 图鉴
tools/
  jouer.py               # serveur local + ouverture du navigateur (appelé par JOUER.bat)
  capture.sh             # capture un écran du build web (serveur + Chrome logiciel + CDP)
  shot.js                # pilote Chrome par le protocole DevTools, gère les clics
outils/
  molab_icones.py        # notebook molab (GPU) : 35 icônes cel-anime, planche QA, objets.zip
  molab_images.py        # notebook molab (GPU) : 5 tableaux de cinématique, cine.zip
  atelier_assets.py      # notebook marimo : cadres UI dessinés par code
  harmoniser_fonds.py    # fonds des icônes → crème exact #f8f2e4 (flood-fill)
  controle_icones.py     # planche de contrôle QA + rapport mesurable
  recadrer_icones.py     # recadre chaque icône sur son objet (sinon trop petite en jeu)
  titre_fond.py          # fond du carton de titre, dessiné (déterministe)
  generer_sons.py        # 6 WAV synthétisés
  generer_images.py      # repli historique : FLUX CPU local (lent sans GPU)
  api_replis/            # ARCHIVE : anciennes voies API (Agnes, Pollinations) — hors pipeline
```

### Direction artistique
Cel-anime 1984-89, chibi cozy : contours d'encre bruns ronds, aplats plats avec
un seul ton d'ombre, lumière chaude de fin de journée.

**Images générées par IA** — *via les notebooks molab uniquement*
(https://molab.marimo.io, GPU gratuit : téléverser le notebook, activer le GPU
dans *notebook specs*, suivre `outils/SESSION_MOLAB.md`) :

```
outils/molab_icones.py  # 35 icônes → objets.zip → assets/objets/
outils/molab_images.py  # 5 tableaux de cinématique → cine.zip → assets/cine/
python outils/harmoniser_fonds.py   # puis, en local, fonds → crème exact
python outils/controle_icones.py    # planche QA + rapport
```

Les vieux relais API (Agnes, Pollinations) sont archivés dans
`outils/api_replis/` : seule la génération par notebook garantit la cohérence
de style, car chaque prompt y vit au même endroit.

Choix de modèles, mesurés sur ce projet :

| Usage | Modèle | Pourquoi |
|---|---|---|
| Illustrations manga (personnages, objets, île, cinématiques) | Animagine XL 4.0 (dans `molab_image_lab.py`, Molab) | modèle SDXL spécialisé anime/manga, génération sur GPU distant |

Le notebook exporte chaque création en ZIP (PNG + manifeste de prompt, graine, paramètres et
SHA-256). Après téléchargement, importer un résultat avec
`python outils/importer_assets_ia.py <paquet.zip> --type sprite` ; types disponibles :
`sprite`, `objet`, `ui`, `decor`, `cinematique`, `tuile`. Voir
[`outils/MOLAB_GENERATION_IMAGES.md`](outils/MOLAB_GENERATION_IMAGES.md).

- `assets/objets/<chaine>-<niveau>.jpg` : 30 icônes 256×256, fond crème, une par objet.
- `assets/objets/gen-<chaine>.jpg` : les 5 générateurs posés sur le plateau.
- `assets/cine/` : 5 tableaux 720×1280 pour la cinématique d'ouverture.
- `assets/sprites/insulaire_manga.png` : premier personnage original généré avec Animagine XL 4.0,
  détouré pour le portrait de l'en-tête de l'île. L'asset est une illustration unique, pas une feuille d'animation.
- `assets/ui/icones_atlas.svg` : atlas vectoriel de 10 cellules de 48×48 px pour énergie, pièces, feuilles,
  lune, plateau, île, recherche, cadeau, trophée et réglages ; `UiKit.icone_emoji()` l'utilise
  automatiquement pour ces symboles et garde le rendu emoji comme solution de repli.
- Le terrain de l'île est dessiné dans `Terrain` : mer, écume, plages, sentier, trois
  variantes d'arbres, fleurs, galets et étang. Le dessin est déterministe et ne nécessite
  aucune texture de décor supplémentaire.

Le fond crème est volontaire : l'icône remplace la pastille colorée, pas besoin de la
détourer. Un JPEG 256 px pèse ~10 Ko, contre 1,4 Mo pour le PNG 512 d'origine — d'où
`recadrer_icones.py`, qui réduit et recentre sur l'objet.

`Data.chemin_icone()` renvoie `""` si le fichier manque : le jeu retombe alors sur
l'emoji et la pastille colorée, donc il reste jouable sans les images.

**Cadres d'interface** — dessinés par code, `outils/atelier_assets.py` (notebook marimo) :
6 textures 104×104 en 9 tranches (marge 22), branchées dans `UiKit.panneau_bois()` /
`panneau_parchemin()` via `StyleBoxTexture`.

- **Cinématique** : 5 tableaux joués au premier lancement par `scripts/cinematique.gd`
  (fondu enchaîné, léger zoom, titre, clic pour passer), une seule fois
  (`State.d["cine_vue"]`). `?cine=1` la désactive — c'est ce qu'utilisent les captures.
- **Chibi** : personnage original (grosse tête, cheveux en pointes, tunique pastel).
  Aucun personnage de licence n'est reproduit.

> Piège PIL : `ImageDraw` **écrit** l'alpha au lieu de le mélanger. Toute forme
> translucide doit être dessinée sur une couche RGBA séparée puis composée, sinon elle
> perce un trou dans l'image.

### Éditer le contenu
- **Objets / chaînes** : `Data.CHAINS` (5 chaînes × 6 niveaux, trilingues avec lore).
- **Générateurs** : `Data.GEN_CHARGES`, `Data.GEN_RECHARGE`, `Data.GEN_POSITIONS`.
- **Paliers du pass** : `Data.PASS_PALIERS` (points cumulés 🌙).
- **Bâtiments / zones** : `Data.ZONES` (coût 🪙/🍃, durée, prospérité).
- **Carte de l'île** : `Data.MAP_COLS`, `Data.MAP_ROWS`, `Data.MAP_ACTIVITES` (cellules des
  mini-jeux). `Data.carte_ile()` remplit les parcelles dans l'ordre des saisons, avec un palier
  de prospérité tous les 3 points — c'est ce qui fait avancer le front de déblocage.
- **Fouilles** : `Data.FOUILLES` (points, récompenses, cooldown).
- **Équilibrage** : `State` (cap ⚡=100, régén 60 s/pt, durée d'une commande, prix des caisses).

### État des sprites
Les objets de fusion utilisent encore l'emoji de repli dans `ui_kit.gd::_icone_objet()` ;
les 35 icônes de `assets/objets/` sont les illustrations actuellement utilisées. Le portrait
de l'en-tête de l'île utilise maintenant `assets/sprites/insulaire_manga.png`, une image
originale générée avec Animagine XL 4.0 et détourée. `assets/sprites/insulaire.svg` reste
une feuille éditable historique ; le rendu manga actuel est un portrait fixe, pas une animation.

## 4. Tests sans GPU

- Tests **logiques** (aucun rendu, CPU seul, rapide) :
  `godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --quit-after 600`
- Tests **visuels** : le mieux est d'exporter vers **Web** et jouer dans un navigateur
  (Chrome/Edge rend en SwiftShader sans GPU) — voir §1B.
- Captures pour vérifier un écran : `PROTO_SHOT=plateau|ile|fouille|boutique|passe|classe|cadeau`
  — après un run windowed, une capture est sauvée en `user://shot_<mode>.png`.

## 5. Choix de design volontaires (différences assumées avec l'original)

- **Pas d'attentes artificielles** : recharge des générateurs à 45 s, chantiers de 40 s à 12 min,
  commandes de 45 min, événement de 14 j (au lieu des 5 h / 18 j du jeu source), car ce prototype
  sert à tester les boucles, pas la monétisation.
- **VIP simulé** : les passes ¥30/¥45 sont des boutons de démonstration — aucun paiement réel.
- **Commerce peut vendre** : niv×3 coins, pour ne jamais bloquer un plateau saturé.
- L'île se débloque par la **prospérité** (20/35/60/120), pas par des achats, et rapporte un
  revenu passif (prospérité ÷ 6 🪙/min, plafonné à 8 h hors ligne).
- **Art généré au runtime** (emoji + formes) : aucun asset du jeu original n'est utilisé.
  Les emojis sont rendus par `NotoColorEmoji.ttf` chargée en **fallback explicite** —
  `Theme.default_font` ne propage pas la chaîne de fallback sur le web.

## 6. Boucle de développement (sans GPU)

`tools/capture.sh` sert le build, lance Chrome en WebGL logiciel et capture un écran précis,
clics compris — c'est le moyen de vérifier une modification sans carte graphique :

```
bash tools/capture.sh /tmp/board.png "?nocadeau=1" 26000              # plateau
bash tools/capture.sh /tmp/ile.png   "?nocadeau=1" 26000 "230,872"    # clic sur l'onglet Île
```

Chaque exécution part d'un profil navigateur neuf, donc d'une sauvegarde vierge.

## 6. Sources de recherche (référence 去有梦的小岛)
- 12 captures d'écran fournies par l'utilisateur (source principale de l'UX).
- `ANALYSE_JEU_REFERENCE.md` (dans l'ancien prototype LUMO) : decode complet des boucles, monnaies et événements.
- 7724 : guide de prise en main (génération 去有梦的小岛, 2026) —合成棋盘, commandes des lapins, énergie.
- Baidu Baike (fiche officielle : éditeur, approbation, ISBN) + guides 18183 / baijiahao (croisements saisons, énergie).
