# hidden_game.gd — Mode 寻物 : choisir une fouille, puis retrouver 8 objets cachés
# dans une scène peinte (décor généré au runtime, aucune asset externe).
extends Control

var main = null
var v: VBoxContainer = null
var fouille: Dictionary = {}
var nb_trouves := 0
var total_cibles := 8
var lbl_progres: Label = null
var scene = null
var retardements: Array = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var marg := MarginContainer.new()
	marg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	marg.add_theme_constant_override("margin_left", 6)
	marg.add_theme_constant_override("margin_right", 6)
	marg.add_theme_constant_override("margin_top", 6)
	add_child(marg)
	v = UiKit.vbox(8)
	marg.add_child(v)
	_afficher_liste()

func _en_tete(titre: String, complement := "") -> PanelContainer:
	var pan := PanelContainer.new()
	pan.add_theme_stylebox_override("panel", UiKit.panneau_bois(14))
	var hb := UiKit.hbox(10)
	pan.add_child(hb)
	var retour := UiKit.bouton("←", UiKit.BOIS_CLAIR, UiKit.TEXT_CLAIR, 18, 40, 12)
	retour.pressed.connect(func(): main.vers_plateau())
	hb.add_child(retour)
	var l := UiKit.label(titre, 20, UiKit.PARCH, HORIZONTAL_ALIGNMENT_CENTER, true)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(l)
	if complement != "":
		hb.add_child(UiKit.label(complement, 16, UiKit.OR))
	return pan

# ================================================================ liste des fouilles
func _afficher_liste() -> void:
	retardements.clear()
	v.add_child(_en_tete(Data.t("彩色寻物", "Scenic Search", "彩色寻物")))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var col := UiKit.vbox(10)
	col.custom_minimum_size.x = 690
	sc.add_child(col)
	col.add_child(UiKit.label(
		Data.t("Trouve tous les objets cachés dans la scène !", "Find every hidden item in the scene!", "找到所有隐藏的物品！"),
		15, UiKit.TEXT))
	for i in range(Data.FOUILLES.size()):
		col.add_child(_carte_fouille(Data.FOUILLES[i], i))

func _carte_fouille(f: Dictionary, i: int) -> PanelContainer:
	var debloquee := State.fouille_debloquee(i)
	var pan := PanelContainer.new()
	pan.add_theme_stylebox_override("panel", UiKit.panneau_bois(16) if debloquee else UiKit.panneau(Color("#a2967f"), Color("#6e4c1e"), 16, 3))
	var hb := UiKit.hbox(12)
	hb.add_child(UiKit.icone_emoji("🖼", 56, Color("#eadcc0"), UiKit.BOIS_CLAIR))
	var col := UiKit.vbox(2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(UiKit.label(f[Data.langue], 18, UiKit.TEXT if debloquee else Color("#4a3a28"), HORIZONTAL_ALIGNMENT_LEFT, true))
	if debloquee:
		var r := UiKit.hbox(8)
		r.add_child(UiKit.icone_emoji("⚡", 16))
		r.add_child(UiKit.label("+%d" % int(f.get("energie", 0)), 13, UiKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true))
		r.add_child(UiKit.icone_emoji("🌙", 16))
		r.add_child(UiKit.label(str(f["points"]), 13, UiKit.TEXT))
		r.add_child(UiKit.icone_emoji("🪙", 16))
		r.add_child(UiKit.label(str(f["coins"]), 13, UiKit.TEXT))
		r.add_child(UiKit.icone_emoji("🍃", 16))
		r.add_child(UiKit.label(str(f["feuilles"]), 13, UiKit.TEXT))
		col.add_child(r)
	else:
		col.add_child(UiKit.label(Data.t("Niveau verrouillé — termine le précédent.", "Level locked — finish the previous one.", "关卡未解锁"), 13, Color("#5a4a32")))
	hb.add_child(col)

	var bt: Button
	if not debloquee:
		bt = UiKit.bouton("🔒", Color("#8a7d6c"), UiKit.TEXT_CLAIR, 16, 42, 12)
		bt.disabled = true
	elif not State.fouille_finie(f["id"]) or State.fouille_cooldown_restant(f["id"]) <= 0.0:
		var lbl_bt := Data.t("Rejouer", "Replay", "重玩") if State.fouille_finie(f["id"]) else Data.t("开始", "Start", "开始")
		bt = UiKit.bouton(lbl_bt, UiKit.VERT, UiKit.TEXT_CLAIR, 16, 42, 12)
		bt.pressed.connect(func(): _lancer(f))
	else:
		bt = UiKit.bouton(UiKit.fmt_duree(State.fouille_cooldown_restant(f["id"])), UiKit.BOIS_CLAIR, UiKit.TEXT_CLAIR, 14, 42, 12)
		bt.disabled = true
		retardements.append({"bt": bt, "f": f})
	hb.add_child(bt)
	pan.add_child(hb)
	return pan

func _process(_delta: float) -> void:
	for e in retardements:
		var bt: Button = e["bt"]
		if not is_instance_valid(bt): continue
		var reste := State.fouille_cooldown_restant(e["f"]["id"])
		if reste <= 0.0 and bt.disabled:
			bt.disabled = false
			bt.text = Data.t("Rejouer", "Replay", "重玩")
		elif reste > 0.0:
			bt.text = UiKit.fmt_duree(reste)

# ================================================================ la fouille
func _lancer(f: Dictionary) -> void:
	if State.fouille_cooldown_restant(f["id"]) > 0.0:
		return
	fouille = f
	nb_trouves = 0
	for c in v.get_children():
		v.remove_child(c)
		c.queue_free()
	# --- en-tête avec compteur de progression
	var pan := PanelContainer.new()
	pan.add_theme_stylebox_override("panel", UiKit.panneau_bois(14))
	var hb := UiKit.hbox(10)
	pan.add_child(hb)
	var retour := UiKit.bouton("←", UiKit.BOIS_CLAIR, UiKit.TEXT_CLAIR, 18, 40, 12)
	retour.pressed.connect(func(): main.vers_plateau())
	hb.add_child(retour)
	var titre := UiKit.label(Data.t("Trouve les objets cachés !", "Find the hidden items!", "找到所有隐藏的物品！"), 20, UiKit.PARCH, HORIZONTAL_ALIGNMENT_CENTER, true)
	titre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titre.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(titre)
	lbl_progres = UiKit.label("%s 0/%d" % [f[Data.langue], total_cibles], 16, UiKit.OR)
	hb.add_child(lbl_progres)
	v.add_child(pan)

	# --- scène
	var panneau_scene := PanelContainer.new()
	panneau_scene.add_theme_stylebox_override("panel", UiKit.panneau_bois(18))
	panneau_scene.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scene = Decor.new(f["id"].hash())
	scene.custom_minimum_size = Vector2(690, 600)
	scene.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panneau_scene.add_child(scene)
	v.add_child(panneau_scene)

	# --- 8 cibles : objets d'objets de chaînes, niveaux 1..3
	var r := RandomNumberGenerator.new()
	r.seed = f["id"].hash()
	var ids: Array = []
	var chaines: Array = Data.CHAINS.keys()
	for i in total_cibles:
		var chaine: String = chaines[r.randi_range(0, chaines.size() - 1)]
		var lvl := r.randi_range(1, 3)
		ids.append("%s-%d" % [chaine, lvl])

	# --- positions sans chevauchement grossier
	var places: Array = []
	for id_objet in ids:
		var taille := r.randi_range(46, 62)
		var p := Vector2.ZERO
		var trop_proche := true
		var essais := 0
		while trop_proche and essais < 40:
			essais += 1
			p = Vector2(r.randf_range(20, 664 - taille), r.randf_range(20, 574 - taille))
			trop_proche = false
			for q in places:
				if p.distance_to(q) < taille * 0.95:
					trop_proche = true
					break
		places.append(p)
		var ic := UiKit.icone_objet(id_objet, taille, false)
		ic.position = p
		ic.rotation = r.randf_range(-0.25, 0.25)
		ic.mouse_filter = Control.MOUSE_FILTER_STOP
		ic.set_meta("objet", id_objet)
		var ref := ic
		ic.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_tap(ref))
		scene.add_child(ic)

	# --- liste du bas : cibles à retrouver
	var bas := PanelContainer.new()
	bas.add_theme_stylebox_override("panel", UiKit.panneau_parchemin(14))
	var liste := UiKit.hbox(6)
	bas.add_child(liste)
	for id_objet in ids:
		var carte := PanelContainer.new()
		carte.custom_minimum_size = Vector2(76, 76)
		carte.add_theme_stylebox_override("panel", UiKit.panneau(Color("#f3e8d2"), Color("#cbb17e"), 10, 2))
		carte.set_meta("objet", id_objet)
		var box := UiKit.vbox(0)
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		var ic2 := UiKit.icone_objet(id_objet, 40, false)
		box.add_child(ic2)
		var nm := UiKit.label(Data.nom_objet(id_objet), 10, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
		nm.clip_text = true
		box.add_child(nm)
		carte.add_child(box)
		for c in box.get_children():
			(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		liste.add_child(carte)

func _tap(ic) -> void:
	if ic == null or nb_trouves >= total_cibles: return
	var id_objet: String = str(ic.get_meta("objet"))
	# marquer trouvé
	nb_trouves += 1
	var tw: Tween = ic.create_tween()
	tw.tween_property(ic, "modulate:a", 0.15, 0.25)
	tw.tween_property(ic, "scale", Vector2(0.6, 0.6), 0.2)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# cocher la carte correspondante dans la liste du bas
	var bas = v.get_child(v.get_child_count() - 1)
	for carte in bas.get_child(0).get_children():
		if carte.has_meta("objet") and str(carte.get_meta("objet")) == id_objet:
			var sb := UiKit.panneau(Color("#dff0c8"), UiKit.VERT_FONCE, 10, 3)
			carte.add_theme_stylebox_override("panel", sb)
			break
	if lbl_progres != null:
		lbl_progres.text = "%s %d/%d" % [fouille[Data.langue], nb_trouves, total_cibles]
	if nb_trouves >= total_cibles:
		_terminer()

func _terminer() -> void:
	await get_tree().create_timer(0.7).timeout
	if not is_instance_valid(self): return
	State.terminer_fouille(fouille)
	UiKit.toast(Data.t("Fouille réussie !", "Search complete!", "寻物成功！"), UiKit.OR)
	State.sauver()
	_afficher_liste()

# ================================================================ décor peint (généré)
class Decor extends Control:
	var graine := 0

	func _init(p_graine: int) -> void:
		graine = p_graine

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = graine
		# ciel dégradé (bandes)
		var ciel := [Color("#e8f4f5"), Color("#dceff0"), Color("#d0e8ea"), Color("#c6e0e3")]
		for i in ciel.size():
			draw_rect(Rect2(0, size.y * i / ciel.size(), size.x, size.y / ciel.size() + 1), ciel[i])
		# collines de fond
		draw_rect(Rect2(0, size.y * 0.55, size.x, size.y * 0.5), Color("#9fbf79"))
		draw_rect(Rect2(0, size.y * 0.62, size.x, size.y * 0.45), Color("#8db06a"))
		# rangée de toits chinois à l'arrière-plan
		for i in 5:
			var cx := 60.0 + i * (size.x - 120) / 4.0 + r.randf_range(-20, 20)
			var corps := Rect2(cx - 55, size.y * 0.42 + r.randf_range(-20, 10), 110, size.y * 0.20)
			draw_rect(corps, Color(Color("#c78b52"), 0.55))
			var toit := PackedVector2Array([Vector2(cx - 75, corps.position.y), Vector2(cx + 75, corps.position.y), Vector2(cx + 58, corps.position.y - 30), Vector2(cx - 58, corps.position.y - 30)])
			draw_colored_polygon(toit, Color(Color("#7d4e1e"), 0.7))
			# lanternes
			draw_circle(Vector2(cx, corps.position.y + 22), 7, Color(Color("#e05540"), 0.75))
		# buissons / dallage
		for i in 16:
			var p := Vector2(r.randf_range(0, size.x), r.randf_range(size.y * 0.62, size.y))
			var rr := r.randf_range(10, 30)
			draw_circle(p, rr, Color(Color("#7fa657"), r.randf_range(0.25, 0.5)))
		for i in 10:
			var p2 := Vector2(r.randf_range(20, size.x - 20), r.randf_range(size.y * 0.7, size.y - 20))
			var w := r.randf_range(26, 60)
			draw_rect(Rect2(p2, Vector2(w, w * 0.55)), Color(Color("#e7dbb8"), 0.4))
			draw_rect(Rect2(p2, Vector2(w, w * 0.55)), Color(Color("#cbb17e"), 0.7), false)
		# étang
		draw_circle(Vector2(size.x * 0.75, size.y * 0.88), 70, Color(Color("#7fb9c9"), 0.5))
