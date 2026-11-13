# event_pass.gd — Modal 月神节 : pass à deux voies (gratuit / VIP simulé) + tâches quotidiennes.
# Disposition du jeu de référence : une seule colonne défilante, un palier par ligne,
# récompense gratuite à gauche, numéro au centre, récompense VIP à droite.
extends RefCounted

static func ouvrir(_main) -> void:
	var m := UiKit.modale(Data.t("月神节", "Moon Festival", "有梦月神节"), 660, 900)
	(_main as Node).get_tree().root.add_child.call_deferred(m["racine"])
	var c: VBoxContainer = m["contenu"]

	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(640, 830)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	c.add_child(sc)
	var col := UiKit.vbox(8)
	sc.add_child(col)

	# Reconstruire le contenu en place après une réclamation. Le dictionnaire sert de
	# relais : une lambda ne peut pas se référencer elle-même à sa création.
	var raf := {"cb": Callable()}
	raf["cb"] = func(): _remplir(col, _main, m, raf["cb"])
	raf["cb"].call()

# ---------------------------------------------------------------- contenu (reconstruit après réclamation)
static func _remplir(col: VBoxContainer, _main, m: Dictionary, raf: Callable) -> void:
	for c in col.get_children():
		col.remove_child(c)
		c.queue_free()

	# --- bandeau résumé
	var rende := PanelContainer.new()
	rende.add_theme_stylebox_override("panel", UiKit.panneau_parchemin(14))
	var rv := UiKit.vbox(4)
	rende.add_child(rv)
	var hb := UiKit.hbox(8)
	rv.add_child(hb)
	hb.add_child(UiKit.icone_emoji("🌙", 38))
	hb.add_child(UiKit.label(str(State.points_event()), 24, UiKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true))
	var restant := UiKit.fmt_duree(State.secondes_event_restantes())
	var tl := UiKit.label(Data.t("Temps restant : %s" % restant, "Time left: %s" % restant, "剩余时间：%s" % restant), 13, Color("#8a6d3d"))
	tl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(tl)

	var suiv := palier_suivant()
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	if suiv > 0:
		var prec := _prec_palier(suiv)
		bar.value = clampf(float(State.points_event() - prec) / float(maxi(1, suiv - prec)), 0.0, 1.0) * 100.0
	else:
		bar.value = 100.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 16)
	bar.add_theme_stylebox_override("background", UiKit.panneau(Color("#d8c69e"), Color("#b7a274"), 8, 2))
	bar.add_theme_stylebox_override("fill", UiKit.panneau(UiKit.OR, Color("#8a6d3d"), 8, 2))
	rv.add_child(bar)
	var sous := Data.t("Prochain palier à %d points", "Next tier at %d points", "%d积分到下一档") % suiv if suiv > 0 else Data.t("Tous les paliers atteints", "All tiers reached", "全部档位已达成")
	rv.add_child(UiKit.label(sous, 12, Color("#8a6d3d")))
	col.add_child(rende)

	# --- bandeau VIP
	var vip_pan := PanelContainer.new()
	vip_pan.add_theme_stylebox_override("panel", UiKit.panneau(Color("#e6d6f4"), Color("#9a6fc0"), 12, 3))
	var vh := UiKit.hbox(8)
	vip_pan.add_child(vh)
	vh.add_child(UiKit.label(Data.t("VIP 通行证", "VIP pass", "VIP 通行证"), 15, UiKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true))
	var esp := Control.new()
	esp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	esp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vh.add_child(esp)
	if bool(State.d["event"]["vip"]):
		var t := Data.t("VIP actif", "VIP active", "VIP已解锁")
		if bool(State.d["event"]["vip_lux"]):
			t += Data.t(" (豪华)", " (Deluxe)", " (豪华)")
		vh.add_child(UiKit.label("✔ " + t, 13, UiKit.VERT_FONCE, HORIZONTAL_ALIGNMENT_LEFT, true))
	else:
		var b1 := UiKit.bouton("¥30", UiKit.OR, UiKit.TEXT_CLAIR, 13, 30, 8)
		b1.custom_minimum_size.x = 66
		b1.pressed.connect(func():
			State.acheter_vip(false)
			State.sauver()
			raf.call())
		vh.add_child(b1)
		var b2 := UiKit.bouton(Data.t("¥45 豪华", "¥45 deluxe", "¥45 豪华"), UiKit.OR, UiKit.TEXT_CLAIR, 13, 30, 8)
		b2.custom_minimum_size.x = 96
		b2.pressed.connect(func():
			State.acheter_vip(true)
			State.sauver()
			raf.call())
		vh.add_child(b2)
	col.add_child(vip_pan)

	# --- entêtes de colonnes
	var entetes := UiKit.hbox(6)
	var eg := UiKit.label(Data.t("Gratuit", "Free", "免费"), 13, UiKit.VERT_FONCE, HORIZONTAL_ALIGNMENT_CENTER, true)
	eg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entetes.add_child(eg)
	entetes.add_child(UiKit.vide(Vector2(44, 0)))
	var ev := UiKit.label("VIP", 13, Color("#7a4fa0"), HORIZONTAL_ALIGNMENT_CENTER, true)
	ev.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entetes.add_child(ev)
	col.add_child(entetes)

	# --- paliers
	for i in range(1, Data.PASS_PALIERS.size() + 1):
		col.add_child(_ligne_palier(i, raf))

	# --- tâches
	col.add_child(UiKit.label(Data.t("Tâches quotidiennes", "Daily tasks", "今日任务"), 18, UiKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true))
	for t in Data.TASKS:
		col.add_child(_carte_tache(t, raf))

	col.add_child(UiKit.label(
		Data.t("Prototype : les voies VIP sont simulées depuis la boutique ⚙.", "Prototype: VIP purchases are simulated from the shop ⚙.", "演示版：可在商店 ⚙ 中模拟购买VIP。"),
		11, Color("#9a8a70")))

# ---------------------------------------------------------------- une ligne = un palier
static func _ligne_palier(i: int, raf: Callable) -> HBoxContainer:
	var hb := UiKit.hbox(6)
	hb.add_child(_cellule(i, "gratuit", raf))
	var num := UiKit.label(str(i), 16, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER, true)
	num.custom_minimum_size = Vector2(44, 0)
	num.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(num)
	hb.add_child(_cellule(i, "vip", raf))
	return hb

static func _cellule(i: int, voie: String, raf: Callable) -> PanelContainer:
	var vip := voie == "vip"
	var atteint := State.palier_atteint(i)
	var pris := State.palier_pris(i, voie)
	var dispo := atteint and (not vip or bool(State.d["event"]["vip"]))

	var pan := PanelContainer.new()
	pan.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fond := Color("#e6d6f4") if vip else Color("#e8eccb")
	if pris:
		fond = Color("#dff0c8")
	elif dispo:
		fond = Color("#f7e7b6")
	var bord := Color("#9a6fc0") if vip else Color("#a4b569")
	pan.add_theme_stylebox_override("panel", UiKit.panneau(fond, bord, 10, 2))

	var v := UiKit.vbox(2)
	pan.add_child(v)
	v.add_child(UiKit.label(_recompense(i, voie), 12, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER))

	var b := UiKit.bouton("", UiKit.VERT if dispo else Color("#a89a86"), UiKit.TEXT_CLAIR, 12, 26, 8)
	if pris:
		b.text = "✔"
		b.disabled = true
	elif dispo:
		b.text = Data.t("领取", "Claim", "领取")
		b.pressed.connect(func():
			State.reclam_palier(i, voie)
			State.sauver()
			raf.call())
	elif not atteint:
		b.text = "%d 🌙" % int(Data.PASS_PALIERS[i - 1])
		b.disabled = true
	else:
		b.text = "🔒"
		b.disabled = true
	v.add_child(b)
	return pan

static func _recompense(i: int, voie: String) -> String:
	var mult := 1 if voie == "gratuit" else 2
	var txt := "🪙 %d" % (80 * i * mult)
	if i % 3 == 0:
		txt += "  🍃 %d" % (2 * mult)
	return txt

static func _prec_palier(suiv: int) -> int:
	var idx := Data.PASS_PALIERS.find(suiv)
	if idx <= 0: return 0
	return int(Data.PASS_PALIERS[idx - 1])

static func palier_suivant() -> int:
	for p in Data.PASS_PALIERS:
		if State.points_event() < int(p):
			return int(p)
	return -1

# ---------------------------------------------------------------- carte de tâche
static func _carte_tache(t: Dictionary, raf: Callable) -> PanelContainer:
	var pan := PanelContainer.new()
	pan.add_theme_stylebox_override("panel", UiKit.panneau_parchemin(12))
	var hb := UiKit.hbox(8)
	pan.add_child(hb)
	var cv := UiKit.vbox(2)
	cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(cv)
	cv.add_child(UiKit.label(t[Data.langue], 14, UiKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true))
	var prog := mini(State.tache_progression(t["id"]), int(t["but"]["pallier"]))
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = int(t["but"]["pallier"])
	bar.value = prog
	bar.show_percentage = true
	bar.custom_minimum_size = Vector2(0, 15)
	bar.add_theme_stylebox_override("background", UiKit.panneau(Color("#d8c69e"), Color("#b7a274"), 8, 2))
	bar.add_theme_stylebox_override("fill", UiKit.panneau(UiKit.VERT, UiKit.VERT_FONCE, 8, 2))
	cv.add_child(bar)
	var rv := UiKit.hbox(5)
	rv.add_child(UiKit.icone_emoji("🌙", 16))
	rv.add_child(UiKit.label(str(t["points"]), 13, UiKit.TEXT))
	rv.add_child(UiKit.icone_emoji("🪙", 16))
	rv.add_child(UiKit.label(str(t["coins"]), 13, UiKit.TEXT))
	if int(t["feuilles"]) > 0:
		rv.add_child(UiKit.icone_emoji("🍃", 16))
		rv.add_child(UiKit.label(str(t["feuilles"]), 13, UiKit.TEXT))
	hb.add_child(rv)
	var bt := UiKit.bouton(Data.t("领", "Get", "领"), UiKit.VERT, UiKit.TEXT_CLAIR, 13, 32, 8)
	bt.custom_minimum_size.x = 60
	if State.tache_prise(t["id"]):
		bt.text = "✔"
		bt.disabled = true
	elif not State.tache_disponible(t):
		bt.text = "…"
		bt.disabled = true
	else:
		bt.pressed.connect(func():
			State.reclam_nombre_tache(t)
			State.sauver()
			raf.call())
	hb.add_child(bt)
	return pan
