# Génération d’images sur Molab / marimo

## Notebook prêt à importer

`molab_image_lab.py` est un notebook marimo autonome pour générer des illustrations du jeu.
Il utilise Diffusers et le modèle `Lykon/dreamshaper-xl-v2-turbo` ; Torch et le GPU sont
fournis par Molab. Le notebook ne charge pas les poids pendant son ouverture : le clic sur
**Générer une image** déclenche le chargement différé puis l’inférence. Le modèle est mis en
cache mémoire avec `mo.cache` pendant la session afin de ne pas le recharger à chaque image.

### Import dans Molab

1. Ouvrir `https://molab.marimo.io/notebooks` et cliquer **Import notebook**.
2. Importer `outils/molab_image_lab.py` depuis le sélecteur de fichiers.
3. Dans **Notebook settings → Compute**, choisir le GPU **RTX Pro 6000**.
4. Attendre la résolution des dépendances inscrites dans les métadonnées PEP 723. Molab
   utilise le gestionnaire de paquets marimo/uv ; Torch est déjà fourni dans l’image Molab.
5. Choisir un type d’image, préciser l’objet, puis lancer une génération avec le bouton.
   La première génération télécharge les poids du modèle ; les suivantes réutilisent le cache
   de la session.
6. Enregistrer l’image avec **Télécharger le PNG**. Les fichiers produits dans le système de
   fichiers du notebook sont éphémères ; télécharger les livrables avant la fin de session.

## Particularités vérifiées de Molab

- Les notebooks tournent dans des sandboxes marimo avec 4 CPU et 32 Go de RAM par défaut.
  L’option GPU ajoute un NVIDIA RTX Pro 6000 Blackwell de 96 Go VRAM.
- Les sessions peuvent durer jusqu’à 12 h ; une sandbox inactive plus de 90 min est arrêtée.
- Les cellules marimo sont réactives et s’exécutent selon leurs dépendances. Une cellule qui
  charge les poids dès l’ouverture peut retarder l’affichage du notebook ; ce notebook garde
  le chargement du modèle derrière le bouton de génération.
- Les dépendances déclarées sont installées par marimo. Les fichiers conservés dans Molab
  doivent être téléversés par le panneau Files, ou placés dans le cache persistant marimo.
  `mo.cache` conserve ici le pipeline en mémoire pour la session ; le PNG est exporté par le
  contrôle `mo.download`, qui le transmet au navigateur de l’utilisateur.
- Les notebooks Molab sont publics par URL mais non découvrables par défaut. Ne pas y placer
  de secrets, jetons ou fichiers privés qui ne sont pas nécessaires à la génération.
- L’usage de Molab est gratuit dans le cadre d’un usage raisonnable ; les restrictions
  officielles interdisent notamment l’exposition de services/proxies et l’exécution de
  charges de calcul non interactives. Ce notebook fonctionne comme une interface interactive.

## Modèle et licence

La fiche Hugging Face du modèle utilisé le déclare sous la licence `openrail++` et fournit un
exemple Diffusers CUDA. Vérifier le texte de licence complet et ses restrictions d’usage avant
la distribution commerciale du jeu ; conserver cette référence dans le registre des assets :
<https://huggingface.co/Lykon/dreamshaper-xl-v2-turbo>.

## Sources officielles consultées

- Molab, calcul, GPU, durée des sessions et fonctionnement marimo :
  <https://docs.marimo.io/guides/molab/>
- Installation des dépendances dans l’éditeur marimo :
  <https://docs.marimo.io/guides/package_management/installing_packages/>
- Cache mémoire et persistant (`mo.cache`, `mo.persistent_cache`) :
  <https://docs.marimo.io/api/caching/>
- Restrictions d’utilisation Molab : <https://marimo.io/pages/molab/restrictions>
- Modèle et exemple d’inférence :
  <https://huggingface.co/Lykon/dreamshaper-xl-v2-turbo>
