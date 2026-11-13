# shop_ui.gd — Boutique (énergie, packs simulés, VIP simulé) + paramètres (langue, sauvegarde) +okedex.
extends RefCounted

static func ouvrir(main) -> void:
	var m := UiKit.modale(Data.t("Boutique", "Shop", "商店"), 640, 960)
	(main as Node).get_tree().root.add_child.call_deferred(m["racine"])
	var c: VBoxContainer = m["contenu"]

	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(620, 860)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	c.add_child(sc)
	var col := UiKit.vbox(10)
	sc.add_child(col)

	# ---------------- énergie
	col.add_child(_titre(Data.t("Énergie", "Energy", "体力"), "⚡"))
	col.add_child(_achat(
		Data.t("+20 ⚡ pour 10 🍃", "+20 ⚡ for 10 🍃", "10 🍃 兑换 +20 ⚡"), 10,
		func():
			if State.depenser_feuilles(10):
				State.d["energie"] = mini(State.CAP_ENERGIE, State.energie() + 20)
				State.maj.emit()
				UiKit.toast(Data.t("Énergie régénérée !", "Energy topped up!", "体力已恢复！"), UiKit.OR)))
	col.add_child(_achat(
		Data.t("+50 ⚡ pour 25 🍃", "+50 ⚡ for 25 🍃", "25 🍃 兑换 +50 ⚡"), 25,
		func():
			if State.depenser_feuilles(25):
				State.d["energie"] = mini(State.CAP_ENERGIE, State.energie() + 50)
				State.maj.emit()
				UiKit.toast(Data.t("Énergie régénérée !", "Energy topped up!", "体力已恢复！"), UiKit.OR)))

	# ---------------- packs (affichage fidèle à l'original, sans paiement réel)
	col.add_child(_titre(Data.t("Packs (simulés)", "Packs (simulated)", "礼包（模拟）"), "🎒"))
	var packs := [
		{"nom": ["Pack Pluie dedré", "Drizzle pack", "顺手礼包"], "prix": "¥6",  "desc": [":  🪙×500 + ⚡×100", "500 coins + 100 energy", "铜钱×500 + 体力×100"]},
		{"nom": ["Pack VIP", "VIP pack", "VIP礼包"], "prix": "¥30", "desc": ["VIP + 🌙×150", "VIP + 150 pts", "VIP + 🌙×150"]},
		{"nom": ["Pack 豪华 VIP", "Deluxe VIP pack", "豪华VIP礼包"], "prix": "¥45", "desc": ["VIP豪华 + 🌙×200", "Deluxe VIP + 200 pts", "豪华VIP + 🌙×200"]},
	]
	for p in packs:
		var pan := PanelContainer.new()
		pan.add_theme_stylebox_override("panel", UiKit.panneau_parchemin(12))
		var hb := UiKit.hbox(10)
		pan.add_child(hb)
		var cv := UiKit.vbox(2)
		cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(cv)
		cv.add_child(UiKit.label(Data.t(p["nom"][0], p["nom"][1], p["nom"][2]), 16, UiKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true))
		cv.add_child(UiKit.label(Data.t(p["desc"][0], p["desc"][1], p["desc"][2]), 13, Color("#8a6d3d")))
		var bt := UiKit.bouton(p["prix"], UiKit.OR, UiKit.TEXT_CLAIR, 15, 36, 10)
		bt.custom_minimum_size.x = 80
		bt.pressed.connect(func(): UiKit.toast(Data.t("Prototype : aucun paiement réel.", "Prototype: no real payment.", "演示版：无真实付款。")))
		hb.add_child(bt)
		col.add_child(pan)

	# ---------------- paramètres
	col.add_child(_titre(Data.t("Paramètres", "Settings", "设置"), "⚙"))
	var hb_lang := UiKit.hbox(8)
	col.add_child(hb_lang)
	for lg in Data.LANGUES:
		var lg_b := UiKit.bouton(Data.LANGUE_LIBELLE[lg], UiKit.VERT if State.langue_actuelle() == lg else UiKit.BOIS_CLAIR, UiKit.TEXT_CLAIR, 14, 34, 10)
		lg_b.custom_minimum_size.x = 150
		lg_b.pressed.connect(func():
			State.d["langue"] = lg
			Data.langue = lg
			State.sauver()
			main._construire())
		hb_lang.add_child(lg_b)
	var vip_b := UiKit.bouton(
		Data.t("Simuler VIP : ", "Simulate VIP: ", "模拟VIP：") + [Data.t("non", "off", "否"), Data.t("oui", "on", "是")][1 if State.d["event"]["vip"] else 0],
		UiKit.VERT if State.d["event"]["vip"] else UiKit.BOIS_CLAIR, UiKit.TEXT_CLAIR, 14, 38, 10)
	vip_b.pressed.connect(func():
		State.acheter_vip(not State.d["event"]["vip"])
		State.sauver())
	col.add_child(vip_b)
	var son_b := UiKit.bouton(_libelle_son(), UiKit.VERT if not Son.muet else UiKit.BOIS_CLAIR, UiKit.TEXT_CLAIR, 14, 38, 10)
	son_b.pressed.connect(func():
		Son.basculer_muet()
		son_b.text = _libelle_son()
		son_b.add_theme_stylebox_override("normal", UiKit.panneau(
			UiKit.VERT if not Son.muet else UiKit.BOIS_CLAIR, UiKit.BOIS_FONCE, 14, 2)))
	col.add_child(son_b)
	var raz := UiKit.bouton(Data.t("Réinitialiser la sauvegarde", "Reset save", "重置存档"), UiKit.ROUGE, UiKit.TEXT_CLAIR, 14, 38, 10)
	raz.pressed.connect(func(): _reset(raz, main))
	col.add_child(raz)

	# ---------------- dex
	col.add_child(_titre(Data.t("图鉴", "Item catalog", "图鉴"), "📜"))
	var gr := GridContainer.new()
	gr.columns = 5
	gr.add_theme_constant_override("h_separation", 8)
	gr.add_theme_constant_override("v_separation", 8)
	col.add_child(gr)
	for id_objet in Data.ITEMS:
		var ic = UiKit.icone_objet(id_objet, 62, true)
		ic.tooltip_text = Data.nom_objet(id_objet)
		gr.add_child(ic)

static func _libelle_son() -> String:
	var etat := Data.t("coupé", "off", "关") if Son.muet else Data.t("activé", "on", "开")
	return Data.t("Son : ", "Sound: ", "音效：") + etat

static func _titre(txt: String, emoji: String) -> HBoxContainer:
	var hb := UiKit.hbox(8)
	hb.add_child(UiKit.icone_emoji(emoji, 26))
	var l := UiKit.label(txt, 20, UiKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true)
	hb.add_child(l)
	return hb

static func _achat(txt: String, cout_feuilles: int, cb: Callable) -> PanelContainer:
	var pan := PanelContainer.new()
	pan.add_theme_stylebox_override("panel", UiKit.panneau_parchemin(12))
	var hb := UiKit.hbox(10)
	pan.add_child(hb)
	var l := UiKit.label(txt, 15, UiKit.TEXT)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(l)
	var bt := UiKit.bouton(("🍃 %d" % cout_feuilles) if cout_feuilles > 0 else "🎁", UiKit.VERT, UiKit.TEXT_CLAIR, 14, 36, 10)
	bt.custom_minimum_size.x = 80
	bt.pressed.connect(cb)
	hb.add_child(bt)
	return pan

static func _reset(bt: Button, main) -> void:
	if bt.has_meta("confirm"):
		DirAccess.remove_absolute("user://save.json")
		State.nouveau_save()
		State.sauver()
		UiKit.toast(Data.t("Sauvegarde réinitialisée.", "Save reset.", "存档已重置。"), UiKit.OR)
		main._construire()
	else:
		bt.set_meta("confirm", true)
		bt.text = Data.t("Confirmer ?", "Confirm?", "确认？")
		UiKit.toast(Data.t("Appuie encore pour confirmer.", "Press again to confirm.", "再按一次确认。"))
