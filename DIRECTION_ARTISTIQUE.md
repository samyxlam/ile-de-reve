# Île de Rêve — Direction artistique

> Document de référence visuelle et sonore. Il décrit ce qui existe, les règles à respecter
> pour que tout nouvel élément reste cohérent, et ce qu'il faut atteindre pour que le jeu
> soit présentable et commercialisable.
>
> Dernière mise à jour : 7 novembre 2026 (orientation shōnen rétro + cozy chibi).

---

## 1. L'intention, en trois mots

**Shōnen rétro 80s · Cozy · Chibi.**

La référence d'énergie est celle des aventures shōnen animées des années 1980 : dessin
celluloïd fait main, silhouettes très lisibles, expressions généreuses, poses vivantes et
petites touches de mouvement dessinées (étoiles, poussière, traits courbes). On équilibre
cette énergie par le confort d'un jeu cozy : île accueillante, lumière de fin de journée,
formes rondes et proportions chibi. Les personnages sont originaux, avec une grande tête,
des yeux expressifs et des corps compacts ; les objets restent immédiatement identifiables.
Contours d'encre brun chaud, aplats nets et une ombre celluloïd douce. Le plateau reste calme :
le dynamisme sert les fusions et les réactions, sans rendre la lecture fatigante.

**Ce qu'on veut entendre** : « ça sent le dessin animé de mon enfance », « c'est mignon ».
**Ce qu'on ne veut pas entendre** : « on dirait un prototype », « ça pique les yeux »,
« ça fait IA/watercolor template ».

Trois règles qui découlent de l'intention :

1. **Des aplats francs mais jamais néon.** Un objet peut porter une couleur chaude
   affirmée, mais rien n'est à 100 % de saturation avant d'être couvert par le contour ;
   les surfaces de décor (mer, ciel, herbe) gardent un voile crémeux.
2. **Aucun contour noir pur, aucun contour pâle.** Les contours sont un trait d'encre
   rond de brun foncé (`#4a3a28`), d'épaisseur quasi constante, dessinés « à la main ».
3. **Aucune animation sèche.** Tout mouvement dure au moins 90 ms et se termine en douceur.

---

## 2. Références et ligne rouge

**Références de ton** : l'énergie, l'expressivité et le mouvement du shōnen d'aventure
animé des années 1980, associés à une ambiance insulaire douce et aux proportions chibi.
Ces références décrivent des codes généraux, pas la reproduction d'une franchise.

**Ce qu'on emprunte** au jeu de référence *去有梦的小岛* : les proportions chibi (grosse tête,
petit corps), la douceur des teintes, les lanternes de papier, l'île vue de dessus, la
couronne d'activités minutées autour de la carte.

**Ce qu'on n'emprunte pas** : aucun personnage, aucun sprite, aucune illustration, aucun
texte, emblème, costume ou signe distinctif d'une œuvre existante. Le chibi est un insulaire
original — cheveux en pointes, tunique pastel, yeux ronds — et non un personnage existant.
Les objets sont des créations propres décrites par un prompt.

C'est une contrainte juridique autant qu'artistique : le jeu doit pouvoir être publié sans
dépendre d'une licence tierce.

---

## 3. Palette

Couleurs de référence, telles qu'utilisées dans `scripts/ui_kit.gd`.

### Fonds et surfaces

| Rôle | Hex | Usage |
|---|---|---|
| Parchemin | `#f7edda` | fond général, panneaux clairs |
| Parchemin foncé | `#eaddc2` | barres, zones en retrait |
| Bois | `#b5773a` | cadres de panneau |
| Bois foncé | `#7d4e1e` | bordures, ombres de cadre |
| Bois clair | `#d9a05f` | boutons secondaires, accents |

### Accents

| Rôle | Hex | Usage |
|---|---|---|
| Jade | `#8ec63f` | action principale (construire, livrer, tourner) |
| Jade foncé | `#5f962c` | bordure du jade, texte sur fond clair |
| Or | `#e8b53a` | récompense, monnaie, bouton de gain |
| Rouge | `#e0503f` | erreur, urgence, compte à rebours critique |
| Encre | `#4a3a28` | **tout le texte**, tous les contours |
| Blanc chaud | `#fff8ea` | texte sur fond sombre |

### Palette de la cinématique et des icônes

| Rôle | Hex |
|---|---|
| Nuit haute | `#3a3454` |
| Nuit médiane | `#7c6a92` |
| Aurore | `#f0b2a4` |
| Soleil | `#ffe4be` |
| Mer haute | `#a8c6d6` |
| Mer basse | `#6c92ac` |
| Île | `#a8cea4` |
| Ombre d'île | `#7eaa82` |
| Terre | `#c69e80` |
| Lanterne | `#f2a07a` |
| Peau (chibi) | `#f6d8c2` |
| Cheveux | `#563e3e` |

### Règles d'usage

- **Une seule couleur d'action par écran.** Le jade signifie « fais-le » ; l'or signifie
  « tu gagnes ». Ne jamais mettre deux boutons verts concurrents côte à côte.
- **Le rouge est réservé à l'urgence.** Un compte à rebours passe au rouge sous 5 minutes,
  pas avant.
- **Jamais de texte pur sur une photo ou un dégradé** sans un voile sombre à 35 % derrière.

---

## 4. Typographie

| Élément | Police | Taille | Graisse |
|---|---|---|---|
| Titre de modale | Noto Sans CJK SC | 24 px | demi-gras |
| Titre d'écran | Noto Sans CJK SC | 20 px | demi-gras |
| Texte courant | Noto Sans CJK SC | 14–15 px | normal |
| Métadonnée, chrono | Noto Sans CJK SC | 11–13 px | normal |
| Chiffre de monnaie | Noto Sans CJK SC | 15 px | demi-gras |
| Emoji d'interface | Noto Color Emoji | 16–26 px | — |

**Contrainte technique — résolue le 07/11** : les polices complètes pèsent 40 Mo ; le jeu charge désormais les sous-ensembles `cjk-sous-ensemble.otf` (263 Ko) et `emoji-sous-ensemble.ttf` (738 Ko), générés par `outils/sous_ensemble_polices.py` à partir des caractères réellement utilisés. Les originales vivent dans `fonts/source/` (.gdignore, jamais exportées). Pour la version
commerciale, il faut les **sous-ensembler** :

```bash
pip install fonttools brotli
pyftsubset fonts/NotoSansCJKsc-Regular.otf \
  --unicodes="U+0020-007E,U+00C0-017F,U+2000-206F,U+3000-303F,U+4E00-9FFF" \
  --output-file=fonts/cjk-sous-ensemble.otf
pyftsubset fonts/NotoColorEmoji.ttf \
  --text="⚡🪙🍃🌙🎁🔒🏮🏆🔍🎡🎊🛒🎒📜⏳✔✕←→▼🌿🏗🎨🎯🎲💎🌸🍁❄️🪷" \
  --output-file=fonts/emoji-sous-ensemble.ttf
```

Gain attendu : **40 Mo → 6-8 Mo**. À faire avant toute diffusion publique.

---

## 5. Inventaire des assets

### 5.1 Icônes d'objets — `assets/objets/`

| | |
|---|---|
| Nombre | 30 (5 chaînes × 6 niveaux) + 5 générateurs |
| Format | JPEG, qualité 90 |
| Taille | 256 × 256 px |
| Fond | crème uni (`#f8f2e4`), **pas de transparence** |
| Poids | ~10 Ko pièce, 604 Ko au total |
| Cadrage | objet centré, marge de 14 % autour de sa boîte englobante |

**Pourquoi un fond crème et pas de transparence** : l'icône remplace la pastille colorée de
la case. Détourer une illustration produit des halos sales ; un fond uni se marie avec le
damier du plateau.

**Pourquoi 256 px et pas 512** : la case affiche 90 px. 256 laisse une marge de netteté pour
les écrans haute densité sans payer 1,4 Mo par image.

**Gabarit de prompt** (à ne pas modifier d'un objet à l'autre, c'est ce qui garantit la
cohérence) :

```
game item icon, one single original object centered, {description},
hand-drawn 1980s adventure-anime cel animation, expressive rounded shapes,
clean confident warm-brown ink contours, crisp flat color fields, one gentle cel-shadow,
warm late-afternoon light, cozy island mood, chibi-friendly scale, cream paper background,
readable silhouette, no text, no logo, no copied character, no border, no frame
```

**Modèle** : Animagine XL 4.0 dans le notebook Molab (`outils/molab_image_lab.py`),
28 étapes, CFG 5 en 1024×1024, avec Euler Ancestral. Il produit des illustrations
anime/manga pour les personnages, objets et décors ; le prompt est adapté à chaque type.
Pour les icônes, garder les objets droits et centrés — préférable pour
une grille. La voie API Agnes est **retirée du pipeline** (scripts archivés dans
`outils/api_replis/`) : tout passe par le notebook pour garantir l'unité du style
généré.

**Contrôle qualité** : générer et vérifier chaque icône séparément, puis monter une planche
de contrôle locale. Vérifier la progression de niveaux et l'absence de texte parasite.

### 5.2 Cadres d'interface — `assets/ui/`

| | |
|---|---|
| Nombre | 6 (bois, parchemin, parchemin foncé, jade, or, encens) |
| Format | PNG avec transparence |
| Taille | 104 × 104 px |
| Découpe | 9-slice, **marge 22 px**, contenu 10 px |
| Poids | ~15 Ko pièce |

La marge de 22 px doit rester supérieure au rayon des coins (20 px), sinon l'arrondi est
coupé. Un panneau plus petit que 44 px de haut ne peut pas utiliser ces cadres — c'est
pourquoi les petits boutons gardent un aplat.

Génération : `python outils/atelier_assets.py` (notebook marimo, dessin par code).

### 5.3 Cinématique — `assets/cine/`

| | |
|---|---|
| Nombre | 5 tableaux |
| Format | PNG, qualité 93 |
| Taille | 720 × 1280 px (format exact du viewport) |
| Poids | ~700 Ko pièce, 3,5 Mo au total |

Ordre narratif : mer au crépuscule → barque avec l'enfant → l'île au loin → lanternes et
cerisier → fond de titre.

Génération : notebook `outils/molab_images.py` (GPU molab, 768×1344 puis réduit à
720×1280 — une image générée en grand puis réduite est plus nette qu'une
génération directe en petit ; il existe aussi une variante dessinée par code,
`outils/titre_fond.py`, pour le carton de titre seul).

### 5.4 Sons — `assets/sons/`

| | |
|---|---|
| Nombre | 6 |
| Format | WAV, mono, 16 bits, 44,1 kHz |
| Durée | 0,10 à 0,42 s |
| Poids | 122 Ko au total |

| Nom | Usage | Description |
|---|---|---|
| `fusion` | fusion de deux objets | deux notes montantes (520→780 Hz) |
| `piece` | livraison, ramassage, achat | clochette (1318 + 1760 Hz) |
| `clic` | production d'un générateur | blip court (392 Hz) |
| `erreur` | action impossible | grave, non agressif (196 Hz) |
| `succes` | construction terminée, roue | arpège majeur (523/659/784) |
| `construire` | lancement de chantier | bois frappé (110/220/330 Hz) |

Génération : `python outils/generer_sons.py` (synthèse pure, aucune licence).

### 5.5 Bâtiments de l'île — `assets/batiments/`

| | |
|---|---|
| Nombre | 24 (4 saisons × 6), clés `spr1…spr6`, `sum1…sum6`, `aut1…aut6`, `win1…win6` |
| Format | PNG, fond transparent |
| Taille | 256 × 256 px (affiché ~54 px sur la parcelle, 96 px dans la modale) |
| Génération | 07/11/2026, gabarit §5.1 adapté (`one single original building centered`) |

Le jeu les charge via `Data.chemin_batiment(cle)` ; si le PNG manque, la parcelle
retombe sur l'emoji. Détourage obligatoire avant intégration : les sources du
générateur livrent un fond blanc opaque (parfois dégradé ou damier cuit) — passer
par `atelier_lot_complet.py` (segmentation scipy) et vérifier la planche QA.

### 5.6 Icônes d'activités — `assets/activites/`

Même gabarit que les bâtiments ; clés `act_0…act_5` dans l'ordre de
`island.gd::ACTIVITES` (fouille, pass, classement, cadeaux, roue, don).
Chargées via `Data.chemin_activite(i)`, fallback emoji identique.

### 5.7 Personnage — `assets/sprites/`

`insulaire_manga.png` (portrait détouré, référence art_review) + 4 poses générées
le 07/11 : `pose_0` salut, `pose_1` joie, `pose_2` réflexion, `pose_3` pièce,
et la feuille 2×2 `insulaire_poses.png` (768×768). **Point de vigilance QA** :
les poses 2 et 3 s'écartent légèrement du costume de référence (manches blanches,
short jaune). À harmoniser lors de la prochaine session de poses — générer depuis
la même graine/prompt et ne pas multiplier les variations de costume.

### 5.8 Assets store — `assets/store/`

| Fichier | Usage |
|---|---|
| `logo_embleme.png` | emblème rond détouré (anneau brun foncé protecteur) |
| `icone_app_1024.png` | icône application 1024×1024, sans transparence |
| `banniere_1024x500.png` | bannière store, titre « Île de Rêve » composé par PIL |

---

## 6. Interface

### 6.1 Grille de layout

Viewport de référence : **720 × 1280**, portrait. Tout est exprimé dans cet espace ; le
moteur met à l'échelle.

```
┌─────────────────────────────────────────┐
│ barre de monnaies            48 px      │  niveau · ⚡ · 🪙 · 🍃 · FR · ⚙
├─────────────────────────────────────────┤
│ rangée d'événements          50 px      │  月神节 · 筑景名录 · 礼品
├─────────────────────────────────────────┤
│                                         │
│  contenu (plateau / île / fouille)      │  prend tout l'espace restant
│                                         │
├─────────────────────────────────────────┤
│ navigation                   58 px      │  Plateau · Île · Fouille
└─────────────────────────────────────────┘
```

Marges latérales : **6 px**. Écart entre blocs : **6 px**.

### 6.2 Cibles tactiles

- Bouton standard : hauteur **46 px** minimum, jamais moins de **40 px**.
- Bouton de barre d'outils : **50–56 px**.
- Une case du plateau : **90 × 84 px**.
- Une parcelle de la carte : **106 × 98 px**.
- Écart minimum entre deux cibles adjacentes : **6 px**.

Un doigt fait ~44 px de large : toute cible plus petite que 40 px est une erreur.

### 6.3 États d'un élément

Chaque élément interactif doit avoir **quatre états visuels distincts**, sinon le joueur
hésite :

| État | Traitement |
|---|---|
| Normal | fond pastel, bordure brune 2 px |
| Survol | fond éclairci de 8 %, même bordure |
| Pressé | fond assombri de 8 % |
| Désactivé | fond gris `#a89a86`, texte à 70 % d'opacité |

Et pour les parcelles de la carte, un état par étape de progression : **verrouillée** (🔒 +
palier), **disponible** (prix), **en chantier** (⏳ + compte à rebours), **construite** (✔ ou
butin `🪙 +N`).

### 6.4 Hiérarchie

Trois niveaux, pas plus :

1. **Ce que je peux faire** — bouton jade, gros, seul.
2. **Ce que je gagne** — or, chiffres, à côté de l'action.
3. **Ce que je dois savoir** — texte encre, petit, en dessous.

Si un écran a besoin d'un quatrième niveau, c'est que l'écran fait trop de choses.

---

## 7. La carte de l'île

### 7.1 Couches, de l'arrière vers l'avant

1. **Mer** `#91b7c7` avec 13 rubans d'écume sinueux, reflets ponctuels et opacités douces.
2. **Rive** en trois bandes (`#d8c396`, `#f0dfb6`, liseré clair), autour d'un contour organique.
3. **Masse de l'île** `#83a965`, puis **prairie** `#a6c77d` en retrait de 20 px.
4. **Sentier** sinueux : ombre végétale, terre `#e3c996` de 12 px et fin reflet crème.
5. **Bosquets** déterministes : 42 arbres en trois variantes de feuillage, ombre, tronc et arc de lumière ; 27 petites fleurs ou pierres.
6. **Étang** à quatre couches d'eau et de rive, avec reflet, trois nénuphars et arc lumineux.
7. **Parcelles**, posées à coordonnées fixes.

Le terrain est dessiné par `Terrain` dans `scripts/island.gd`. Les détails sont générés
avec une graine fixe afin que la disposition reste stable entre les sessions.

### 7.1 Personnage

Le portrait de départ généré par Animagine XL 4.0 est `assets/sprites/insulaire_manga.png`.
Il présente un aventurier insulaire original en pied, avec une palette jade et ocre et un
contour de cel anime. Le fond uni a été détouré pour l'en-tête de l'île ; l'image source,
la graine et le prompt sont conservés dans `art_review/`. C'est une première illustration
de personnage, pas encore une feuille d'animation : les poses et expressions suivantes
doivent être générées à partir de cette référence et vérifiées pour garder le même design.

### 7.2 Les parcelles

- Taille **106 × 98 px**, coins arrondis 14 px.
- **Rangées impaires décalées d'une demi-colonne** (59 px) et **rotation de ±6°** par
  parcelle. Ces deux détails sont ce qui distingue une carte d'un tableau.
- Couleur par saison : printemps `#b6d48c`, été `#8fd0c7`, automne `#e0b76a`, hiver `#aec6da`.
- Verrouillée : `#8d9a6c`, icône 🔒, palier de prospérité en badge.
- Construite : couleur de saison + ombre portée + bulle de butin.

### 7.3 Le front de déblocage

La progression doit être **lisible sur la carte**, pas seulement dans un chiffre. Trois
pistes, par ordre de simplicité :

1. Les parcelles verrouillées affichent des **herbes folles** au lieu d'un cadenas sec.
2. Au moment du déblocage, une **animation de défrichage** (herbes qui s'effacent, poussière).
3. Les parcelles construites **prennent la couleur de leur saison**, créant des taches de
   couleur qui gagnent la carte au fil du jeu.

---

## 8. Animation et « juice »

Le jeu est aujourd'hui **trop statique**. Une fusion produit un rebond de 220 ms et un toast.
C'est insuffisant : le plaisir d'un merge-2 vient du retour sensoriel immédiat.

### 8.1 Timings de référence

| Animation | Durée | Courbe |
|---|---|---|
| Pression d'un bouton | 90 ms | `EASE_OUT` |
| Fusion (scale 1 → 1.14 → 1) | 80 + 140 ms | `EASE_OUT` puis `EASE_IN_OUT` |
| Nombre flottant `+12` (montée + fondu) | 700 ms | `EASE_OUT`, fondu sur les 300 derniers ms |
| Apparition de modale (0.94 → 1 + fondu) | 180 ms | `EASE_OUT` |
| Changement d'écran (fondu) | 220 ms | `EASE_IN_OUT` |
| Compte à rebours critique (pulsation) | 900 ms en boucle | sinusoïdale |
| Transition de cinématique | 800 ms | `EASE_IN_OUT` |

**Règle** : aucune animation ne dépasse **700 ms** sauf la cinématique. Au-delà, le joueur
attend.

### 8.2 Ce qu'il faut ajouter, par ordre d'impact

1. **Nombre flottant à la livraison.** `+63 🪙` qui monte de 40 px et s'efface au-dessus de la
   commande livrée. C'est le retour le plus important du jeu : il matérialise le gain.
2. **Éclat à la fusion.** 6 à 8 particules rondes de la couleur de l'objet, qui s'écartent en
   300 ms et s'effacent. Pas de sprite : des cercles dessinés suffisent.
3. **Pulsation de la case fusionnée.** La case grossit de 14 % puis revient — existe déjà,
   mais devrait s'accompagner d'un halo blanc bref.
4. **Secousse légère à l'encaissement du butin.** 4 px d'amplitude, 120 ms, sur le panneau
   seulement — jamais sur tout l'écran, c'est vulgaire.
5. **Entrée d'écran.** Le contenu arrive depuis le bas de 24 px en 220 ms, plutôt que
   d'apparaître d'un coup.
6. **Bulle de butin qui « respire ».** Scale 1 → 1.06 en boucle de 1,8 s sur les bâtiments
   prêts à ramasser. C'est ce qui attire l'œil sans clignoter.

### 8.3 Ce qu'il ne faut pas faire

- Pas de particules plein écran, pas de flash blanc, pas de zoom brusque.
- Pas de rebond élastique (`TRANS_ELASTIC`) : c'est daté et ça casse la douceur.
- Pas plus de deux animations simultanées sur le même élément.

---

## 9. Cinématique d'ouverture

### 9.1 Découpage

| # | Plan | Durée | Rôle |
|---|---|---|---|
| 1 | Mer au crépuscule, île à l'horizon | 3,0 s | poser le lieu et le calme |
| 2 | Enfant chibi de dos dans une barque, lanterne | 3,0 s | introduire le personnage |
| 3 | L'île au loin dans la brume | 3,0 s | créer le désir d'y aller |
| 4 | Lanternes et pétales de cerisier | 3,0 s | la chaleur, la fête |
| 5 | Ciel crépusculaire + titre | 4,0 s | nommer le jeu, inviter à entrer |

Total : **16 secondes**, dont 12 avant que le joueur puisse passer.

### 9.2 Réalisation

- **Fondu enchaîné de 800 ms** entre chaque plan, jamais de coupe sèche.
- **Zoom avant lent** : échelle 1,06 → 1,00 sur la durée du plan. Imperceptible, mais ça
  donne l'impression d'une caméra.
- **Titre** : apparaît en fondu de 1,2 s sur le dernier plan, avec le sous-titre
  « 去有梦的小岛 · prototype » en 18 px à 75 % d'opacité.
- **Indication de sortie** : « Toucher pour passer » en bas, 14 px, blanc à 55 %.
- **Son** : aucun aujourd'hui. Il faudrait une nappe douce de 16 s, ou au minimum un
  ressenti à chaque transition.

### 9.3 Ce qui manque pour être professionnel

- Un **mouvement de caméra** (panoramique latéral) plutôt qu'un simple zoom : deux images
  clés par plan suffisent.
- Une **transition par volet** entre les plans 3 et 4, pour marquer le passage du large à
  l'intime.
- Un **logo** dessiné, pas seulement du texte.

---

## 10. Audio

### 10.1 Effets (existant)

Six sons, voir §5.4. Volumes recommandés : `-6 dB` pour les gains, `-10 dB` pour les clics,
`-4 dB` pour les erreurs (elles doivent s'entendre sans agresser).

### 10.2 Ce qui manque

- **Musique d'ambiance.** Une boucle de 60 à 90 s, guzheng ou koto, tempo lent, pas de
  percussion. C'est le plus gros manque sonore : un jeu silencieux paraît inachevé.
  Solution gratuite : synthèse par code (comme les effets) ou banque libre de droits
  (Free Music Archive, ccMixter) — vérifier la licence pour un usage commercial.
- **Son de pose d'objet** sur le plateau (très court, 40 ms).
- **Son d'ouverture de modale** (feuille de papier, 120 ms).
- **Variation des gains** : trois hauteurs différentes pour `piece` afin d'éviter la
  répétition quand on livre plusieurs commandes d'affilée.

### 10.3 Règles de mixage

- Un seul son « fort » à la fois. Si deux récompenses tombent ensemble, la seconde baisse de
  4 dB.
- Aucun son ne dure plus de 0,5 s hors musique et cinématique.
- Le bouton muet doit être accessible en deux clics maximum — il l'est (boutique ⚙).

---

## 11. Pipeline de production

### 11.1 Choisir le bon outil

| Besoin | Outil | Pourquoi |
|---|---|---|
| Personnages, objets illustrés, décors et cinématiques | notebook `outils/molab_image_lab.py` (Animagine XL 4.0, GPU Molab) | illustration anime/manga et prompts courts, adaptés par type |
| Gros lots pilotés + post-traitement | génération pilotée + `outils/atelier_lot_complet.py` (détourage scipy, planche QA) | voie du 07/11/2026 : 43 livrables en une session, manifeste SHA-256 |
| Cadres, motifs, fonds répétables | `outils/atelier_assets.py` (code) | précision au pixel, 9-slice |
| Sons | `outils/generer_sons.py`, `titre_fond.py` (code) | zéro licence, zéro dépendance |

**Moteur de génération : Animagine XL 4.0 sur le GPU Molab.** Le notebook actif
est `outils/molab_image_lab.py`; ses réglages et presets forment la source de vérité
pour la génération manga. Les anciens notebooks SDXL/FLUX restent des prototypes
archivés et ne font pas partie de cette boucle.

**Ne jamais générer par IA ce qui doit être répété à l'identique** (cadres, motifs, boutons).
L'IA excelle pour l'illustration, pas pour la cohérence d'un système.

### 11.2 Boucle de travail

```
1. choisir le type d’image et écrire un prompt court dans `outils/molab_image_lab.py`
2. générer une image à la fois, puis vérifier composition, silhouette, style et transparence
3. télécharger le ZIP PNG + manifeste depuis le notebook avant l'arrêt de Molab
4. pour un personnage, détourer le fond et inspecter les bords sur fond clair et foncé
5. intégrer le PNG seulement après vérification du style, de la silhouette et de la lisibilité
6. importer le ZIP avec `python outils/importer_assets_ia.py <paquet.zip> --type <type>` ;
   le script vérifie SHA-256 et dimensions, copie le PNG sans écraser et conserve son manifeste
7. générer séparément chaque pose et valider la cohérence du personnage avant animation
```

### 11.3 Checklist de validation d'une icône

- [ ] L'objet est seul, centré, sans objet secondaire.
- [ ] Il se lit à 90 px (le tester réduit, pas à taille réelle).
- [ ] Le fond est crème uni, sans dégradé ni bord.
- [ ] Aucun texte, aucun filigrane, aucune signature.
- [ ] La couleur dominante ne crie pas (pas de néon ; aplats couverts par le contour).
- [ ] Il se distingue de ses voisins de chaîne (niveau N vs N+1).

---

## 12. Ce qu'il faut pour être commercialisable

Un prototype peut se permettre l'approximation. Un produit, non. Voici l'écart, par ordre
d'importance.

### 12.1 Bloquant

| Point | État | Cible |
|---|---|---|
| **Session de jeu testée** | jamais jouée 20 min | 3 sessions complètes, économie ajustée |
| **Poids du build** | 68 Mo | **< 40 Mo** (sous-ensemblage des polices) |
| **Musique** | absente | une boucle d'ambiance |
| **Onboarding** | absent | 3 étapes guidées au premier lancement |

### 12.2 Important

| Point | État | Cible |
|---|---|---|
| Cohérence des 35 icônes | bonne, quelques écarts | revue par planche, 2-3 régénérations |
| Animations de retour | minimales | §8.2 points 1 à 4 |
| Carte | lisible mais rectangulaire | parcelles irrégulières, décors |
| Résolution des assets | 256 px | 512 px pour les écrans haute densité |
| Accessibilité | non traitée | contraste ≥ 4,5:1, taille de texte réglable |

### 12.3 Assets de diffusion (stores)

| Asset | Spécification |
|---|---|
| Icône d'application | 1024 × 1024 PNG, sans transparence |
| Icône adaptative Android | 512 × 512 + zone de sécurité de 66 % |
| Captures d'écran | 1080 × 1920, 6 minimum, une par système |
| Bande-annonce | 30 s, 1080p, les 3 premières secondes = la fusion |
| Bannière | 1024 × 500 |
| Textes de fiche | titre 30 car., description courte 80 car., longue 4000 car. |
| Politique de confidentialité | obligatoire si collecte de données (ici : aucune) |
| Classification par âge | 3+ (aucune violence, aucun achat réel dans le prototype) |

### 12.4 Positionnement

Le marché du merge-2 est saturé. Ce qui peut différencier celui-ci :

- **L'absence d'agression monétaire** : pas de pub, pas de paiement réel, pas de timer
  punitif. C'est un argument, pas un défaut — à condition d'assumer le modèle (premium ou
  gratuit sans monétisation).
- **L'esthétique rétro anime** : rare dans le genre, qui penche vers le 3D coloré.
- **Le trilingue natif** : ouvre le marché chinois, qui est le marché d'origine du genre.

---

## 13. Checklist QA visuelle

À passer avant chaque livraison.

- [ ] Aucun texte coupé, tronqué ou superposé, dans les trois langues.
- [ ] Aucun emoji rendu en carré vide (test web, pas seulement natif).
- [ ] Aucun élément interactif sous 40 px de haut.
- [ ] Tous les boutons ont leurs quatre états.
- [ ] Les contrastes texte/fond passent 4,5:1.
- [ ] La cinématique se joue une fois, se saute au clic, et ne revient pas.
- [ ] Les modales se ferment par la croix et ne bloquent jamais le jeu.
- [ ] Les compte à rebours s'affichent en `1h 02m` et non en `3722 s`.
- [ ] Les icônes se lisent à la taille réelle du plateau (90 px).
- [ ] Le jeu reste jouable avec le son coupé.
- [ ] Le build fait moins de 40 Mo (après sous-ensemblage des polices).
- [ ] Test sur un écran de 360 px de large : rien ne déborde.
