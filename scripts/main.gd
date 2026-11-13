# main.gd — Racine : barre de monnaies, rangée d'événements, navigation par onglets, modales système.
# Les écrans sont : plateau (fusion), ile (bâtiments), fouille (objets cachés).
extends Node

const BoardScript := preload("res://scripts/board.gd")
const IslandScript := preload("res://scripts/island.gd")
const PassScript := preload("res://scripts/event_pass.gd")
const RankScript := preload("res://scripts/rank_board.gd")
const ShopScript := preload("res://scripts/shop_ui.gd")

var ui: Control = null
var contenu: Control = null
var plateau = null
var ecran := "plateau"

var lbl_energie: Label = null
var lbl_energie_t: Label = null
var lbl_coins: Label = null
var lbl_feuilles: Label = null
var lbl_niveau: Label = null
var barre_xp: ProgressBar = null
var lbl_event: Label = null
var nav := {}                      # nom d'écran -> Button
var _seconde := 0.0

func _ready() -> void:
	Data.langue = State.langue_actuelle()
	get_window().theme = UiKit.theme()
	_construire()
	State.maj.connect(_rafraichir_barre)
	var p := _params()
	var mode: String = OS.get_environment("PROTO_SHOT")
	if mode == "" and p.has("ecran"):
		mode = str(p["ecran"])
	if mode != "":
		# PROTO_SHOT (natif) déclenche la capture ; ?ecran=… (web) ouvre juste l'écran.
		if OS.get_environment("PROTO_SHOT") != "":
			_mode_capture(mode)
		else:
			_ecran_depuis(mode)
	elif not p.has("cine") and not bool(State.d.get("cine_vue", false)):
		_lancer_cinematique()
	elif not p.has("nocadeau") and State.cadeau_du_jour_dispo():
		_ouvrir_cadeau()

func _lancer_cinematique() -> void:
	var Cine := load("res://scripts/cinematique.gd") as GDScript
	var cine = Cine.new()
	cine.main = self
	add_child(cine)

func _apres_cinematique() -> void:
	State.d["cine_vue"] = true
	State.sauver()
	if State.cadeau_du_jour_dispo():
		_ouvrir_cadeau()

# Paramètres passés dans l'URL du build web : index.html?ecran=ile&nocadeau=1
# Sur le web, OS.get_cmdline_args() est vide : seule location.search porte les paramètres.
func _params() -> Dictionary:
	var brut := ""
	if OS.has_feature("web"):
		brut = str(JavaScriptBridge.eval("location.search"))
	else:
		brut = " ".join(OS.get_cmdline_args() + OS.get_cmdline_user_args())
	var out := {}
	for morceau in brut.replace("?", " ").replace("&", " ").split(" ", false):
		if morceau.contains("="):
			out[morceau.get_slice("=", 0)] = morceau.get_slice("=", 1)
	return out

func _ecran_depuis(mode: String) -> void:
	match mode:
		"plateau", "ile", "fouille":
			_changer_ecran(mode)
		"boutique":
			ShopScript.ouvrir(self)
		"passe":
			PassScript.ouvrir(self)
		"classe":
			RankScript.ouvrir(self)
		"cadeau":
			_ouvrir_cadeau()

func T(fr: String, en: String, zh: String) -> String:
	return Data.t(fr, en, zh)

# ================================================================ construction UI
func _construire() -> void:
	if ui != null and is_instance_valid(ui):
		ui.queue_free()
	nav.clear()
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ui)
	var fond := ColorRect.new()
	fond.color = UiKit.PARCH
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(fond)

	var v := UiKit.vbox(0)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(v)

	# --- barre de monnaies
	var barre := PanelContainer.new()
	var sb := UiKit.panneau(UiKit.PARCH_FONCE, UiKit.BOIS_CLAIR, 0, 0)
	sb.shadow_color = Color(0, 0, 0, 0.18)
	sb.shadow_size = 6
	barre.add_theme_stylebox_override("panel", sb)
	var mb := MarginContainer.new()
	mb.add_theme_constant_override("margin_left", 8)
	mb.add_theme_constant_override("margin_right", 8)
	mb.add_theme_constant_override("margin_top", 5)
	mb.add_theme_constant_override("margin_bottom", 5)
	barre.add_child(mb)
	var hb := UiKit.hbox(6)
	mb.add_child(hb)

	hb.add_child(_puce_niveau())

	var pe := _puce("⚡")
	hb.add_child(pe[0])
	lbl_energie = pe[1]
	lbl_energie_t = UiKit.label("", 11, Color("#8a6d3d"))
	lbl_energie_t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(lbl_energie_t)

	var pc := _puce("🪙")
	hb.add_child(pc[0])
	lbl_coins = pc[1]
	var pf := _puce("🍃")
	hb.add_child(pf[0])
	lbl_feuilles = pf[1]

	var espace := Control.new()
	espace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	espace.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(espace)
	var langue_b := UiKit.bouton(State.langue_actuelle().to_upper(), UiKit.BOIS_CLAIR, UiKit.TEXT_CLAIR, 13, 30, 10)
	langue_b.custom_minimum_size.x = 52
	langue_b.pressed.connect(_cycle_langue)
	hb.add_child(langue_b)
	var reglages := UiKit.bouton("⚙", UiKit.BOIS_CLAIR, UiKit.TEXT_CLAIR, 13, 30, 10)
	reglages.custom_minimum_size.x = 38
	reglages.pressed.connect(func(): ShopScript.ouvrir(self))
	hb.add_child(reglages)
	v.add_child(barre)

	# --- rangée d'événements
	v.add_child(_rangee_events())

	# --- contenu d'écran
	contenu = Control.new()
	contenu.size_flags_vertical = Control.SIZE_EXPAND_FILL
	contenu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contenu.clip_contents = true
	v.add_child(contenu)
	_changer_ecran("plateau")

	# --- navigation
	v.add_child(_barre_nav())
	_maj_nav()

func _rangee_events() -> PanelContainer:
	var bx := PanelContainer.new()
	bx.add_theme_stylebox_override("panel", UiKit.panneau(UiKit.PARCH_FONCE, UiKit.BOIS_CLAIR, 10, 2))
	var hb := UiKit.hbox(6)
	bx.add_child(hb)
	var p := bouton_event("🌙", "")
	lbl_event = p.get_meta("lbl")
	p.pressed.connect(func(): PassScript.ouvrir(self))
	hb.add_child(p)
	var r := bouton_event("🏆", T("筑景名录", "Scenery Rank", "筑景名录"))
	r.pressed.connect(func(): RankScript.ouvrir(self))
	hb.add_child(r)
	var g := bouton_event("🎁", T("礼品", "Gifts", "礼品"))
	g.pressed.connect(func(): _ouvrir_cadeau())
	hb.add_child(g)
	_maj_event()
	return bx

func bouton_event(emoji: String, txt: String) -> Button:
	var b := UiKit.bouton("", UiKit.PARCH, UiKit.TEXT, 13, 34, 10)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size.x = 100
	var tb := UiKit.hbox(4)
	tb.alignment = BoxContainer.ALIGNMENT_CENTER
	tb.add_child(UiKit.icone_emoji(emoji, 22))
	var l := UiKit.label(txt, 13, UiKit.TEXT)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tb.add_child(l)
	b.set_meta("lbl", l)
	UiKit.contenu_bouton(b, tb)
	return b

func _puce(emoji: String) -> Array:
	var h := UiKit.hbox(3)
	h.add_child(UiKit.icone_emoji(emoji, 22))
	var l := UiKit.label("", 15, UiKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true)
	h.add_child(l)
	return [h, l]

func _puce_niveau() -> Control:
	var pan := PanelContainer.new()
	var sb := UiKit.panneau(UiKit.PARCH, UiKit.BOIS_CLAIR, 10, 2)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	pan.add_theme_stylebox_override("panel", sb)
	pan.custom_minimum_size = Vector2(88, 0)
	pan.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var v := UiKit.vbox(1)
	pan.add_child(v)
	lbl_niveau = UiKit.label("", 12, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER, true)
	v.add_child(lbl_niveau)
	barre_xp = ProgressBar.new()
	barre_xp.show_percentage = false
	barre_xp.custom_minimum_size = Vector2(0, 6)
	var bg := UiKit.panneau(Color("#d8c69e"), Color("#cbb17e"), 3, 1)
	var fg := UiKit.panneau(UiKit.OR, UiKit.OR.darkened(0.25), 3, 1)
	for s in [bg, fg]:
		s.content_margin_left = 0
		s.content_margin_right = 0
		s.content_margin_top = 0
		s.content_margin_bottom = 0
	barre_xp.add_theme_stylebox_override("background", bg)
	barre_xp.add_theme_stylebox_override("fill", fg)
	v.add_child(barre_xp)
	return pan

func _rafraichir_barre() -> void:
	_maj_energie()
	if lbl_coins != null: lbl_coins.text = str(State.coins())
	if lbl_feuilles != null: lbl_feuilles.text = str(State.feuilles())
	if lbl_niveau != null:
		lbl_niveau.text = "Nv %d" % int(State.d["niveau"])
	if barre_xp != null:
		barre_xp.max_value = max(1, State.xp_par_niveau())
		barre_xp.value = int(State.d["xp"])

func _maj_energie() -> void:
	if lbl_energie == null: return
	lbl_energie.text = "%d/%d" % [State.energie(), State.CAP_ENERGIE]
	if lbl_energie_t != null:
		var reste := State.temps_prochain_energie()
		lbl_energie_t.text = "" if reste <= 0.0 else "+1 " + UiKit.fmt_duree(reste)

func _maj_event() -> void:
	if lbl_event != null and is_instance_valid(lbl_event):
		lbl_event.text = T("月神节", "Moon Festival", "月神节") + " " + UiKit.fmt_duree(State.secondes_event_restantes())

func _process(delta: float) -> void:
	_seconde += delta
	if _seconde < 1.0: return
	_seconde = 0.0
	_maj_event()
	_maj_energie()

# ================================================================ navigation
func _barre_nav() -> PanelContainer:
	var pan := PanelContainer.new()
	var sb := UiKit.panneau(UiKit.PARCH_FONCE, UiKit.BOIS_CLAIR, 0, 0)
	sb.shadow_color = Color(0, 0, 0, 0.15)
	sb.shadow_size = 6
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	pan.add_theme_stylebox_override("panel", sb)
	var hb := UiKit.hbox(6)
	pan.add_child(hb)
	for e in [
		{"cle": "plateau", "emoji": "🧩", "fr": "Plateau", "en": "Board", "zh": "棋盘"},
		{"cle": "ile",     "emoji": "🏝", "fr": "Île",     "en": "Island", "zh": "海岛"},
		{"cle": "fouille", "emoji": "🔍", "fr": "Fouille", "en": "Search", "zh": "寻物"},
	]:
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 50)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var tb := UiKit.hbox(6)
		tb.alignment = BoxContainer.ALIGNMENT_CENTER
		tb.add_child(UiKit.icone_emoji(e["emoji"], 22))
		var l := UiKit.label(T(e["fr"], e["en"], e["zh"]), 14, UiKit.TEXT)
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tb.add_child(l)
		UiKit.contenu_bouton(b, tb)
		var cle: String = e["cle"]
		b.pressed.connect(func(): _changer_ecran(cle))
		nav[cle] = b
		hb.add_child(b)
	return pan

func _maj_nav() -> void:
	for cle in nav:
		var b: Button = nav[cle]
		if not is_instance_valid(b): continue
		var actif: bool = cle == ecran
		var bg: Color = UiKit.VERT_FONCE if actif else UiKit.PARCH
		var fg: Color = UiKit.TEXT_CLAIR if actif else UiKit.TEXT
		var bord: Color = UiKit.VERT_FONCE if actif else Color("#cbb17e")
		b.add_theme_stylebox_override("normal", UiKit.panneau(bg, bord, 12, 2))
		b.add_theme_stylebox_override("hover", UiKit.panneau(bg.lightened(0.08), bord, 12, 2))
		b.add_theme_stylebox_override("pressed", UiKit.panneau(bg.darkened(0.08), bord, 12, 2))
		_teinter(b, fg)

func _teinter(n: Node, coul: Color) -> void:
	if n is Label:
		(n as Label).add_theme_color_override("font_color", coul)
	for c in n.get_children():
		_teinter(c, coul)

# ================================================================ écrans
func _changer_ecran(nom: String) -> void:
	ecran = nom
	if contenu == null: return
	for c in contenu.get_children():
		contenu.remove_child(c)
		c.queue_free()
	plateau = null
	match nom:
		"plateau":
			plateau = BoardScript.new()
			plateau.main = self
			contenu.add_child(plateau)
		"ile":
			var ile = IslandScript.new()
			ile.main = self
			contenu.add_child(ile)
		"fouille":
			var FouilleScript := load("res://scripts/hidden_game.gd") as GDScript
			var fouille = FouilleScript.new()
			fouille.main = self
			contenu.add_child(fouille)
		_:
			pass
	_maj_nav()

func vers_plateau() -> void:
	_changer_ecran("plateau")

func vers_fouille() -> void:
	_changer_ecran("fouille")

func _ouvrir_boutique() -> void:
	ShopScript.ouvrir(self)

# ================================================================ langue / système
func _cycle_langue() -> void:
	var langs: Array = Data.LANGUES
	var cur: String = State.langue_actuelle()
	var idx := langs.find(cur)
	if idx < 0: idx = 0
	var nxt: String = langs[(idx + 1) % langs.size()]
	State.d["langue"] = nxt
	Data.langue = nxt
	State.sauver()
	_construire()

func _ouvrir_cadeau() -> void:
	var m := UiKit.modale(T("礼包", "Daily gift", "每日登录礼包"), 520)
	get_tree().root.add_child.call_deferred(m["racine"])
	var c: VBoxContainer = m["contenu"]
	c.add_child(UiKit.icone_emoji("🎁", 80))
	for ligne in [
		T("体力 ×20", "Energy ×20", "体力 ×20"),
		T("铜钱 ×40", "Coins ×40", "铜钱 ×40"),
		T("树叶 ×2", "Leaves ×2", "树叶 ×2"),
		T("活动积分 ×100", "Event points ×100", "活动积分 ×100"),
	]:
		c.add_child(UiKit.label("·  " + ligne, 18, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	var ok := UiKit.bouton(T("一键领取", "Claim all", "一键领取"), UiKit.VERT, UiKit.TEXT_CLAIR, 20, 50)
	ok.pressed.connect(func():
		State.prendre_cadeau()
		UiKit.fermer(m["racine"])
		UiKit.toast(T("礼包已领取！", "Gift claimed!", "礼包已领取！"), UiKit.OR))
	c.add_child(ok)

# ================================================================ capture d'écran de debug
func _mode_capture(mode: String) -> void:
	State.remplir_commandes()
	await get_tree().create_timer(1.2).timeout
	match mode:
		"plateau": _changer_ecran("plateau")
		"ile": _changer_ecran("ile")
		"fouille": _changer_ecran("fouille")
		"boutique": ShopScript.ouvrir(self)
		"passe": PassScript.ouvrir(self)
		"classe": RankScript.ouvrir(self)
		"cadeau": _ouvrir_cadeau()
	if DisplayServer.get_name() == "headless":
		for i in range(20):
			await get_tree().process_frame
		print("NO_RENDER_OK ", mode)
		State.sauver()
		get_tree().quit()
		return
	for i in range(6):
		await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("user://shot_%s.png" % mode)
	print("SHOT_OK user://shot_%s.png" % mode)
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()
