# board.gd — Écran principal : plateau de fusion 7×10 à la 去有梦的小岛.
# Disposition fidèle au jeu de référence :
#   · 3 commandes de lapins EN HAUT avec minuteur + bouton "livrer tout"
#   · générateurs POSÉS SUR LE PLATEAU (charges puis recharge), pas une barre d'outils
#   · bloc de caisses verrouillées sur les deux rangées du bas
#   · barre du bas : coffre | fiche objet | boutique
extends Control

var main = null                    # main.gd
var cases := {}                    # str(idx) -> Case
var sel_idx := -1                  # case sélectionnée (fiche objet)
var grille: GridContainer = null
var commandes_box: HBoxContainer = null
var info_box: HBoxContainer = null
var info_v: VBoxContainer = null
var info_vente: Button = null
var info_icone: Control = null
var _sec := 0.0

# ================================================================ construction
func _ready() -> void:
	State.remplir_commandes()
	_preparer_plateau_neuf()
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
	v.add_child(_commandes())
	v.add_child(_plateau())
	v.add_child(_barre_info())
	State.maj.connect(_sur_maj)
	State.commandes_maj.connect(_sur_commandes)
	_rafraichir_tout()
	_rafraichir_sel()

func _sur_maj() -> void:
	_rafraichir_tout()
	_rafraichir_sel()

func _sur_commandes() -> void:
	_rafraichir_commandes()

# -------------------------------------------------------------- préparations
func _preparer_plateau_neuf() -> void:
	if not State.d["plateau"].is_empty(): return
	if State.d.get("tuto_sem", false): return
	State.d["tuto_sem"] = true
	var r := RandomNumberGenerator.new()
	r.randomize()
	for chaine in Data.CHAINS:
		for n in 2:
			var libre := _cases_libres()
			if libre.is_empty(): return
			var idx: int = libre[r.randi_range(0, libre.size() - 1)]
			State.d["plateau"][str(idx)] = "%s-1" % chaine

# ================================================================ commandes des lapins (en haut)
func _commandes() -> PanelContainer:
	var pan := PanelContainer.new()
	pan.add_theme_stylebox_override("panel", UiKit.panneau_parchemin(16))
	var hb := UiKit.hbox(6)
	pan.add_child(hb)
	var tout := UiKit.bouton("✔", UiKit.VERT, UiKit.TEXT_CLAIR, 24, 56, 14)
	tout.custom_minimum_size.x = 56
	tout.tooltip_text = Data.t("Livrer tout ce qui est prêt", "Deliver everything ready", "交付所有已完成的订单")
	tout.pressed.connect(_tout_livrer)
	hb.add_child(tout)
	commandes_box = UiKit.hbox(6)
	commandes_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(commandes_box)
	_rafraichir_commandes()
	return pan

func _tout_livrer() -> void:
	var n := 0
	for i in range(State.d["commandes"].size() - 1, -1, -1):
		if State.livraison_possible(State.d["commandes"][i]):
			State.livrer(i)
			n += 1
	if n == 0:
		Son.jouer("erreur")
		UiKit.toast(Data.t("Aucune commande prête.", "No order ready.", "暂无可交付的订单。"))
		return
	State.sauver()

func _rafraichir_commandes() -> void:
	if commandes_box == null: return
	for c in commandes_box.get_children():
		commandes_box.remove_child(c)
		c.queue_free()
	for i in range(State.d["commandes"].size()):
		commandes_box.add_child(_carte_commande(i))

func _carte_commande(i: int) -> Button:
	var cmd: Dictionary = State.d["commandes"][i]
	var ok := State.livraison_possible(cmd)
	var carte := Button.new()
	carte.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	carte.custom_minimum_size = Vector2(0, 84)
	var fond: Color = Color("#dff0c8") if ok else Color("#f3e8d2")
	var bord: Color = UiKit.VERT_FONCE if ok else Color("#cbb17e")
	carte.add_theme_stylebox_override("normal", UiKit.panneau(fond, bord, 12, 3))
	carte.add_theme_stylebox_override("hover", UiKit.panneau(fond.lightened(0.06), bord, 12, 3))
	carte.add_theme_stylebox_override("pressed", UiKit.panneau(fond.darkened(0.06), bord, 12, 3))

	var vb := UiKit.vbox(1)
	var ligne := UiKit.hbox(5)
	ligne.alignment = BoxContainer.ALIGNMENT_CENTER
	ligne.add_child(UiKit.icone_objet(cmd["obj"], 38, false))
	var infos := UiKit.vbox(0)
	infos.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var niv := int(str(cmd["obj"]).get_slice("-", 1))
	infos.add_child(UiKit.label("N%d ×%d" % [niv, int(cmd["qty"])], 15, UiKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true))
	var gains := UiKit.hbox(4)
	gains.add_child(UiKit.icone_emoji("🪙", 14))
	gains.add_child(UiKit.label(str(int(cmd["coins"])), 12, UiKit.TEXT))
	if int(cmd["feuilles"]) > 0:
		gains.add_child(UiKit.icone_emoji("🍃", 14))
		gains.add_child(UiKit.label(str(int(cmd["feuilles"])), 12, UiKit.TEXT))
	infos.add_child(gains)
	ligne.add_child(infos)
	vb.add_child(ligne)

	var t := State.temps_commande(i)
	var chrono := UiKit.label("⏳ " + UiKit.fmt_duree(t), 11, Color("#8a6d3d") if t > 300 else UiKit.ROUGE, HORIZONTAL_ALIGNMENT_CENTER)
	chrono.name = "chrono"
	vb.add_child(chrono)

	UiKit.contenu_bouton(carte, vb)
	carte.pressed.connect(func():
		if State.livrer(i):
			Son.jouer("piece")
			State.sauver()
		else:
			UiKit.toast(Data.t("Objets manquants sur le plateau.", "Items missing on the board.", "棋盘上缺少所需物品。")))
	return carte

# ================================================================ plateau
func _plateau() -> Control:
	var centre := CenterContainer.new()
	centre.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var pan := PanelContainer.new()
	pan.add_theme_stylebox_override("panel", UiKit.panneau_bois(16))
	var fond := PanelContainer.new()
	fond.add_theme_stylebox_override("panel", UiKit.panneau(Color("#b7cf9a"), Color("#7d9a5c"), 10, 2))
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pan.add_child(fond)
	grille = GridContainer.new()
	grille.columns = Data.BOARD_COLS
	grille.add_theme_constant_override("h_separation", 2)
	grille.add_theme_constant_override("v_separation", 2)
	grille.custom_minimum_size = Vector2(Data.BOARD_COLS * 90, Data.BOARD_ROWS * 84)
	var m2 := MarginContainer.new()
	m2.add_theme_constant_override("margin_left", 5)
	m2.add_theme_constant_override("margin_right", 5)
	m2.add_theme_constant_override("margin_top", 5)
	m2.add_theme_constant_override("margin_bottom", 5)
	m2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m2.add_child(grille)
	fond.add_child(m2)
	for idx in range(Data.BOARD_COLS * Data.BOARD_ROWS):
		var c := Case.new(idx, self)
		cases[str(idx)] = c
		grille.add_child(c)
	for k in cases:
		_case(int(k))._update_v()
	centre.add_child(pan)
	return centre

func _case(idx: int):
	return cases.get(str(idx))

func objet_idx(idx: int) -> String:
	if State.est_verrouillee(idx): return ""
	if State.gen_est_gen(idx): return ""
	return str(State.d["plateau"].get(str(idx), ""))

func _rafraichir_tout() -> void:
	for k in cases:
		_case(int(k))._update_v()

func _cases_libres() -> Array:
	var out: Array = []
	for idx in range(Data.BOARD_COLS * Data.BOARD_ROWS):
		var k := str(idx)
		if State.est_verrouillee(idx): continue
		if State.gen_est_gen(idx): continue
		if State.d["plateau"].has(k): continue
		out.append(idx)
	return out

# La production part de la case la plus proche du générateur, pas au hasard sur le plateau.
func _case_libre_proche(idx: int, libres: Array) -> int:
	var cx := idx % Data.BOARD_COLS
	var cy := idx / Data.BOARD_COLS
	var meilleur: int = libres[0]
	var meilleure_d := 9999
	for l in libres:
		var d: int = absi(int(l) % Data.BOARD_COLS - cx) + absi(int(l) / Data.BOARD_COLS - cy)
		if d < meilleure_d:
			meilleure_d = d
			meilleur = int(l)
	return meilleur

# ================================================================ barre du bas : coffre | fiche | boutique
func _barre_info() -> PanelContainer:
	var pan := PanelContainer.new()
	pan.add_theme_stylebox_override("panel", UiKit.panneau_parchemin(14))
	var hb := UiKit.hbox(6)
	pan.add_child(hb)

	var coffre := UiKit.bouton("🎁", UiKit.OR, UiKit.TEXT_CLAIR, 22, 52, 12)
	coffre.custom_minimum_size.x = 56
	coffre.tooltip_text = Data.t("Coffre", "Chest", "宝箱")
	coffre.pressed.connect(_ouvrir_coffre)
	hb.add_child(coffre)

	var cadre := PanelContainer.new()
	cadre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cadre.add_theme_stylebox_override("panel", UiKit.panneau(UiKit.PARCH, Color("#cbb17e"), 12, 2))
	info_box = UiKit.hbox(8)
	cadre.add_child(info_box)
	hb.add_child(cadre)

	var boutique := UiKit.bouton("🛒", UiKit.BOIS_CLAIR, UiKit.TEXT_CLAIR, 22, 52, 12)
	boutique.custom_minimum_size.x = 56
	boutique.tooltip_text = Data.t("Boutique", "Shop", "商店")
	boutique.pressed.connect(func():
		if main != null: main._ouvrir_boutique())
	hb.add_child(boutique)
	return pan

# ================================================================ fiche objet
func _rafraichir_sel() -> void:
	if info_box == null: return
	for c in info_box.get_children():
		info_box.remove_child(c)
		c.queue_free()
	info_icone = null
	info_vente = null
	if sel_idx < 0 or not State.d["plateau"].has(str(sel_idx)):
		var hint := UiKit.label(Data.t("Touche un objet pour voir sa fiche.", "Tap an item to see its card.", "点击选中物品查看详情。"), 14, UiKit.TEXT)
		hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		info_box.add_child(hint)
		return
	var s: String = str(State.d["plateau"][str(sel_idx)])
	var info = Data.ITEMS.get(s)
	if info == null: return
	info_icone = UiKit.icone_objet(s, 40, false)
	info_icone.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info_box.add_child(info_icone)
	info_v = UiKit.vbox(0)
	info_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info_v.add_child(UiKit.label("%s · N%d" % [Data.nom_objet(s), int(info["niveau"])], 14, UiKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true))
	var lore := Data.lore_objet(s)
	if lore != "":
		var l := UiKit.label(lore, 11, Color("#7a6a52"))
		l.clip_text = true
		info_v.add_child(l)
	info_box.add_child(info_v)
	info_vente = UiKit.bouton("+%d 🪙" % (3 * int(info["niveau"])), UiKit.OR, UiKit.TEXT_CLAIR, 13, 40)
	info_vente.custom_minimum_size.x = 84
	info_vente.tooltip_text = Data.t("Vendre", "Sell", "出售")
	info_vente.pressed.connect(func(): _vendre(sel_idx, s))
	info_box.add_child(info_vente)

func _vendre(idx_v: int, objet: String) -> void:
	var info = Data.ITEMS[objet]
	State.d["plateau"].erase(str(idx_v))
	State.ajouter_coins(3 * int(info["niveau"]))
	State.sauver()
	sel_idx = -1
	_rafraichir_tout()
	_rafraichir_sel()

# ================================================================ clics : production / sélection / achat
func cliquer(idx: int) -> void:
	if State.est_verrouillee(idx):
		var p := State.prix_case(idx)
		if State.deverrouiller_case(idx):
			Son.jouer("piece")
			UiKit.toast(Data.t("Case débloquée !", "Cell unlocked!", "解锁成功！"), UiKit.OR)
			State.sauver()
		else:
			UiKit.toast(Data.t("Pas assez de pièces (%d 🪙)." % p, "Not enough coins (%d 🪙)." % p, "铜钱不足（%d 🪙）。" % p))
		_rafraichir_tout()
		return
	if State.gen_est_gen(idx):
		produire(idx)
		return
	sel_idx = idx
	_rafraichir_tout()
	_rafraichir_sel()

func produire(idx: int) -> void:
	var g := State.gen_at(idx)
	if g.is_empty(): return
	var reste := State.gen_recharge_restante(idx)
	if reste > 0.0:
		UiKit.toast(Data.t("En recharge… %s" % UiKit.fmt_duree(reste), "Recharging… %s" % UiKit.fmt_duree(reste), "充能中… %s" % UiKit.fmt_duree(reste)))
		return
	var libre := _cases_libres()
	if libre.is_empty():
		UiKit.toast(Data.t("Plateau plein : fusionne ou vends !", "Board full: merge or sell!", "棋盘满了：合成或出售！"))
		return
	if not State.depenser_energie(1):
		Son.jouer("erreur")
		UiKit.toast(Data.t("Plus d'énergie ! Ouvre la boutique 🛒", "Out of energy! Open the shop 🛒", "体力不足！请打开商店 🛒"))
		return
	var cible := _case_libre_proche(idx, libre)
	State.d["plateau"][str(cible)] = "%s-1" % str(g["chaine"])
	State.gen_consommer(idx)
	Son.jouer("clic")
	_fusion_anim(_case(cible))
	State.sauver()
	_rafraichir_tout()

func _fusion_anim(c) -> void:
	if c == null: return
	var tw: Tween = c.create_tween()
	tw.tween_property(c, "scale", Vector2(1.14, 1.14), 0.08)
	tw.tween_property(c, "scale", Vector2(1.0, 1.0), 0.14)

func _process(delta: float) -> void:
	_sec += delta
	if _sec < 1.0: return
	_sec = 0.0
	# Générateurs en recharge et chronos de commande : une mise à jour par seconde suffit.
	for k in State.d["gen"]:
		var c = _case(int(k))
		if c != null: c._update_v()
	if commandes_box != null:
		var enfants := commandes_box.get_children()
		for i in range(enfants.size()):
			var chrono = enfants[i].find_child("chrono", false, false)
			if chrono != null:
				var t := State.temps_commande(i)
				chrono.text = "⏳ " + UiKit.fmt_duree(t)
				chrono.add_theme_color_override("font_color", Color("#8a6d3d") if t > 300 else UiKit.ROUGE)

# ================================================================ déplacement / fusion
func deposer(src: int, dst: int) -> void:
	if State.est_verrouillee(src) or State.est_verrouillee(dst): return
	# Un générateur se déplace mais ne fusionne jamais.
	if State.gen_est_gen(src):
		if State.d["plateau"].has(str(dst)) or State.gen_est_gen(dst):
			UiKit.toast(Data.t("Un générateur ne fusionne pas.", "A producer never merges.", "生产器无法合成。"))
			return
		State.deplacer_gen(src, dst)
		State.sauver()
		_rafraichir_tout()
		return
	if State.gen_est_gen(dst): return
	var a: String = objet_idx(src)
	var b: String = objet_idx(dst)
	if a == "": return
	if b == "":
		State.d["plateau"].erase(str(src))
		State.d["plateau"][str(dst)] = a
	elif b == a:
		var nxt: String = Data.item_suivant(a)
		if nxt == "":
			UiKit.toast(Data.t("Objet au niveau maximum !", "Item at max level!", "已达到最高等级！"))
			return
		State.d["plateau"].erase(str(src))
		State.d["plateau"].erase(str(dst))
		State.d["plateau"][str(dst)] = nxt
		State.noter_fusion()
		State.ajouter_xp(5)
		Son.jouer("fusion")
		_fusion_anim(_case(dst))
		UiKit.toast(Data.t("Fusion ", "Merged ", "合成 ") + Data.nom_objet(nxt), Color("#dff0c8"))
	else:
		State.d["plateau"][str(src)] = b
		State.d["plateau"][str(dst)] = a
	State.sauver()
	_rafraichir_tout()
	_rafraichir_sel()

func prix_efface(idx: int) -> int:
	return State.prix_case(idx)

# ================================================================ coffre
func _ouvrir_coffre() -> void:
	var m := UiKit.modale(Data.t("Coffre au trésor", "Treasure chest", "藏宝箱"), 480)
	get_tree().root.add_child.call_deferred(m["racine"])
	var c: VBoxContainer = m["contenu"]
	c.add_child(UiKit.icone_emoji("🎁", 72))
	c.add_child(UiKit.label(Data.t("60 🪙 → 3 objets au hasard", "60 🪙 → 3 random items", "60 🪙 → 随机3件物品"), 18, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	var ok := UiKit.bouton(Data.t("Ouvrir (60 🪙)", "Open (60 🪙)", "打开（60 🪙）"), UiKit.OR, UiKit.TEXT_CLAIR, 18, 48)
	ok.pressed.connect(func():
		if State.depenser_coins(60):
			var offerts := []
			var r := RandomNumberGenerator.new()
			r.randomize()
			var chaines: Array = Data.CHAINS.keys()
			for i in 3:
				var chaine: String = chaines[r.randi_range(0, chaines.size() - 1)]
				var lvl := 1
				if r.randf() < 0.35: lvl = 2
				if r.randf() < 0.07: lvl = 3
				offerts.append("%s-%d" % [chaine, lvl])
			_libre_ou_perdu(offerts)
			Son.jouer("piece")
			UiKit.fermer(m["racine"])
			UiKit.toast(Data.t("Coffre ouvert !", "Chest opened!", "宝箱已打开！"), UiKit.OR)
			State.sauver()
		else:
			UiKit.toast(Data.t("Pas assez de pièces.", "Not enough coins.", "铜钱不足。")))
	c.add_child(ok)

func _libre_ou_perdu(offerts: Array) -> void:
	var r := RandomNumberGenerator.new()
	r.randomize()
	for o in offerts:
		var libre := _cases_libres()
		if libre.is_empty():
			UiKit.toast(Data.t("Plateau plein : objet perdu !", "Board full: item lost!", "棋盘满了：物品遗失！"))
			return
		var idx: int = libre[r.randi_range(0, libre.size() - 1)]
		State.d["plateau"][str(idx)] = o
	_rafraichir_tout()

# ================================================================ une case
class Case extends PanelContainer:
	var idx: int = 0
	var board = null
	var txt: Label = null
	var badge: Label = null
	var img: TextureRect = null
	var _sig := ""

	func _init(p_idx: int, p_board) -> void:
		idx = p_idx
		board = p_board
		custom_minimum_size = Vector2(90, 84)
		pivot_offset = Vector2(45, 42)
		mouse_filter = Control.MOUSE_FILTER_STOP
		# Illustration de l'objet, affichée par-dessus le fond de case quand elle existe.
		img = TextureRect.new()
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		img.visible = false
		add_child(img)
		# PanelContainer empile ses enfants en plein cadre : il faut un VBox pour que
		# l'icône et son badge (charges, niveau) se répartissent verticalement.
		var vb := VBoxContainer.new()
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		vb.add_theme_constant_override("separation", 0)
		vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(vb)
		txt = Label.new()
		txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		txt.add_theme_font_override("font", UiKit.font())
		txt.add_theme_font_size_override("font_size", 34)
		txt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(txt)
		badge = Label.new()
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.add_theme_font_override("font", UiKit.font())
		badge.add_theme_font_size_override("font_size", 12)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(badge)

	func _update_v() -> void:
		if board == null: return
		var verrou: bool = State.est_verrouillee(idx)
		var gen: Dictionary = State.gen_at(idx)
		var s: String = board.objet_idx(idx)
		var sig := "%s|%s|%s|%d" % [str(verrou), str(gen.get("chaine", "")), s, int(gen.get("charges", -1))]
		var change := sig != _sig
		_sig = sig

		if verrou:
			if change:
				img.visible = false
				add_theme_stylebox_override("panel", UiKit.panneau(Color("#c9a06a"), Color("#8a5f2f"), 6, 2))
				txt.text = "🪙%d" % board.prix_efface(idx)
				txt.add_theme_font_size_override("font_size", 15)
				txt.add_theme_color_override("font_color", Color("#3c2a12"))
				badge.text = ""
			return

		if not gen.is_empty():
			if change:
				var chaine: String = str(gen["chaine"])
				var coul: Color = Data.CHAINS[chaine]["couleur"]
				var bord: Color = Data.CHAINS[chaine]["bord"]
				add_theme_stylebox_override("panel", UiKit.panneau(coul.darkened(0.08), bord, 8, 3))
				var chemin_gen := Data.chemin_icone_gen(chaine)
				if chemin_gen != "":
					img.texture = load(chemin_gen)
					img.visible = true
					txt.text = ""
				else:
					img.visible = false
					txt.text = Data.GENERATORS[chaine]["emoji"]
					txt.add_theme_font_size_override("font_size", 36)
					txt.add_theme_color_override("font_color", Color("#000000"))
			var reste: float = State.gen_recharge_restante(idx)
			var libelle := ("⏳" + UiKit.fmt_duree(reste)) if reste > 0.0 else "×%d" % int(gen["charges"])
			if badge.text != libelle:
				badge.text = libelle
				badge.add_theme_font_size_override("font_size", 12)
				badge.add_theme_color_override("font_color", UiKit.ROUGE if reste > 0.0 else Color("#2f4a12"))
			return

		var info = Data.ITEMS.get(s)
		if info != null:
			if change:
				add_theme_stylebox_override("panel", UiKit.panneau(info["couleur"], info["bord"], 8, 2))
				var chemin := Data.chemin_icone(s)
				if chemin != "":
					img.texture = load(chemin)
					img.visible = true
					txt.text = ""
				else:
					img.visible = false
					txt.text = info["emoji"]
					txt.add_theme_font_size_override("font_size", 34)
					txt.add_theme_color_override("font_color", Color("#000000"))
				var niv := int(info["niveau"])
				badge.text = "" if niv <= 1 else "N%d" % niv
				badge.add_theme_font_size_override("font_size", 11)
				badge.add_theme_color_override("font_color", Color("#4a3a28"))
			return

		if change:
			img.visible = false
			# damier clair, comme la grille du jeu de référence
			var cx: int = idx % Data.BOARD_COLS
			var cy: int = idx / Data.BOARD_COLS
			var clair := (cx + cy) % 2 == 0
			add_theme_stylebox_override("panel", UiKit.panneau(
				Color("#e2eecd") if clair else Color("#d3e3b6"),
				Color("#b7cf9a"), 6, 1))
			txt.text = ""
			badge.text = ""

	func _get_drag_data(_at: Vector2):
		if State.est_verrouillee(idx): return null
		var prev := PanelContainer.new()
		if State.gen_est_gen(idx):
			var g: Dictionary = State.gen_at(idx)
			var chaine: String = str(g["chaine"])
			prev.add_theme_stylebox_override("panel", UiKit.panneau(Data.CHAINS[chaine]["couleur"], Data.CHAINS[chaine]["bord"], 10, 3))
			var lg := Label.new()
			lg.text = Data.GENERATORS[chaine]["emoji"]
			lg.add_theme_font_override("font", UiKit.font())
			lg.add_theme_font_size_override("font_size", 40)
			lg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			prev.add_child(lg)
		else:
			var s: String = board.objet_idx(idx)
			if s == "": return null
			var info = Data.ITEMS.get(s)
			if info == null: return null
			prev.add_theme_stylebox_override("panel", UiKit.panneau(info["couleur"], info["bord"], 10, 3))
			var l := Label.new()
			l.text = info["emoji"]
			l.add_theme_font_override("font", UiKit.font())
			l.add_theme_font_size_override("font_size", 40)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			prev.add_child(l)
		prev.modulate.a = 0.85
		set_drag_preview(prev)
		return {"idx": idx}

	func _can_drop_data(_at: Vector2, data) -> bool:
		if typeof(data) != TYPE_DICTIONARY: return false
		if not data.has("idx"): return false
		if State.est_verrouillee(idx): return false
		return int(data["idx"]) != idx

	func _drop_data(_at: Vector2, data) -> void:
		board.deposer(int(data["idx"]), idx)

	func _gui_input(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			board.cliquer(idx)
