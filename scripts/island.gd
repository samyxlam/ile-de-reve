# island.gd — Vue île : carte de parcelles, déblocage progressif, mini-jeux posés dessus.
# Chaque parcelle porte soit un bâtiment à construire (coût, durée, prospérité), soit un
# mini-jeu. Le front de déblocage avance avec la prospérité, parcelle par parcelle.
extends Control

const PassScript := preload("res://scripts/event_pass.gd")
const RankScript := preload("res://scripts/rank_board.gd")

const ACTIVITES := [
	{"emoji": "🔍", "fr": "彩色寻物", "en": "Scavenger hunt", "zh": "彩色寻物", "cible": "fouille"},
	{"emoji": "🌙", "fr": "月神节", "en": "Moon festival", "zh": "月神节", "cible": "passe"},
	{"emoji": "🏆", "fr": "筑景名录", "en": "Scenery rank", "zh": "筑景名录", "cible": "classe"},
	{"emoji": "🎁", "fr": "Cadeaux", "en": "Gifts", "zh": "礼品", "cible": "cadeau"},
	{"emoji": "🎡", "fr": "Roue de la fortune", "en": "Wheel of fortune", "zh": "幸运轮盘", "cible": "roue"},
	{"emoji": "🎊", "fr": "天赐好礼", "en": "Heavenly gift", "zh": "天赐好礼", "cible": "don"},
]

const COULEURS_ZONES := {
	"printemps": Color("#b6d48c"),
	"ete": Color("#8fd0c7"),
	"automne": Color("#e0b76a"),
	"hiver": Color("#aec6da"),
}

var main = null
var lbl_pro: Label = null
var bt_collecte: Button = null
var parcelles := {}          # idx -> Parcelle
var _sec := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var marg := MarginContainer.new()
	marg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	marg.add_theme_constant_override("margin_left", 6)
	marg.add_theme_constant_override("margin_right", 6)
	marg.add_theme_constant_override("margin_top", 6)
	marg.add_theme_constant_override("margin_bottom", 6)
	add_child(marg)
	var v := UiKit.vbox(6)
	marg.add_child(v)
	v.add_child(_entete())
	v.add_child(_carte())
	State.maj.connect(_rafraichir)
	_rafraichir()

# ---------------------------------------------------------------- en-tête
func _entete() -> PanelContainer:
	var ent := PanelContainer.new()
	ent.add_theme_stylebox_override("panel", UiKit.panneau_bois(14))
	var hb := UiKit.hbox(8)
	ent.add_child(hb)
	var retour := UiKit.bouton("←", UiKit.BOIS_CLAIR, UiKit.TEXT_CLAIR, 18, 40, 12)
	retour.custom_minimum_size.x = 46
	retour.pressed.connect(func(): main.vers_plateau())
	hb.add_child(retour)
	var portrait := TextureRect.new()
	portrait.texture = load("res://assets/sprites/insulaire_manga.png")
	portrait.custom_minimum_size = Vector2(38, 38)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(portrait)
	lbl_pro = UiKit.label("", 15, UiKit.PARCH, HORIZONTAL_ALIGNMENT_LEFT, true)
	lbl_pro.clip_text = true
	lbl_pro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_pro.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(lbl_pro)
	bt_collecte = UiKit.bouton("", UiKit.OR, UiKit.TEXT_CLAIR, 13, 40, 12)
	bt_collecte.custom_minimum_size.x = 118
	bt_collecte.pressed.connect(func():
		var n := State.collecter_tout_ile()
		if n > 0:
			Son.jouer("piece")
			UiKit.toast(Data.t("+%d 🪙 récoltés !" % n, "+%d 🪙 harvested!" % n, "收获 +%d 🪙！" % n), UiKit.OR)
			State.sauver()
		_rafraichir())
	hb.add_child(bt_collecte)
	return ent

# ---------------------------------------------------------------- la carte
# Les parcelles ne sont plus dans une grille : elles sont posées à des coordonnées
# fixes sur un terrain dessiné (mer, sable, rivière, chemins, arbres). Le resserrement
# des colonnes vers le haut et le bas donne la silhouette d'une île.
const TAILLE_PARCELLE := Vector2(106, 98)
const SCENE := Vector2(700, 1040)

func _positions() -> Array:
	var out: Array = []
	var r := RandomNumberGenerator.new()
	r.seed = 20261102
	for i in range(Data.MAP_COLS * Data.MAP_ROWS):
		var c := i % Data.MAP_COLS
		var row := i / Data.MAP_COLS
		var etroit := absf(float(row) - 2.5) / 2.5      # 0 au centre, 1 aux extrémités
		# Rangées impaires décalées d'une demi-colonne : c'est ce qui casse la grille.
		var decalage := 59.0 if row % 2 == 1 else 0.0
		var cx := 42.0 + c * 118.0 + decalage + (2.0 - float(c)) * 12.0 * etroit + r.randf_range(-6.0, 6.0)
		var cy := 54.0 + row * 168.0 + r.randf_range(-7.0, 7.0)
		out.append(Vector2(cx, cy))
	return out

func _carte() -> Control:
	var pan := PanelContainer.new()
	pan.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pan.add_theme_stylebox_override("panel", UiKit.panneau_bois(18))

	var centre := CenterContainer.new()
	pan.add_child(centre)
	var scene := Control.new()
	scene.custom_minimum_size = SCENE
	centre.add_child(scene)

	var terrain := Terrain.new()
	terrain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	terrain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene.add_child(terrain)

	var positions := _positions()
	terrain.positions = positions
	terrain.taille = TAILLE_PARCELLE
	var cellules := Data.carte_ile()
	var r := RandomNumberGenerator.new()
	r.seed = 77
	for idx in range(cellules.size()):
		var p := Parcelle.new()
		p.ile = self
		p.idx = idx
		p.cellule = cellules[idx]
		p.custom_minimum_size = TAILLE_PARCELLE
		p.size = TAILLE_PARCELLE
		p.pivot_offset = TAILLE_PARCELLE * 0.5
		p.position = positions[idx]
		# Légère rotation : c'est ce qui casse l'effet « grille ».
		p.rotation = r.randf_range(-0.10, 0.10)
		parcelles[idx] = p
		scene.add_child(p)
	return pan

func _rafraichir() -> void:
	lbl_pro.text = Data.t("Prospérité %d · +%d 🪙/min" % [State.prosperite_totale(), int(State.taux_ile_min())],
		"Prosperity %d · +%d 🪙/min" % [State.prosperite_totale(), int(State.taux_ile_min())],
		"繁荣值 %d · +%d 🪙/分" % [State.prosperite_totale(), int(State.taux_ile_min())])
	for idx in parcelles:
		parcelles[idx]._maj()

func _process(delta: float) -> void:
	_sec += delta
	if _sec < 1.0: return
	_sec = 0.0
	for idx in parcelles:
		parcelles[idx]._maj_chrono()
	if bt_collecte != null and is_instance_valid(bt_collecte):
		var gain := State.butin_total()
		var txt := Data.t("Récolter +%d 🪙" % gain, "Harvest +%d 🪙" % gain, "收获 +%d 🪙" % gain)
		if bt_collecte.text != txt:
			bt_collecte.text = txt
		bt_collecte.disabled = gain <= 0

# ---------------------------------------------------------------- interaction d'une parcelle
func ouvrir_parcelle(p) -> void:
	var cell: Dictionary = p.cellule
	if str(cell["type"]) == "activite":
		var a: Dictionary = ACTIVITES[int(cell["activite"])]
		match str(a["cible"]):
			"fouille": main._changer_ecran("fouille")
			"passe": PassScript.ouvrir(main)
			"classe": RankScript.ouvrir(main)
			"cadeau": main._ouvrir_cadeau()
			"roue": _modal_roue()
			"don": _modal_don()
		return
	if str(cell["type"]) == "vide":
		UiKit.toast(Data.t("Terrain libre : rien à bâtir ici.", "Free land: nothing to build here.", "空地：此处暂无建筑。"))
		return

	var cle: String = str(cell["cle"])
	var b := Data.batiment_par_cle(cle)
	if b.is_empty(): return
	if State.prosperite_totale() < int(cell["palier"]):
		UiKit.toast(Data.t("Prospérité %d requise (tu as %d)." % [int(cell["palier"]), State.prosperite_totale()],
			"Prosperity %d required (you have %d)." % [int(cell["palier"]), State.prosperite_totale()],
			"需要繁荣值 %d（当前 %d）。" % [int(cell["palier"]), State.prosperite_totale()]))
		return
	if State.batiment_construit(cle):
		var n := State.collecter_batiment(cle)
		if n > 0:
			Son.jouer("piece")
			UiKit.toast("+%d 🪙" % n, UiKit.OR)
			State.sauver()
			_rafraichir()
		else:
			UiKit.toast("%s · +%d 🏮" % [b[Data.langue], int(b["prosperite"])])
		return
	if State.batiment_en_chantier(cle):
		if State.collecter_chantier(b):
			Son.jouer("succes")
			UiKit.toast(Data.t("Construction terminée !", "Construction finished!", "建筑完工！"), UiKit.OR)
			State.sauver()
			_rafraichir()
		else:
			var reste := State.construction_fin_tts(cle) - Time.get_unix_time_from_system()
			UiKit.toast(Data.t("Encore %s de chantier." % UiKit.fmt_duree(reste),
				"%s left on site." % UiKit.fmt_duree(reste),
				"还需 %s。" % UiKit.fmt_duree(reste)))
		return
	_modal_construction(b)

# ---------------------------------------------------------------- roue de la fortune
# Source d'énergie gratuite : on ne paie pas, on attend 30 minutes entre deux tours.
func _modal_roue() -> void:
	var m := UiKit.modale(Data.t("Roue de la fortune", "Wheel of fortune", "幸运轮盘"), 560)
	get_tree().root.add_child.call_deferred(m["racine"])
	var c: VBoxContainer = m["contenu"]

	var cadre := CenterContainer.new()
	cadre.custom_minimum_size = Vector2(440, 440)
	# Enveloppe fixe : le disque tourne, la flèche non.
	var enveloppe := Control.new()
	enveloppe.custom_minimum_size = Vector2(440, 440)
	enveloppe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var disque = preload("res://scripts/roue.gd").new()
	disque.position = Vector2(10, 10)
	enveloppe.add_child(disque)
	disque.size = Vector2(420, 420)
	var fleche := UiKit.label("▼", 30, Color("#c0533c"), HORIZONTAL_ALIGNMENT_CENTER)
	fleche.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	fleche.offset_top = -14
	fleche.offset_bottom = 24
	fleche.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enveloppe.add_child(fleche)
	cadre.add_child(enveloppe)
	c.add_child(cadre)

	var etat := UiKit.label("", 14, Color("#8a6d3d"), HORIZONTAL_ALIGNMENT_CENTER)
	c.add_child(etat)
	var bouton := UiKit.bouton("", UiKit.OR, UiKit.TEXT_CLAIR, 18, 50)
	c.add_child(bouton)

	var rafraichir := func():
		if not is_instance_valid(bouton): return
		if State.roue_prete():
			bouton.text = Data.t("Tourner", "Spin", "转动")
			bouton.disabled = false
			etat.text = Data.t("Une rotation gratuite", "One free spin", "免费转动一次")
		else:
			bouton.text = UiKit.fmt_duree(State.roue_attente())
			bouton.disabled = true
			etat.text = Data.t("Prochaine rotation gratuite dans %s" % UiKit.fmt_duree(State.roue_attente()),
				"Next free spin in %s" % UiKit.fmt_duree(State.roue_attente()),
				"下次免费转动：%s" % UiKit.fmt_duree(State.roue_attente()))
	rafraichir.call()

	disque.fini.connect(func(i: int):
		var prix: Dictionary = State.tourner_roue(i)
		var txt := ""
		if int(prix["energie"]) > 0:
			txt = "+%d ⚡" % int(prix["energie"])
		elif int(prix["coins"]) > 0:
			txt = "+%d 🪙" % int(prix["coins"])
		else:
			txt = "+%d 🍃" % int(prix["feuilles"])
		Son.jouer("succes")
		UiKit.toast(txt, UiKit.OR)
		State.sauver()
		rafraichir.call())

	bouton.pressed.connect(func():
		if not State.roue_prete(): return
		bouton.disabled = true
		disque.tourner(State.tirer_secteur_roue()))

	var minuteur := Timer.new()
	minuteur.wait_time = 1.0
	minuteur.autostart = true
	minuteur.timeout.connect(func(): rafraichir.call())
	m["racine"].add_child(minuteur)

# ---------------------------------------------------------------- 天赐好礼 : gros cadeau minuté
func _modal_don() -> void:
	var m := UiKit.modale(Data.t("天赐好礼", "Heavenly gift", "天赐好礼"), 520)
	get_tree().root.add_child.call_deferred(m["racine"])
	var c: VBoxContainer = m["contenu"]
	c.add_child(UiKit.icone_emoji("🎊", 84))
	c.add_child(UiKit.label(Data.t("Toutes les 3 heures", "Every 3 hours", "每3小时一次"), 15, Color("#8a6d3d"), HORIZONTAL_ALIGNMENT_CENTER))
	for ligne in [["⚡", "+50"], ["🪙", "+200"]]:
		var h := UiKit.hbox(8)
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		h.add_child(UiKit.icone_emoji(str(ligne[0]), 26))
		h.add_child(UiKit.label(str(ligne[1]), 22, UiKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true))
		c.add_child(h)

	var etat := UiKit.label("", 13, Color("#8a6d3d"), HORIZONTAL_ALIGNMENT_CENTER)
	c.add_child(etat)
	var bouton := UiKit.bouton("", UiKit.VERT, UiKit.TEXT_CLAIR, 18, 50)
	c.add_child(bouton)

	var rafraichir := func():
		if not is_instance_valid(bouton): return
		if State.don_prete():
			bouton.text = Data.t("Réclamer", "Claim", "领取")
			bouton.disabled = false
			etat.text = Data.t("Cadeau disponible", "Gift available", "礼包可领取")
		else:
			bouton.text = UiKit.fmt_duree(State.don_attente())
			bouton.disabled = true
			etat.text = Data.t("Prochain cadeau dans %s" % UiKit.fmt_duree(State.don_attente()),
				"Next gift in %s" % UiKit.fmt_duree(State.don_attente()),
				"下个礼包：%s" % UiKit.fmt_duree(State.don_attente()))
	rafraichir.call()

	bouton.pressed.connect(func():
		if State.reclamer_don():
			Son.jouer("succes")
			UiKit.toast(Data.t("+50 ⚡  +200 🪙", "+50 ⚡  +200 🪙", "+50 ⚡  +200 🪙"), UiKit.OR)
			State.sauver()
			rafraichir.call())

	var minuteur := Timer.new()
	minuteur.wait_time = 1.0
	minuteur.autostart = true
	minuteur.timeout.connect(func(): rafraichir.call())
	m["racine"].add_child(minuteur)

func _modal_construction(b: Dictionary) -> void:
	var m := UiKit.modale(b[Data.langue], 520)
	get_tree().root.add_child.call_deferred(m["racine"])
	var c: VBoxContainer = m["contenu"]
	# Illustration du bâtiment si elle existe, sinon l'emoji.
	var visuel := Data.chemin_batiment(str(b["cle"]))
	if visuel != "":
		var illu := TextureRect.new()
		illu.texture = load(visuel)
		illu.custom_minimum_size = Vector2(96, 96)
		illu.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		illu.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		illu.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var centre := CenterContainer.new()
		centre.add_child(illu)
		c.add_child(centre)
	else:
		c.add_child(UiKit.icone_emoji(b["emoji"], 76))
	for l in [["🪙", str(b["coins"])], ["🍃", str(b["feuilles"])], ["⏱", UiKit.fmt_duree(b["temps"])], ["🏮", "+%d" % int(b["prosperite"])]]:
		var h := UiKit.hbox(6)
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		h.add_child(UiKit.icone_emoji(str(l[0]), 20))
		h.add_child(UiKit.label(str(l[1]), 17, UiKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true))
		c.add_child(h)
	var ok := UiKit.bouton(Data.t("Construire", "Build", "建造"), UiKit.VERT, UiKit.TEXT_CLAIR, 18, 50)
	ok.pressed.connect(func():
		if State.payer_construction(b):
			Son.jouer("construire")
			UiKit.toast(Data.t("Chantier lancé !", "Construction started!", "工程开始！"))
			State.sauver()
			UiKit.fermer(m["racine"])
			_rafraichir()
		else:
			Son.jouer("erreur")
			UiKit.toast(Data.t("Ressources insuffisantes.", "Not enough resources.", "资源不足。")))
	c.add_child(ok)

# ---------------------------------------------------------------- une parcelle
class Parcelle extends Button:
	var ile = null
	var idx := 0
	var cellule: Dictionary = {}
	var img: TextureRect = null    # illustration du bâtiment / de l'activité
	var icone: Label = null
	var nom: Label = null
	var badge: Label = null
	var _sig := ""

	func _init() -> void:
		custom_minimum_size = Vector2(128, 132)
		var v := UiKit.vbox(0)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		img = TextureRect.new()
		img.custom_minimum_size = Vector2(54, 54)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		img.visible = false
		v.add_child(img)
		icone = UiKit.label("", 34, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
		v.add_child(icone)
		nom = UiKit.label("", 11, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
		nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nom.max_lines_visible = 2
		v.add_child(nom)
		badge = UiKit.label("", 10, Color("#4a3a28"), HORIZONTAL_ALIGNMENT_CENTER)
		v.add_child(badge)
		UiKit.contenu_bouton(self, v, 4, 4)
		pressed.connect(func(): ile.ouvrir_parcelle(self))

	# Affiche l'illustration si elle existe, sinon l'emoji de secours.
	func _afficher_visuel(visuel: String, emoji: String) -> void:
		if visuel != "":
			img.texture = load(visuel)
			img.visible = true
			icone.text = ""
		else:
			img.visible = false
			icone.text = emoji

	func _maj() -> void:
		if ile == null: return
		var type: String = str(cellule["type"])
		if type == "activite":
			var a: Dictionary = ACTIVITES[int(cellule["activite"])]
			var sig := "A%d" % int(cellule["activite"])
			if sig == _sig: return
			_sig = sig
			add_theme_stylebox_override("normal", UiKit.panneau(Color("#f3e2b6"), Color("#c99a3f"), 14, 3))
			add_theme_stylebox_override("hover", UiKit.panneau(Color("#fbeecb"), Color("#c99a3f"), 14, 3))
			add_theme_stylebox_override("pressed", UiKit.panneau(Color("#e8d49c"), Color("#c99a3f"), 14, 3))
			_afficher_visuel(Data.chemin_activite(int(cellule["activite"])), str(a["emoji"]))
			nom.text = Data.t(a["fr"], a["en"], a["zh"])
			badge.text = Data.t("jouer", "play", "进入")
			badge.add_theme_color_override("font_color", Color("#8a6d3d"))
			return

		if type == "vide":
			if _sig == "V": return
			_sig = "V"
			add_theme_stylebox_override("normal", UiKit.panneau(Color("#cfdcae"), Color("#9db877"), 14, 2))
			add_theme_stylebox_override("hover", UiKit.panneau(Color("#d9e6bc"), Color("#9db877"), 14, 2))
			_afficher_visuel("", "🌿")
			nom.text = ""
			badge.text = ""
			return

		var cle: String = str(cellule["cle"])
		var b := Data.batiment_par_cle(cle)
		if b.is_empty(): return
		var zone: String = State.zone_cle_depuis_batiment(cle)
		var palier: int = int(cellule["palier"])
		var debloque: bool = State.prosperite_totale() >= palier
		var construit: bool = State.batiment_construit(cle)
		var chantier: bool = State.batiment_en_chantier(cle)
		var sig3 := "%s|%s|%s|%s" % [str(debloque), str(construit), str(chantier), zone]
		if sig3 == _sig: return
		_sig = sig3

		if not debloque:
			add_theme_stylebox_override("normal", UiKit.panneau(Color("#8d9a6c"), Color("#5f6b44"), 14, 2))
			add_theme_stylebox_override("hover", UiKit.panneau(Color("#97a476"), Color("#5f6b44"), 14, 2))
			_afficher_visuel("", "🔒")
			nom.text = b[Data.langue]
			badge.text = "🏮 %d" % palier
			badge.add_theme_color_override("font_color", Color("#f0f4e2"))
			return

		var coul: Color = COULEURS_ZONES.get(zone, Color("#b6d48c"))
		if construit:
			add_theme_stylebox_override("normal", UiKit.panneau(coul, coul.darkened(0.30), 14, 3))
			add_theme_stylebox_override("hover", UiKit.panneau(coul.lightened(0.06), coul.darkened(0.30), 14, 3))
			_afficher_visuel(Data.chemin_batiment(cle), str(b["emoji"]))
			nom.text = b[Data.langue]
			badge.text = "✔"
			badge.add_theme_color_override("font_color", UiKit.VERT_FONCE)
		elif chantier:
			add_theme_stylebox_override("normal", UiKit.panneau(Color("#f0e3c4"), Color("#b08a4a"), 14, 3))
			add_theme_stylebox_override("hover", UiKit.panneau(Color("#f7ecd2"), Color("#b08a4a"), 14, 3))
			_afficher_visuel("", "🏗")
			nom.text = b[Data.langue]
		else:
			add_theme_stylebox_override("normal", UiKit.panneau(Color("#eaf2d6"), coul.darkened(0.20), 14, 2))
			add_theme_stylebox_override("hover", UiKit.panneau(Color("#f3f8e4"), coul.darkened(0.20), 14, 2))
			_afficher_visuel(Data.chemin_batiment(cle), str(b["emoji"]))
			nom.text = b[Data.langue]
			badge.text = "🪙 %d" % int(b["coins"])
			badge.add_theme_color_override("font_color", Color("#8a6d3d"))

	func _maj_chrono() -> void:
		if cellule.is_empty() or str(cellule["type"]) != "batiment": return
		var cle: String = str(cellule["cle"])
		if State.batiment_construit(cle):
			# Bulle de butin : c'est le « bouton minuté » de la carte de référence.
			var butin := State.butin_batiment(cle)
			var t := ("🪙 +%d" % butin) if butin > 0 else "✔"
			if badge.text != t:
				badge.text = t
				badge.add_theme_color_override("font_color", UiKit.OR if butin > 0 else UiKit.VERT_FONCE)
			return
		if not State.batiment_en_chantier(cle): return
		var reste: float = State.construction_fin_tts(cle) - Time.get_unix_time_from_system()
		var txt := ("⏳ " + UiKit.fmt_duree(max(0.0, reste))) if reste > 0.0 else Data.t("Prêt !", "Ready!", "完成！")
		if badge.text != txt:
			badge.text = txt
			badge.add_theme_color_override("font_color", UiKit.ROUGE if reste > 0.0 else UiKit.VERT_FONCE)

# ---------------------------------------------------------------- décor de fond
# Terrain peint : mer, anneau de sable, île, chemins entre les parcelles, bosquets
# dans les marges. Les parcelles se posent par-dessus, à des coordonnées fixes.
class Terrain extends Control:
	var positions: Array = []
	var taille := Vector2(106, 98)

	func _contour(w: float, h: float, retrait: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		var cx := w * 0.5
		var cy := h * 0.5
		var rx := w * 0.48 + retrait
		var ry := h * 0.47 + retrait
		for i in 64:
			var a := TAU * i / 64.0
			var k := 1.0 + 0.05 * sin(a * 3.0 + 1.2) + 0.025 * cos(a * 5.0)
			pts.append(Vector2(cx + cos(a) * rx * k, cy + sin(a) * ry * k))
		return pts

	func _draw() -> void:
		var w := size.x
		var h := size.y
		# mer
		draw_rect(Rect2(0, 0, w, h), Color("#91b7c7"))
		# Rubans d'écume irréguliers : ils rendent la mer lisible sans texture lourde.
		for i in 13:
			var y := h * (0.025 + i * 0.078)
			var vague := PackedVector2Array()
			for j in 25:
				var x := w * float(j) / 24.0
				vague.append(Vector2(x, y + sin(float(j) * 0.52 + float(i) * 1.7) * (3.0 + float(i % 3))))
			draw_polyline(vague, Color("#d8e8e2", 0.28 if i % 2 == 0 else 0.15), 2.0 if i % 2 == 0 else 1.4, true)
			if i % 3 == 1:
				for j in range(3, 23, 5):
					var x := w * float(j) / 24.0
					draw_line(Vector2(x, y - 3.0), Vector2(x + 9.0, y - 3.0), Color("#f5eddb", 0.24), 1.4, true)
		# sable puis terre
		draw_colored_polygon(_contour(w, h, 21.0), Color("#d8c396"))
		draw_colored_polygon(_contour(w, h, 14.0), Color("#f0dfb6"))
		draw_colored_polygon(_contour(w, h, 0.0), Color("#83a965"))
		draw_colored_polygon(_contour(w, h, -20.0), Color("#a6c77d"))
		var liseresable := _contour(w, h, 13.0)
		liseresable.append(liseresable[0])
		draw_polyline(liseresable, Color("#fff0cc", 0.55), 2.0, true)

		# quelques sentiers sinueux, sans suivre la grille
		var sentier := PackedVector2Array()
		for i in 26:
			var t := i / 25.0
			sentier.append(Vector2(w * (0.10 + 0.80 * t) + sin(t * 7.0) * 26.0, h * (0.16 + 0.68 * t)))
		draw_polyline(sentier, Color("#78965b", 0.55), 17.0, true)
		draw_polyline(sentier, Color("#e3c996"), 12.0, true)
		draw_polyline(sentier, Color("#f4e4c1", 0.55), 2.0, true)

		# Bosquets variés : ombre, feuillage en trois tons et petites trouées lumineuses.
		var r := RandomNumberGenerator.new()
		r.seed = 5150
		for i in 42:
			var a := TAU * r.randf()
			var d := r.randf_range(0.86, 1.0)
			var p := Vector2(w * 0.5 + cos(a) * w * 0.47 * d, h * 0.5 + sin(a) * h * 0.46 * d)
			var rad := r.randf_range(8.0, 17.0)
			_dessiner_arbre(p, rad, i % 3)

		# Quelques fleurs et galets ponctuent la rive sans gêner les parcelles.
		for i in 27:
			var a := TAU * r.randf()
			var p := Vector2(w * 0.5 + cos(a) * w * r.randf_range(0.37, 0.43), h * 0.5 + sin(a) * h * r.randf_range(0.36, 0.42))
			if i % 3 == 0:
				draw_circle(p + Vector2(1, 2), 3.0, Color("#708a59", 0.45))
				draw_colored_polygon(_ellipse(p, 3.0, 2.0), Color("#d5c39d"))
			else:
				var petale := Color("#f6e5d3") if i % 2 == 0 else Color("#edc1ad")
				for j in 5:
					var angle := TAU * float(j) / 5.0
					draw_circle(p + Vector2(cos(angle), sin(angle)) * 3.2, 1.8, petale)
				draw_circle(p, 1.6, Color("#e5b550"))

		# étang au bord, côté droit
		var etang := Vector2(w * 0.86, h * 0.30)
		draw_circle(etang + Vector2(1, 4), 37.0, Color("#718e5c", 0.32))
		draw_circle(etang, 35.0, Color("#d9c896"))
		draw_circle(etang, 30.0, Color("#78a8b5"))
		draw_circle(etang + Vector2(-3, -3), 23.0, Color("#a9d0d2"))
		draw_arc(etang, 26.0, 3.55, 5.45, 24, Color("#edf0d5", 0.75), 2.0, true)
		for n in 3:
			var feuille := etang + Vector2(-15.0 + n * 13.0, 8.0 + (n % 2) * 8.0)
			draw_colored_polygon(_ellipse(feuille, 5.0, 2.0), Color("#739a64"))
			draw_circle(feuille, 2.0, Color("#f4dfb2"))

	func _dessiner_arbre(p: Vector2, rad: float, espece: int) -> void:
		var ombre := Vector2(2.0, 4.0)
		draw_colored_polygon(_ellipse(p + ombre, rad * 0.88, rad * 0.32), Color("#657c4f", 0.35))
		draw_rect(Rect2(p.x - 2.0, p.y - 1.0, 4.0, rad * 0.72), Color("#886144"))
		var feuillage := Color("#6f9659") if espece == 0 else (Color("#7d9f5e") if espece == 1 else Color("#719a70"))
		var clair := Color("#9dbc70") if espece != 2 else Color("#a9c487")
		draw_circle(p, rad, Color("#536e49"))
		draw_circle(p + Vector2(-rad * 0.08, -rad * 0.10), rad * 0.88, feuillage)
		draw_circle(p + Vector2(-rad * 0.26, -rad * 0.28), rad * 0.54, clair)
		draw_circle(p + Vector2(rad * 0.28, rad * 0.12), rad * 0.35, feuillage)
		draw_arc(p + Vector2(-rad * 0.04, -rad * 0.04), rad * 0.74, 3.35, 5.65, 20, Color("#d5df9a", 0.62), 1.4, true)

	func _ellipse(centre: Vector2, rayon_x: float, rayon_y: float) -> PackedVector2Array:
		var points := PackedVector2Array()
		for i in 20:
			var angle := TAU * float(i) / 20.0
			points.append(centre + Vector2(cos(angle) * rayon_x, sin(angle) * rayon_y))
		return points
