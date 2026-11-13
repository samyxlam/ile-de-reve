# data.gd — Toutes les données de jeu (chaînes d'objets, générateurs, paliers, zones, tâches, i18n).
# Il n'y a AUCUN art externe : chaque objet est rendu par un emoji + une couleur de chaîne.
# Pour remplacer par de vrais sprites : ajouter une clé "tex" (chemin de texture) dans l'entrée
# de l'objet et modifier ui_kit.gd::_affiche_objet() — le reste du code ne dépend pas de ça.
extends Node
# Autoload : "Data"

const BOARD_COLS := 7
const BOARD_ROWS := 10
const LEVELS_PER_CHAIN := 6
const MAX_ORDER_SLOTS := 3
const EVENT_DURATION_DAYS := 14

# Production : dans le jeu de référence, les générateurs sont des objets POSÉS SUR LE PLATEAU
# qu'on tape pour produire, avec des charges puis une recharge. Pas une barre d'outils.
const GEN_CHARGES := 5
const GEN_RECHARGE := 45.0        # secondes pour retrouver ses charges
# Position de départ des 5 générateurs (index de case), étalés sur les deux premières rangées.
const GEN_POSITIONS := [0, 2, 4, 7, 9]

# ---------------------------------------------------------------- chaînes d'objets
# Chaque chaîne : 6 niveaux. emoji = glyphe affiché, col = couleur de fond de la pastille.
# lore = description courte (affichée dans la fiche objet, en bas du plateau).
const CHAINS := {
	"bois": {
		"couleur": Color("#ead9b0"),
		"bord": Color("#b98c4a"),
		"niveaux": [
			{"emoji": "🪵", "fr": "Bois d'échouage", "en": "Driftwood", "zh": "漂木",
				"lore_fr": "Porté par la marée, propre et solide.", "lore_en": "Carried ashore by the tide.", "lore_zh": "潮水送来的木材。",
				"lore_fr2": "Assez sec pour brûler.", "lore_en2": "Dry enough to burn.", "lore_zh2": "干燥易燃。"},
			{"emoji": "🚪", "fr": "Planche rabotée", "en": "Planed plank", "zh": "刨板",
				"lore_fr": "Lisse au toucher, prête à l'emploi.", "lore_en": "Smooth and ready to use.", "lore_zh": "光滑好用。"},
			{"emoji": "🪟", "fr": "Traverse", "en": "Crossbeam", "zh": "横梁",
				"lore_fr": "Colonne vertébrale des charpentes.", "lore_en": "The spine of any frame.", "lore_zh": "木架主骨。"},
			{"emoji": "🪜", "fr": "Échafaudage", "en": "Scaffold", "zh": "棚架",
				"lore_fr": "Sert à bâtir haut, puis disparaît.", "lore_en": "Built high, taken down after.", "lore_zh": "建高层用。"},
			{"emoji": "🏠", "fr": "Cabane de chantier", "en": "Work hut", "zh": "工棚",
				"lore_fr": "Un toit pour les artisans.", "lore_en": "A roof for the workers.", "lore_zh": "匠人的屋顶。"},
			{"emoji": "🏯", "fr": "Portique de temple", "en": "Temple gate", "zh": "牌楼",
				"lore_fr": "L'œuvre que l'on gravit.", "lore_en": "A masterpiece to climb toward.", "lore_zh": "登临之作。"},
		],
	},
	"ferme": {
		"couleur": Color("#dcecc4"),
		"bord": Color("#89a85c"),
		"niveaux": [
			{"emoji": "🌱", "fr": "Graine du matin", "en": "Morning seed", "zh": "晨露种子",
				"lore_fr": "À peine semée, déjà pressée.", "lore_en": "Just sown, already eager.", "lore_zh": "刚种下就发芽。"},
			{"emoji": "🌿", "fr": "Pousse tendre", "en": "Tender sprout", "zh": "嫩芽",
				"lore_fr": "Verte comme une rumeur de printemps.", "lore_en": "Green as a rumor of spring.", "lore_zh": "绿意初绽。"},
			{"emoji": "🥕", "fr": "Carotte sucrée", "en": "Sweet carrot", "zh": "甜萝卜",
				"lore_fr": "Craque sous la dent.", "lore_en": "Snaps when you bite it.", "lore_zh": "脆甜可口。"},
			{"emoji": "🍅", "fr": "Tomate du clocher", "en": "Bell-tower tomato", "zh": "灯笼番茄",
				"lore_fr": "Ronde comme une lanternette.", "lore_en": "Round as a little lantern.", "lore_zh": "圆如小灯笼。"},
			{"emoji": "🧺", "fr": "Panier récolté", "en": "Harvest basket", "zh": "丰收菜篮",
				"lore_fr": "Plus lourd qu'il n'y paraît.", "lore_en": "Heavier than it looks.", "lore_zh": "沉甸甸的。"},
			{"emoji": "🍖", "fr": "Festin de fête", "en": "Feast platter", "zh": "盛宴",
				"lore_fr": "On en parle déjà dans le village.", "lore_en": "The whole village talks about it.", "lore_zh": "全村闻名。"},
		],
	},
	"forge": {
		"couleur": Color("#f4dcc8"),
		"bord": Color("#c07a54"),
		"niveaux": [
			{"emoji": "🪨", "fr": "Pierre d'atelier", "en": "Shop stone", "zh": "锻石",
				"lore_fr": "Passée au feu, elle devient fer.", "lore_en": "Held in fire, it becomes iron.", "lore_zh": "千锤成铁。"},
			{"emoji": "⛓️", "fr": "Chaînette", "en": "Small chain", "zh": "细铁链",
				"lore_fr": "Chaque maillon raconte une forge.", "lore_en": "Each link tells of a forge.", "lore_zh": "环环皆锤炼。"},
			{"emoji": "🔨", "fr": "Marteau de maître", "en": "Master hammer", "zh": "师锤",
				"lore_fr": "Rythme la journée du village.", "lore_en": "Sets the village rhythm.", "lore_zh": "村中日课。"},
			{"emoji": "⚒️", "fr": "Enclume octogonale", "en": "Anvil", "zh": "八角铁砧",
				"lore_fr": "Épouse les coups sans broncher.", "lore_en": "Takes the blows without a word.", "lore_zh": "任敲不语。"},
			{"emoji": "🏮", "fr": "Lanterne de forge", "en": "Forge lantern", "zh": "铜灯",
				"lore_fr": "Garde la fonderie éveillée.", "lore_en": "Keeps the furnace awake.", "lore_zh": "守炉不眠。"},
			{"emoji": "🗡️", "fr": "Lame rituelle", "en": "Ritual blade", "zh": "灵剑",
				"lore_fr": "Forgée pour la gardienne de l'île.", "lore_en": "Forged for the island's keeper.", "lore_zh": "为守护者而铸。"},
		],
	},
	"tissu": {
		"couleur": Color("#e5d9f0"),
		"bord": Color("#9a7fbe"),
		"niveaux": [
			{"emoji": "🧵", "fr": "Fil de soie", "en": "Silk thread", "zh": "丝线",
				"lore_fr": "Fin comme la première pluie.", "lore_en": "Fine as the first rain.", "lore_zh": "细若初雨。"},
			{"emoji": "🪢", "fr": "Nœud de chance", "en": "Lucky knot", "zh": "祥结",
				"lore_fr": "On l'accroche aux portes blanches.", "lore_en": " Hung on pale doors.", "lore_zh": "挂于门户。"},
			{"emoji": "🧶", "fr": "Pelote multicolore", "en": "Yarn ball", "zh": "彩线球",
				"lore_fr": "Dévidée jamais, reprise toujours.", "lore_en": "Never undone for good.", "lore_zh": "反覆绕理。"},
			{"emoji": "🧣", "fr": "Étoffe d'hiver", "en": "Winter cloth", "zh": "冬布",
				"lore_fr": "Contient une saudence entière.", "lore_en": "Holds a whole warm month.", "lore_zh": "裹着一月暖阳。"},
			{"emoji": "👘", "fr": "Robe de festival", "en": "Festival robe", "zh": "锦衣",
				"lore_fr": "Portée une nuit, rêvée toute l'année.", "lore_en": "Worn one night, dreamt all year.", "lore_zh": "一夜华彩。"},
			{"emoji": "🎏", "fr": "Grande bannière", "en": "Great banner", "zh": "幡旗",
				"lore_fr": "Symbole du port reconstruit.", "lore_en": "Symbol of the rebuilt port.", "lore_zh": "重港之号。"},
		],
	},
	"ceramique": {
		"couleur": Color("#d8ecf0"),
		"bord": Color("#5f9fb2"),
		"niveaux": [
			{"emoji": "🫗", "fr": "Eau de source", "en": "Spring water", "zh": "清泉",
				"lore_fr": "Descend de la colline du rosier.", "lore_en": "Comes down the rose hill.", "lore_zh": "山泉下淌。"},
			{"emoji": "🍵", "fr": "Tasse d'hôte", "en": "Guest cup", "zh": "客盏",
				"lore_fr": "Arrose les conversations.", "lore_en": "Lubricates conversation.", "lore_zh": "润谈之杯。"},
			{"emoji": "🫖", "fr": "Théière doube", "en": "Double teapot", "zh": "双陶茶壶",
				"lore_fr": "Retient tout l'arôme du jardin.", "lore_en": "Keeps the garden's whole aroma.", "lore_zh": "存尽满园香。"},
			{"emoji": "🍶", "fr": "Cruche d'étain", "en": "Tin jug", "zh": "锡壶",
				"lore_fr": "L'invité surprise des banquets.", "lore_en": "The surprise guest of banquets.", "lore_zh": "宴上客卿。"},
			{"emoji": "🏺", "fr": "Vase ancien", "en": "Ancient vase", "zh": "古瓶",
				"lore_fr": "Pulit des générations silencieuses.", "lore_en": "Kept for silent generations.", "lore_zh": "静世珍藏。"},
			{"emoji": "🪔", "fr": "Lampe au trésor", "en": "Treasure lamp", "zh": "宝灯",
				"lore_fr": "On y voit son plus profond vœu.", "lore_en": "You see your deepest wish in it.", "lore_zh": "照见心愿。"},
		],
	},
}

# ---------------------------------------------------------------- générateurs (producteurs)
const GENERATORS := {
	"bois":       {"fr": "Bûcheron", "en": "Woodcutter", "zh": "樵夫", "emoji": "🪓", "delai": 2.0},
	"ferme":      {"fr": "Potager",   "en": "Kitchen garden", "zh": "菜园", "emoji": "🚜", "delai": 2.4},
	"forge":      {"fr": "Forge",     "en": "Forge", "zh": "铁铺", "emoji": "🔥", "delai": 2.6},
	"tissu":      {"fr": "Atelier",   "en": "Weaving shop", "zh": "机坊", "emoji": "🧺", "delai": 2.8},
	"ceramique":  {"fr": "Four",      "en": "Kiln", "zh": "瓷窑", "emoji": "🍶", "delai": 3.0},
}

# ---------------------------------------------------------------- paliers du pass (points cumulés)
const PASS_PALIERS := [60, 150, 280, 450, 680, 950, 1280, 1650, 2100, 2600]  # 0 index → palier 1

# ---------------------------------------------------------------- zones de l'île
const ZONES := {
	"printemps": {
		"fr": "Printemps", "en": "Spring", "zh": "春", "emoji": "🌸",
		"prosperite_requise": 0,
		"batiments": [
			{"cle": "spr1", "emoji": "🏠", "fr": "Pavillon des voix", "en": "Voice pavilion", "zh": "留听阁",
				"coins": 60,  "feuilles": 0, "temps": 40,  "prosperite": 4},
			{"cle": "spr2", "emoji": "🌸", "fr": "Cerisier ancien", "en": "Old cherry", "zh": "古樱树",
				"coins": 140, "feuilles": 2, "temps": 70,  "prosperite": 6},
			{"cle": "spr3", "emoji": "🪑", "fr": "Kiosque de brume", "en": "Mist kiosk", "zh": "雾亭",
				"coins": 240, "feuilles": 3, "temps": 100, "prosperite": 8},
			{"cle": "spr4", "emoji": "🧺", "fr": "Étal du commerce", "en": "Market stall", "zh": "货摊",
				"coins": 400, "feuilles": 4, "temps": 130, "prosperite": 12},
			{"cle": "spr5", "emoji": "🫖", "fr": "Maison de thé", "en": "Tea house", "zh": "茶室",
				"coins": 640, "feuilles": 6, "temps": 170, "prosperite": 17},
			{"cle": "spr6", "emoji": "🎏", "fr": "Grand relais", "en": "Great waystop", "zh": "大驿站",
				"coins": 950, "feuilles": 8, "temps": 220, "prosperite": 24},
		],
	},
	"ete": {
		"fr": "Été", "en": "Summer", "zh": "夏", "emoji": "🪷",
		"prosperite_requise": 30,
		"batiments": [
			{"cle": "sum1", "emoji": "🛖", "fr": "Hutte de lotus", "en": "Lotus hut", "zh": "莲舍",
				"coins": 1200, "feuilles": 8, "temps": 200, "prosperite": 26},
			{"cle": "sum2", "emoji": "🚣", "fr": "Barque fleurie", "en": "Flower boat", "zh": "花舟",
				"coins": 1800, "feuilles": 10, "temps": 240, "prosperite": 30},
			{"cle": "sum3", "emoji": "🌉", "fr": "Pont de jade", "en": "Jade bridge", "zh": "玉桥",
				"coins": 2400, "feuilles": 14, "temps": 280, "prosperite": 36},
			{"cle": "sum4", "emoji": "🏮", "fr": "Allée de lanternes", "en": "Lantern alley", "zh": "灯街",
				"coins": 3200, "feuilles": 16, "temps": 320, "prosperite": 42},
			{"cle": "sum5", "emoji": "🍬", "fr": "Boutique de sucre", "en": "Sugar shop", "zh": "糖坊",
				"coins": 4100, "feuilles": 20, "temps": 360, "prosperite": 48},
			{"cle": "sum6", "emoji": "⛵", "fr": "Bassin d'été", "en": "Summer basin", "zh": "夏舫",
				"coins": 5200, "feuilles": 24, "temps": 420, "prosperite": 56},
		],
	},
	"automne": {
		"fr": "Automne", "en": "Autumn", "zh": "秋", "emoji": "🍁",
		"prosperite_requise": 80,
		"batiments": [
			{"cle": "aut1", "emoji": "🍁", "fr": "Érable doré", "en": "Golden maple", "zh": "金枫",
				"coins": 6400, "feuilles": 26, "temps": 440, "prosperite": 60},
			{"cle": "aut2", "emoji": "🪡", "fr": "Pavillon de tapisserie", "en": "Embroidery hall", "zh": "绣楼",
				"coins": 7800, "feuilles": 30, "temps": 460, "prosperite": 66},
			{"cle": "aut3", "emoji": "🥮", "fr": "Table du gâteau de lune", "en": "Moon-cake table", "zh": "月饼台",
				"coins": 9200, "feuilles": 36, "temps": 480, "prosperite": 72},
			{"cle": "aut4", "emoji": "🍷", "fr": "Cellar de lune", "en": "Moon cellar", "zh": "月窟",
				"coins": 11000, "feuilles": 40, "temps": 500, "prosperite": 80},
			{"cle": "aut5", "emoji": "🌠", "fr": "Tour d'observation", "en": "Watch tower", "zh": "观星塔",
				"coins": 13000, "feuilles": 46, "temps": 520, "prosperite": 88},
			{"cle": "aut6", "emoji": "🌇", "fr": "Musée du coucher", "en": "Sunset museum", "zh": "落霞馆",
				"coins": 15000, "feuilles": 52, "temps": 540, "prosperite": 96},
		],
	},
	"hiver": {
		"fr": "Hiver", "en": "Winter", "zh": "冬", "emoji": "❄️",
		"prosperite_requise": 160,
		"batiments": [
			{"cle": "win1", "emoji": "❄️", "fr": "Pavillon de neige", "en": "Snow pavilion", "zh": "雪亭",
				"coins": 17500, "feuilles": 56, "temps": 560, "prosperite": 100},
			{"cle": "win2", "emoji": "☃️", "fr": "Bonhomme de neige", "en": "Snow fellow", "zh": "雪人",
				"coins": 20000, "feuilles": 60, "temps": 580, "prosperite": 108},
			{"cle": "win3", "emoji": "🎿", "fr": "Poste de ski", "en": "Ski hut", "zh": "雪栈",
				"coins": 23000, "feuilles": 66, "temps": 600, "prosperite": 118},
			{"cle": "win4", "emoji": "🛷", "fr": "Ligne de luge", "en": "Sledge line", "zh": "雪橇道",
				"coins": 26000, "feuilles": 72, "temps": 620, "prosperite": 128},
			{"cle": "win5", "emoji": "🏮", "fr": "Fête de lanterne", "en": "Lantern fest", "zh": "灯会",
				"coins": 29000, "feuilles": 78, "temps": 640, "prosperite": 140},
			{"cle": "win6", "emoji": "🏰", "fr": "Palais d'hiver", "en": "Winter palace", "zh": "冬宫",
				"coins": 33000, "feuilles": 84, "temps": 700, "prosperite": 160},
		],
	},
}

# ---------------------------------------------------------------- carte de l'île
# L'île n'est plus une liste de cartes : c'est une grille de parcelles. Les quatre coins
# accueillent les mini-jeux, le reste se remplit des 24 bâtiments dans l'ordre des saisons.
const MAP_COLS := 5
const MAP_ROWS := 6
const MAP_ACTIVITES := [0, 4, 25, 29, 27, 5]  # cellules réservées aux mini-jeux (row-major)

# Retourne MAP_COLS*MAP_ROWS cellules : {type: "activite"|"batiment"|"vide", cle, palier}
# Le palier d'une parcelle = prospérité de base de sa saison + 3 par rang dans la saison,
# ce qui fait avancer le front de déblocage bâtiment par bâtiment.
func carte_ile() -> Array:
	var batiments: Array = []
	for zone in ZONES:
		var base: int = int(ZONES[zone]["prosperite_requise"])
		var i := 0
		for b in ZONES[zone]["batiments"]:
			batiments.append({"cle": b["cle"], "zone": zone, "palier": base + i * 3})
			i += 1
	var out: Array = []
	var k := 0
	for idx in range(MAP_COLS * MAP_ROWS):
		if MAP_ACTIVITES.has(idx):
			out.append({"type": "activite", "activite": MAP_ACTIVITES.find(idx)})
		elif k < batiments.size():
			out.append({"type": "batiment", "cle": batiments[k]["cle"], "palier": int(batiments[k]["palier"])})
			k += 1
		else:
			out.append({"type": "vide"})
	return out

func batiment_par_cle(cle: String) -> Dictionary:
	for zone in ZONES:
		for b in ZONES[zone]["batiments"]:
			if b["cle"] == cle:
				return b
	return {}

# ---------------------------------------------------------------- tâches quotidiennes (6 h comme le jeu source)
const TASKS := [
	{"id": "t_coins",  "fr": "Gagner 200 pièces", "en": "Earn 200 coins", "zh": "获取200个铜钱",
		"but": {"type": "coins_earned", "pallier": 200}, "points": 180, "coins": 100, "feuilles": 0},
	{"id": "t_merges", "fr": "Réaliser 30 fusions", "en": "Do 30 merges", "zh": "完成30次合成",
		"but": {"type": "merges", "pallier": 30}, "points": 120, "coins": 80, "feuilles": 1},
	{"id": "t_orders", "fr": "Livrer 5 commandes", "en": "Deliver 5 orders", "zh": "交付5个订单",
		"but": {"type": "orders", "pallier": 5}, "points": 215, "coins": 140, "feuilles": 2},
	{"id": "t_find",   "fr": "Terminer 1 fouille", "en": "Finish 1 search", "zh": "完成1次寻物",
		"but": {"type": "hidden", "pallier": 1}, "points": 300, "coins": 200, "feuilles": 3},
]

# ---------------------------------------------------------------- fouilles (objets cachés)
const FOUILLES := [
	{"id": "f1", "fr": "Marché du matin", "en": "Morning market", "zh": "晨市", "points": 150, "feuilles": 1, "coins": 60, "energie": 25, "delai": 60.0},
	{"id": "f2", "fr": "Quai des barques", "en": "Boat wharf", "zh": "船埠", "points": 260, "feuilles": 2, "coins": 120, "energie": 40, "delai": 90.0},
	{"id": "f3", "fr": "Jardin des lanternes", "en": "Lantern garden", "zh": "灯园", "points": 400, "feuilles": 3, "coins": 200, "energie": 60, "delai": 120.0},
]

# ---------------------------------------------------------------- roue de la fortune
# Source d'énergie gratuite, comme les activités du jeu de référence : on ne paie pas,
# on attend. Huit secteurs, une rotation toutes les 30 minutes.
const ROUE := [
	{"emoji": "⚡", "energie": 20, "coins": 0,   "feuilles": 0, "poids": 22},
	{"emoji": "🪙", "energie": 0,  "coins": 60,  "feuilles": 0, "poids": 16},
	{"emoji": "⚡", "energie": 40, "coins": 0,   "feuilles": 0, "poids": 14},
	{"emoji": "🍃", "energie": 0,  "coins": 0,   "feuilles": 2, "poids": 12},
	{"emoji": "⚡", "energie": 10, "coins": 0,   "feuilles": 0, "poids": 14},
	{"emoji": "🪙", "energie": 0,  "coins": 120, "feuilles": 0, "poids": 8},
	{"emoji": "🍃", "energie": 0,  "coins": 0,   "feuilles": 4, "poids": 6},
	{"emoji": "⚡", "energie": 60, "coins": 0,   "feuilles": 0, "poids": 8},
]

# ---------------------------------------------------------------- boutique (prototype : sans argent réel)
# prix_type : "coins" → payables ; "iap" → affichés comme dans l'original, bouton factice.

# ---------------------------------------------------------------- chaînes par clé pour i18n
# -------------------------------------------------------------- langue
const LANGUES := ["fr", "en", "zh"]
const LANGUE_LIBELLE := {"fr": "Français", "en": "English", "zh": "中文"}

var langue := "fr"

func t(fr: String, en: String, zh: String) -> String:
	match langue:
		"en": return en
		"zh": return zh
		_: return fr

func nom_objet(id: String) -> String:
	if ITEMS.has(id):
		var e: Dictionary = ITEMS[id]
		return t(e["fr"], e["en"], e["zh"])
	return id

func lore_objet(id: String) -> String:
	if ITEMS.has(id):
		var e: Dictionary = ITEMS[id]
		return t(e["lore_fr"], e["lore_en"], e["lore_zh"])
	return ""

# Remplie dans _ready : ITEMS["bois-1"] → toutes les infos + niveau.
var ITEMS := {}

func _ready() -> void:
	var r := RandomNumberGenerator.new()
	r.randomize()
	for chaine in CHAINS:
		var c: Dictionary = CHAINS[chaine]
		for niveau in range(1, LEVELS_PER_CHAIN + 1):
			var n: Dictionary = c["niveaux"][niveau - 1]
			var infos := {
				"id": "%s-%d" % [chaine, niveau],
				"chaine": chaine, "niveau": niveau,
				"emoji": n["emoji"],
				"couleur": c["couleur"], "bord": c["bord"],
			}
			for k in ["fr", "en", "zh"]:
				infos[k] = n[k]
			infos["lore_fr"] = n.get("lore_fr", "")
			infos["lore_en"] = n.get("lore_en", "")
			infos["lore_zh"] = n.get("lore_zh", "")
			# Fallback : lore hérité du premier niveau si manquant.
			for k in ["lore_fr", "lore_en", "lore_zh"]:
				if infos[k] == "":
					infos[k] = c["niveaux"][0].get(k, "")
			ITEMS[infos["id"]] = infos

func niveau_max(chaine: String) -> int:
	return LEVELS_PER_CHAIN

func item_suivant(id: String) -> String:
	var it = ITEMS.get(id)
	if it == null: return ""
	var lvl: int = it["niveau"]
	if lvl >= LEVELS_PER_CHAIN: return ""
	return "%s-%d" % [it["chaine"], lvl + 1]

# Chemin de l'illustration générée pour un objet, ou "" si l'asset n'existe pas
# (le jeu retombe alors sur l'emoji, donc reste jouable sans les images).
func chemin_icone(id: String) -> String:
	var chemin := "res://assets/objets/%s.jpg" % id
	return chemin if ResourceLoader.exists(chemin) else ""

func chemin_icone_gen(chaine: String) -> String:
	var chemin := "res://assets/objets/gen-%s.jpg" % chaine
	return chemin if ResourceLoader.exists(chemin) else ""

# Illustration d'un bâtiment de l'île (assets/batiments/<cle>.png), ou "" si
# l'asset manque — les parcelles retombent alors sur l'emoji.
func chemin_batiment(cle: String) -> String:
	var chemin := "res://assets/batiments/%s.png" % cle
	return chemin if ResourceLoader.exists(chemin) else ""

# Illustration d'une activité de la carte (assets/activites/act_<i>.png).
func chemin_activite(i: int) -> String:
	var chemin := "res://assets/activites/act_%d.png" % i
	return chemin if ResourceLoader.exists(chemin) else ""
