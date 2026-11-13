# Île de Rêve — Documentation du projet

> Prototype jouable d'un jeu de fusion (merge-2) et de gestion d'île, inspiré des mécaniques
> de *去有梦的小岛* (mini-jeu WeChat). Godot 4.7, cible navigateur, jouable sans carte graphique.
>
> Dernière mise à jour : 2 novembre 2026.

---

## 1. En bref

| | |
|---|---|
| **Genre** | Merge-2 + gestion d'île + événements à paliers |
| **Moteur** | Godot 4.7.2, rendu GL Compatibility |
| **Cible** | Navigateur (WebGL, rendu logiciel), portrait 720×1280 |
| **Langues** | Français, anglais, chinois (bascule en jeu) |
| **Code** | 3 777 lignes de GDScript, 13 scripts |
| **Outils** | 1 232 lignes de Python, 9 scripts |
| **Assets** | 35 icônes d'objets, 24 bâtiments, 6 activités, 5 tableaux de cinématique, 6 cadres d'UI, 4 poses de personnage, logo + icône app + bannière, musique d'ambiance 72 s, 6 sons |
| **Build web** | 57 Mo (pck 19 Mo : polices sous-ensemblées à ~1 Mo, musique 0,6 Mo ; le WASM pèse 38 Mo) |
| **État** | Prototype complet et jouable, **non testé sur une session longue** |

**Le jeu en une phrase** : tu tapes des générateurs posés sur un plateau 7×10 pour produire
des objets, tu fusionnes les paires pour monter en niveau, tu livres les commandes de lapins
contre des pièces, et tu dépenses ces pièces pour bâtir une île qui produit à son tour.

---

## 2. Origine et positionnement

Le projet reproduit **les mécaniques** d'un mini-jeu WeChat chinois, *去有梦的小岛*
(« l'île aux rêves »), édité par 重庆聚购科技. Aucun asset, texte ou code du jeu original
n'est utilisé : tout est généré par code ou par IA à partir d'une description.

**Les mécaniques ne sont pas protégeables ; les assets et le code le sont.** C'est la ligne
tenue depuis le début : on reproduit les boucles de jeu, jamais les fichiers. Le personnage
(chibi) est original, les objets sont des créations propres, l'interface est une
réinterprétation.

Une demande de décompiler le paquet `.wxapkg` du jeu a été refusée pour cette raison : rien
d'extrait n'aurait été publiable, et le risque juridique aurait été réel.

---

## 3. État actuel — ce qui fonctionne

Tout ce qui suit a été vérifié dans le navigateur, capture d'écran à l'appui.

### Plateau de fusion
- Grille **7×10 (70 cases)**, damier vert pâle, glisser-déposer, échange, fusion animée.
- **Générateurs posés sur le plateau** (5 chaînes, 5 charges, 45 s de recharge). Taper un
  générateur consomme 1 ⚡ et pose un objet niveau 1 sur la case libre la plus proche.
- **3 commandes de lapins en haut**, avec récompense visible et **minuteur de 45 min**.
  Une commande non livrée est remplacée.
- **Caisses en bois verrouillées** sur les deux rangées du bas, de 60 à 900 🪙.
- Barre du bas : coffre | fiche objet (nom, niveau, lore, vente) | boutique.
- 30 objets : 5 chaînes × 6 niveaux, chacun avec nom et lore trilingues.

### Île
- **Carte peinte** : mer, anneau de sable, masse de l'île, sentier, bosquets, étang.
- **30 parcelles** posées à coordonnées fixes, rangées impaires décalées, rotation ±6°.
- **Déblocage progressif** : chaque parcelle a son palier de prospérité
  (`base de la saison + 3 × rang`), soit printemps 0→15, été 30→45, automne 80→95,
  hiver 160→175.
- **Butin par bâtiment** : chaque bâtiment construit accumule `prospérité ÷ 6` pièces par
  minute, affiche `🪙 +N`, et se ramasse en le touchant. Plafond de cumul : 8 h.
- **6 activités** sur des parcelles réservées : 彩色寻物, 天赐好礼, 月神节, 筑景名录,
  roue de la fortune, cadeaux.

### Systèmes et événements
- **月神节** : pass vertical à 2 colonnes (gratuit / VIP), 10 paliers, réclamation sans
  fermer la fenêtre. VIP ¥30 / 豪华 ¥45 simulés.
- **筑景名录** : classement par zone, onglets fonctionnels, récompense top 3 quotidienne.
- **彩色寻物** : 3 niveaux à déblocage séquentiel, 8 objets cachés dans un décor généré,
  cooldown de rejeu, **+25/40/60 ⚡**.
- **Roue de la fortune** : 8 secteurs pondérés (⚡10→60, 🪙60/120, 🍃2/4), 1 tour / 30 min.
- **天赐好礼** : +50 ⚡ / +200 🪙 toutes les 3 h.
- **Cadeau quotidien**, **tâches quotidiennes** (4), **boutique** (énergie, packs simulés,
  langue, son, reset, 图鉴).
- **Cinématique d'ouverture** : 5 tableaux, fondu enchaîné, zoom lent, titre, clic pour passer.
  Jouée une seule fois.
- **Sons** : 6 effets synthétisés, muet persistant.

### Technique
- Sauvegarde JSON dans `user://save.json`, migration de version intégrée.
- Interface trilingue commutable à chaud.
- Régénération d'énergie et revenus de l'île calculés **hors ligne** au chargement.

---

## 4. Architecture

```
project.godot            Godot 4.7, portrait 720×1280, GL Compatibility
scenes/main.tscn         entrée unique (un seul nœud + script)
scripts/
  data.gd      [autoload Data]   contenu : chaînes, générateurs, zones, carte, tâches,
                                 fouilles, roue, i18n
  state.gd     [autoload State]  état persistant : monnaies, plateau, générateurs,
                                 commandes, île, événements, sauvegarde
  son.gd       [autoload Son]    effets sonores, 6 lecteurs tournants, muet
  ui_kit.gd                      thème, polices, panneaux 9-slice, modales, toasts, icônes
  main.gd                        barre de monnaies, rangée d'événements, navigation, cadeau
  board.gd                       plateau : commandes, générateurs, fusions, caisses
  island.gd                      carte de l'île : terrain, parcelles, activités, chantiers
  hidden_game.gd                 fouille : niveaux, décor généré, cibles
  event_pass.gd                  月神节 : paliers 2 colonnes + tâches
  rank_board.gd                  筑景名录 : classement, onglets
  shop_ui.gd                     boutique, paramètres, 图鉴
  roue.gd                        disque de la roue (rotation, secteurs, étiquettes)
  cinematique.gd                 séquence d'ouverture
outils/                          génération d'assets (Python + marimo)
assets/objets/                   35 icônes 256×256 (30 objets + 5 générateurs)
assets/batiments/                24 illustrations de bâtiments 256×256 (fond transparent)
assets/activites/                6 icônes d'activités 256×256 (fond transparent)
assets/sprites/                  personnage : portrait + 4 poses + feuille 2×2
assets/store/                    logo emblème, icône app 1024, bannière 1024×500
assets/ui/                       6 cadres 104×104 pour 9-slice
assets/cine/                     5 tableaux 720×1280
assets/sons/                     6 WAV mono 44,1 kHz
assets/musique/                  ambiance.ogg — boucle 72 s synthétisée (génération outils/generer_musique.py)
fonts/                           Noto Sans CJK SC + Noto Color Emoji (40 Mo)
tools/                           serveur local, capture d'écran automatisée
build/web/                       export HTML5 prêt à servir
```

**Trois autoloads** : `Data` (contenu immuable), `State` (tout ce qui persiste), `Son`.
L'ordre de chargement compte : `Son` lit `State` dans son `_ready`.

**Un seul écran à la fois** dans `main.contenu` : plateau, île ou fouille. Les modales
(pass, classement, boutique, roue, cadeau, construction) sont ajoutées à la racine de la
scène, au-dessus de tout.

**Sauvegarde** : un dictionnaire unique `State.d`, sérialisé en JSON à chaque action
importante et toutes les 5 secondes. `version` permet les migrations — la v2 a remis le
plateau à zéro lors du passage à 7×10.

---

## 5. Économie

| Monnaie | Rôle | Sources | Puits |
|---|---|---|---|
| ⚡ **Énergie** | produire des objets | régénération +1/60 s, cadeau +20/j, roue +10→60, fouille +25→60, 天赐好礼 +50 | 1 par production |
| 🪙 **Pièces** | construire, débloquer | commandes, ventes, roue, fouille, butin des bâtiments | caisses (60→900), chantiers, coffre |
| 🍃 **Feuilles** | énergie, packs | commandes rares, paliers, fouille | boutique |
| 🌙 **Points d'événement** | paliers du pass | commandes, tâches, fouille | — |
| 🏮 **Prospérité** | débloquer l'île | bâtiments construits | — |

**La boucle** : produire → fusionner → livrer → pièces → construire → prospérité →
nouvelles parcelles → plus de butin → plus de pièces.

**Le point sensible** : 100 ⚡ de capacité, +1 par minute. C'est le modèle free-to-play de
l'original, mais pour un prototype c'est un mur après ~100 productions. Les activités
gratuites (roue, fouille, cadeau) servent de soupape. Si le rythme reste trop lent, le
levier est `State.REGEN_ENERGIE`, pas les récompenses.

---

## 6. Pipeline d'assets

Deux sources, jamais de fichiers externes.

**Par IA — deux voies, un seul gabarit de style :**

1. **Notebooks molab** (GPU gratuit de molab, https://molab.marimo.io ; téléverser le
   fichier, activer le GPU via *notebook specs*) — voie interactive : générer image par
   image, télécharger le ZIP, importer avec `outils/importer_assets_ia.py`.
2. **Génération pilotée + post-traitement local** (`outils/atelier_lot_complet.py`) —
   la voie utilisée pour le lot du 07/11/2026 : bâtiments, activités, poses, logo,
   icône app, bannière et les 5 tableaux de cinématique régénérés. Le script détourne
   (scipy, composantes connexes), recadre, redimensionne, compose la bannière et monte
   la planche QA ; le manifeste SHA-256 du lot vit dans `outils/lot_2026-11-07/`.

Les relais API tierces (Agnes, Pollinations) et le repli FLUX CPU local restent
**archivés** dans `outils/api_replis/`. Le prompt de style (cel-anime 1984-89) est le
même pour les deux voies, d'où l'unité du style.
```
outils/molab_icones.py     # 35 icônes, 1024 → cadrage → 256 px, planche QA, objets.zip
outils/molab_images.py     # 5 tableaux de cinématique, 768×1344 → 720×1280, cine.zip
```
Post-traitement local (sans GPU) :
```
outils/harmoniser_fonds.py  # fonds des icônes → crème exact #f8f2e4
outils/controle_icones.py   # planche de contrôle QA + rapport
outils/atelier_lot_complet.py  # lot complet 07/11 : détourage, recadrage, QA, bannière
```

**Par code (Python + marimo)** — cadres d'UI, sons, fond de titre.
```
python outils/atelier_assets.py                    # cadres 9-slice (notebook marimo)
python outils/generer_sons.py                      # 6 WAV synthétisés
python outils/titre_fond.py                        # fond du carton de titre
```

Aucun asset n'est obligatoire : `Data.chemin_icone()` renvoie `""` si le fichier manque, et
le jeu retombe sur l'emoji. On peut supprimer n'importe quelle image sans casser le jeu.

---

## 7. Pièges rencontrés (à ne pas refaire)

Ces cinq erreurs ont coûté du temps ; elles sont documentées pour être évitées.

1. **`Theme.default_font` ne propage pas les polices de secours sur le web.** Les emojis
   sortaient en carrés vides. Solution : `add_theme_font_override("font", …)` explicite sur
   chaque label.
2. **`set_anchors_preset()` ne redimensionne pas** un contrôle ajouté après la première passe
   de layout. Utiliser `set_anchors_and_offsets_preset()` — sinon l'écran reste vide.
3. **Un `Button` n'est pas un `Container`.** Son contenu reste collé en (0,0), et un `Label`
   en `clip_text` tombe à 0 px de large. Passer par `UiKit.contenu_bouton()`.
4. **`GridContainer.custom_minimum_size` plus grand que le contenu** laisse une bande vide en
   bas. Dimensionner les cellules, pas la grille.
5. **`ImageDraw` de PIL écrit l'alpha au lieu de le mélanger.** Toute forme translucide doit
   être dessinée sur une couche RGBA séparée puis composée, sinon elle perce un trou.

Deux autres, spécifiques à Godot 4.7 : `StyleBoxTexture` n'a pas de `shadow_color` (propriété
de `StyleBoxFlat`), et un `Control` racine avec enfants ancrés exige lui aussi
`set_anchors_and_offsets_preset`.

---

## 8. Lancer, construire, vérifier

```bash
# jouer (serveur local + navigateur)
JOUER.bat
# ou
python tools/jouer.py

# réexporter après une modification
godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . \
  --export-release "Web" build/web/index.html

# vérifier un écran sans GPU (serveur + Chrome logiciel + capture)
bash tools/capture.sh /tmp/ecran.png "?cine=1&nocadeau=1" 26000
bash tools/capture.sh /tmp/ile.png "?cine=1&nocadeau=1" 26000 "230,872"
```

Paramètres d'URL : `?ecran=ile|fouille|boutique|passe|classe|cadeau`, `?cine=1` (saute la
cinématique), `?nocadeau=1` (saute le cadeau du jour).

**`file://` ne fonctionne pas** pour un export Godot web : le moteur doit récupérer
`index.wasm` et `index.pck` par HTTP.

---

## 9. Ce qui reste à faire

Par ordre d'impact réel, pas par ordre de difficulté.

### Priorité 1 — Jouer 20 minutes et mesurer (à faire par le porteur du projet)
Aucune session longue n'a été jouée. Tout repose sur des captures. Les questions à trancher :
l'énergie bloque-t-elle trop vite ? Les commandes sont-elles livrables ? La première
construction arrive-t-elle assez tôt ? Sans cette mesure, tout le reste est de la décoration.

### Priorité 2 — Le « juice »
Une fusion ne produit aujourd'hui qu'un toast et un rebond. Il manque : nombre flottant
`+12` à la livraison, éclat de particules à la fusion, pulsation de la case, secousse légère
à l'encaissement, transition d'entrée d'écran. C'est peu de code et c'est ce qui sépare un
prototype d'un jeu.

### Priorité 3 — Le poids — FAIT (07/11)
Sous-ensembles générés par `outils/sous_ensemble_polices.py` à partir des caractères
réellement utilisés : **pck 42 → 19,3 Mo**. Les polices complètes (40 Mo) vivent dans
`fonts/source/` avec `.gdignore` — jamais exportées. `ui_kit.gd` charge les sous-ensembles.

### Priorité 4 — L'onboarding
Un nouveau joueur arrive sur une grille sans savoir quoi faire. Trois étapes guidées :
taper un générateur, fusionner deux objets, livrer une commande. Le champ `State.d["tuto"]`
existe déjà et n'est pas utilisé.

### Priorité 5 — Finir la carte
Les 24 bâtiments et 6 activités ont désormais chacun une illustration posée sur les
parcelles (fallback emoji si un PNG manque). Reste : formes de terrain irrégulières
(en L, en trapèze), décors de sol autour des parcelles construites, front de déblocage
visible (herbes folles sur les parcelles verrouillées).

### Priorité 6 — Équilibrage et méta
- Progression longue : au-delà de la prospérité, il n'y a pas d'objectif.
- Les commandes montent en niveau avec le joueur (`2 + niveau/4`) mais rien ne pousse à
  monter de niveau.
- Pas de prestige, pas de collection à compléter, pas de raison de revenir au jour 30.

### Priorité 7 — Commercialisation
Voir `DIRECTION_ARTISTIQUE.md` §12. En résumé : cohérence des icônes, résolutions pour les
stores, bande-annonce, et surtout une session de jeu qui tienne debout.

---

## 10. Risques

| Risque | Gravité | Parade |
|---|---|---|
| Économie non testée → jeu injouable ou ennuyeux | **Élevée** | Priorité 1, avant tout le reste |
| 68 Mo à télécharger sur mobile | Moyenne | Sous-ensembler les polices (P3) |
| Cohérence des 35 icônes générées indépendamment | Moyenne | Gabarit de prompt unique, revue visuelle par planche |
| Dépendance à une API tierce pour régénérer un asset | Faible | **Supprimée** : la génération passe par les notebooks molab (GPU gratuit, aucun compte d'API) ; les assets sont versionnés, le jeu tourne sans régénération |
| Ressemblance avec le jeu original | Faible | Mécaniques seules, aucun asset copié, personnage original |
| Un seul développeur, quatre pistes en parallèle | Élevée | Un chantier à la fois |

---

## 11. Journal des décisions

| Date | Décision | Raison |
|---|---|---|
| 02/11 | Cible navigateur plutôt que natif | Pas de GPU ; WebGL logiciel fonctionne partout |
| 02/11 | Emoji remplacés par des illustrations IA | Les emojis ne rendent pas de façon fiable sur le web |
| 06/11 | Style cel-anime 1984-89 (chibi cozy) partout | Direction assumée : contours d'encre bruns, aplats plats — lisible et différenciant |
| 06/11 | Génération unifiée sur les notebooks molab | Cohérence de style : un seul lieu pour les prompts, ni Agnes ni Pollinations |
| 02/11 | Plateau 7×10, générateurs sur la grille | Fidélité au jeu de référence |
| 02/11 | Carte peinte plutôt que grille de cases | Fidélité au jeu de référence |
| 02/11 | Butin par bâtiment plutôt que revenu global | Donne une raison de revenir sur la carte |
| 02/11 | Roue + 天赐好礼 + énergie de la fouille | L'original recharge l'énergie par des activités, pas par l'achat |
| 02/11 | Refus de décompiler le `.wxapkg` | Code et art propriétaires ; rien d'exploitable légalement |
