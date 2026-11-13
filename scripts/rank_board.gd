# rank_board.gd — Modal 筑景名录 : classement journalier contre bots, récompenses top 3.
extends RefCounted

static func ouvrir(_main) -> void:
	var m := UiKit.modale(Data.t("筑景名录", "Scenery Rank", "筑景名录"), 560, 900)
	(_main as Node).get_tree().root.add_child.call_deferred(m["racine"])
	var c: VBoxContainer = m["contenu"]

	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(540, 820)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	c.add_child(sc)
	var col := UiKit.vbox(8)
	sc.add_child(col)

	col.add_child(UiKit.label(
		Data.t("Récolte les points de l'événement et compare-toi !", "Collect event points and compare!", "收集活动积分，参与筑景名录！"),
		14, Color("#8a6d3d")))
	col.add_child(UiKit.label(Data.t("activité ouverte", "Event open", "已开启"), 18, UiKit.VERT_FONCE, HORIZONTAL_ALIGNMENT_CENTER, true))

	# La liste est reconstruite à chaque changement d'onglet : l'état vit dans un Dictionary
	# capturé par référence, sinon les lambdas figent la valeur au moment de leur création.
	var etat := {"zone": 0}
	var boutons: Array = []
	var liste_box := UiKit.vbox(0)
	var rafraichir := func():
		for c2 in liste_box.get_children():
			liste_box.remove_child(c2)
			c2.queue_free()
		liste_box.add_child(liste_rangs(int(etat["zone"])))
		for i in boutons.size():
			var b: Button = boutons[i]
			if not is_instance_valid(b): continue
			var actif: bool = i == int(etat["zone"])
			var fond: Color = UiKit.VERT if actif else UiKit.BOIS_CLAIR
			b.add_theme_stylebox_override("normal", UiKit.panneau(fond, fond.darkened(0.28), 10, 2))
			b.add_theme_stylebox_override("hover", UiKit.panneau(fond.lightened(0.08), fond.darkened(0.28), 10, 2))
			b.add_theme_stylebox_override("pressed", UiKit.panneau(fond.darkened(0.10), fond.darkened(0.32), 10, 2))

	# onglets zones
	var ong := UiKit.hbox(6)
	col.add_child(ong)
	var zones: Array = Data.ZONES.keys()
	for i in zones.size():
		var z: Dictionary = Data.ZONES[zones[i]]
		var b := UiKit.bouton("", UiKit.BOIS_CLAIR, UiKit.TEXT_CLAIR, 14, 40, 10)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var tb := UiKit.hbox(4)
		tb.alignment = BoxContainer.ALIGNMENT_CENTER
		tb.add_child(UiKit.icone_emoji(z["emoji"], 22))
		tb.add_child(UiKit.label(z[Data.langue], 14, UiKit.TEXT_CLAIR))
		UiKit.contenu_bouton(b, tb)
		var idx := i
		b.pressed.connect(func():
			etat["zone"] = idx
			rafraichir.call())
		boutons.append(b)
		ong.add_child(b)

	col.add_child(liste_box)
	rafraichir.call()

	# récompense top 3 (une fois par jour)
	var pr := PanelContainer.new()
	pr.add_theme_stylebox_override("panel", UiKit.panneau_parchemin(12))
	var pv := UiKit.vbox(4)
	pr.add_child(pv)
	var bots := State.bots_classement()
	var rang := State.rang_joueur(bots)
	var txt := Data.t("Ton rang : ", "Your rank: ", "你的名次：")
	if rang <= 3:
		var medailles := ["🥇", "🥈", "🥉"]
		txt += medailles[rang - 1]
	else:
		txt += "#%d" % rang
	pv.add_child(UiKit.label(txt, 18, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER, true))
	var br := UiKit.bouton(Data.t("Réclamer", "Claim", "领取"), UiKit.VERT, UiKit.TEXT_CLAIR, 15, 40, 10)
	if rang > 3 or State.d["event"]["classement_pris"].has(State._jour_actuel()):
		br.disabled = true
		br.text = Data.t("Aucune récompense", "No reward", "暂无奖励") if rang > 3 else "✔"
	else:
		br.pressed.connect(func():
			if State.reclam_recompense_rang():
				UiKit.toast(Data.t("Récompense de rang !", "Rank reward!", "排名奖励！"), UiKit.OR))
	pv.add_child(br)
	col.add_child(pr)

static func liste_rangs(zone_sel_i: int) -> VBoxContainer:
	var col := UiKit.vbox(6)
	var bots := State.bots_classement()
	var bruit := zone_sel_i * 3313
	var scores: Array = []
	for b in bots:
		var pts := int(b["points"])
		if bruit > 0:
			# petite variation par onglet pour donner l'impression de listes distinctes
			pts = (pts + bruit) * (1 + zone_sel_i) / (1 + zone_sel_i)
		scores.append({"nom": b["nom"], "points": pts})
	scores.sort_custom(func(a, b2): return int(a["points"]) > int(b2["points"]))
	var rangs := ["🥇", "🥈", "🥉"]
	var ligne_j: Dictionary = {"nom": Data.t("TOI", "YOU", "我"), "points": State.points_event()}
	var lignes: Array = []
	var insere := false
	for s in scores:
		if not insere and int(s["points"]) < State.points_event():
			lignes.append(ligne_j)
			insere = true
		lignes.append(s)
	if not insere:
		lignes.append(ligne_j)
	for i in lignes.size():
		var s: Dictionary = lignes[i]
		var moi: bool = s["nom"] == ligne_j["nom"] and int(s["points"]) == State.points_event()
		var pan := PanelContainer.new()
		pan.add_theme_stylebox_override("panel", UiKit.panneau(
			Color("#dff0c8") if moi else UiKit.PARCH_FONCE,
			UiKit.VERT_FONCE if moi else Color("#cbb17e"), 12, mois_rang(i)))
		var hb := UiKit.hbox(10)
		pan.add_child(hb)
		var rang_l := UiKit.label(rangs[i] if i < 3 else "%d." % (i + 1), 18, UiKit.TEXT)
		rang_l.custom_minimum_size.x = 44
		hb.add_child(rang_l)
		var nom := UiKit.label(str(s["nom"]), 15, UiKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT, moi)
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(nom)
		hb.add_child(UiKit.label(str(s["points"]), 15, UiKit.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, moi))
		hb.add_child(UiKit.icone_emoji("🌙", 18))
		col.add_child(pan)
	return col

static func mois_rang(i: int) -> int:
	return 3 if i < 5 else 2
