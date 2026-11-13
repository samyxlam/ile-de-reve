# ui_kit.gd — Aides d'interface. Tout l'art est généré au runtime (aucun asset externe).
# Icônes vectorielles d'interface ; emoji conservés en repli et pour les icônes non atlascées.
class_name UiKit
extends RefCounted

# ------------------------------------------------------------- palette
const PARCH := Color("#f7edda")
const PARCH_FONCE := Color("#eaddc2")
const BOIS := Color("#b5773a")
const BOIS_FONCE := Color("#7d4e1e")
const BOIS_CLAIR := Color("#d9a05f")
const VERT := Color("#8ec63f")
const VERT_FONCE := Color("#5f962c")
const ROUGE := Color("#e0503f")
const OR := Color("#e8b53a")
const TEXT: Color = Color("#4a3a28")
const TEXT_CLAIR := Color("#fff8ea")

static var _theme: Theme = null
static var _font: Font = null
const ICONES_ATLAS := {
	"⚡": 0, "🪙": 1, "🍃": 2, "🌙": 3, "🧩": 4,
	"🏝": 5, "🏝️": 5, "🔍": 6, "🎁": 7, "🏆": 8, "⚙": 9, "⚙️": 9,
}

# ------------------------------------------------------------- police
# Polices libres packagées (Google Noto, licence OFL) : rendu identique natif ET web.
# CJK + emojis couleur, indépendant des polices système.
# Sous-ensembles générés par outils/sous_ensemble_polices.py — les polices
# complètes vivent dans fonts/source/ (hors export, .gdignore).
static func font() -> Font:
	if _font == null:
		var texte: Font = load("res://fonts/cjk-sous-ensemble.otf")
		var emoji: Font = load("res://fonts/emoji-sous-ensemble.ttf")
		if emoji != null:
			texte.fallbacks = [emoji]
		_font = texte
	return _font

static func theme() -> Theme:
	if _theme != null: return _theme
	_theme = Theme.new()
	_theme.default_font = font()
	_theme.default_font_size = 16
	# Boutons
	var n := panneau(VERT, VERT_FONCE, 14, 3)
	var h := n.duplicate()
	h.bg_color = VERT.lightened(0.12)
	var p := n.duplicate()
	p.bg_color = VERT.darkened(0.12)
	_theme.set_stylebox("normal", "Button", n)
	_theme.set_stylebox("hover", "Button", h)
	_theme.set_stylebox("pressed", "Button", p)
	_theme.set_stylebox("disabled", "Button", _sb_gris())
	_theme.set_color("font_color", "Button", TEXT_CLAIR)
	_theme.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.7))
	return _theme

static func _sb_gris() -> StyleBoxFlat:
	return panneau(Color("#a89a86"), Color("#8a7d6c"), 14, 3)

# ------------------------------------------------------------- styles
static func panneau(bg: Color, bord: Color, rayon := 16, epaisseur := 3) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = bord
	sb.set_border_width_all(epaisseur)
	sb.set_corner_radius_all(rayon)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

static func panneau_bois(_rayon := 18) -> StyleBox:
	var sb := panneau_tex("cadre_bois", 22, 10)
	# l'ombre portée n'existe que sur StyleBoxFlat ; le cadre texturé a déjà son biseau
	if sb is StyleBoxFlat:
		sb.shadow_color = Color(0, 0, 0, 0.22)
		sb.shadow_size = 6
	return sb

static func panneau_parchemin(_rayon := 16) -> StyleBox:
	return panneau_tex("cadre_parchemin", 22, 10)

# Cadres dessinés par outils/atelier_assets.py (marimo), étirés en 9 tranches.
# Si l'asset manque, on retombe sur un aplat : le jeu reste jouable sans les textures.
static func panneau_tex(nom: String, marge := 22, contenu := 10) -> StyleBox:
	var chemin := "res://assets/ui/%s.png" % nom
	if not ResourceLoader.exists(chemin):
		return panneau(PARCH, Color("#cbb17e"), 14, 3)
	var sb := StyleBoxTexture.new()
	sb.texture = load(chemin)
	sb.texture_margin_left = marge
	sb.texture_margin_top = marge
	sb.texture_margin_right = marge
	sb.texture_margin_bottom = marge
	sb.content_margin_left = contenu
	sb.content_margin_right = contenu
	sb.content_margin_top = contenu * 0.8
	sb.content_margin_bottom = contenu * 0.8
	return sb

# ------------------------------------------------------------- widgets
static func label(txt: String, taille := 15, coul: Color = TEXT, align := HORIZONTAL_ALIGNMENT_LEFT, gras := false) -> Label:
	var l := Label.new()
	l.text = txt
	l.horizontal_alignment = align
	# Override explicite : le fallback emoji ne suit pas Theme.default_font sur le web.
	l.add_theme_font_override("font", font())
	l.add_theme_font_size_override("font_size", taille)
	l.add_theme_color_override("font_color", coul)
	if gras:
		l.add_theme_font_size_override("font_size", taille)
		l.add_theme_constant_override("bold_font", 0)
	return l

static func bouton(txt: String, bg := VERT, fg: Color = TEXT_CLAIR, taille_txt := 17, hauteur := 46, rayon := 14) -> Button:
	var b := Button.new()
	b.text = txt
	b.add_theme_font_override("font", font())
	b.custom_minimum_size = Vector2(0, hauteur)
	b.add_theme_font_size_override("font_size", taille_txt)
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", fg)
	b.add_theme_color_override("font_pressed_color", fg)
	var sb := panneau(bg, bg.darkened(0.25), rayon, 2)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb.duplicate())
	b.add_theme_stylebox_override("pressed", sb.duplicate())
	b.add_theme_stylebox_override("disabled", _sb_gris())
	return b

static func vbox(sep := 8) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v

static func hbox(sep := 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h

static func vide(taille: Vector2) -> Control:
	var c := Control.new()
	c.custom_minimum_size = taille
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

# Un Button n'est pas un Container : un enfant ajouté dessus reste collé en (0,0) et
# garde sa taille minimale (un Label en clip_text tombe même à 0 px de large).
# Ce helper force le contenu à remplir le bouton, centré, et neutralise la souris.
static func contenu_bouton(b: Button, c: Control, marge_x := 6, marge_y := 2) -> void:
	b.add_child(c)
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.offset_left = marge_x
	c.offset_right = -marge_x
	c.offset_top = marge_y
	c.offset_bottom = -marge_y
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for e in c.get_children():
		if e is Control:
			(e as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE

# ------------------------------------------------------------ icônes d'objets générées
# Pastille colorée par chaîne + emoji + badge de niveau. tail = pixels.
static func icone_objet(item_id: String, tail := 64, badge := true) -> Control:
	var info = Data.ITEMS.get(item_id)
	var root := Control.new()
	root.custom_minimum_size = Vector2(tail, tail)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if info == null:
		root.add_child(vide(Vector2(tail, tail)))
		return root

	# Illustration générée (assets/objets) : elle remplace la pastille + emoji.
	var chemin := Data.chemin_icone(item_id)
	if chemin != "":
		var tr := TextureRect.new()
		tr.texture = load(chemin)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(tr)
		if badge and int(info["niveau"]) > 1:
			root.add_child(_badge_niveau(int(info["niveau"]), tail))
		return root

	# Repli : pastille colorée + emoji, si l'illustration n'a pas été générée.
	var pc := PanelContainer.new()
	var col: Color = info["couleur"]
	var bord: Color = info["bord"]
	var nb := int(tail / 10.0)
	pc.add_theme_stylebox_override("panel", panneau(col, bord, nb, maxi(2, tail / 24)))
	pc.custom_minimum_size = Vector2(tail, tail)
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var emb := CenterContainer.new()
	emb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var e := label(info["emoji"], int(tail * 0.52), TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	e.mouse_filter = Control.MOUSE_FILTER_IGNORE
	emb.add_child(e)
	pc.add_child(emb)
	root.add_child(pc)
	if badge and int(info["niveau"]) > 1:
		root.add_child(_badge_niveau(int(info["niveau"]), tail))
	return root

# Pastille de niveau, posée en haut à droite de l'icône.
static func _badge_niveau(niveau: int, tail: float) -> Control:
	var b := label("N%d" % niveau, int(max(9.0, tail * 0.22)), TEXT_CLAIR, HORIZONTAL_ALIGNMENT_CENTER)
	var bp := PanelContainer.new()
	bp.add_theme_stylebox_override("panel", panneau(Color(0.86, 0.44, 0.32, 0.96), Color(0.55, 0.24, 0.16), 7, 1))
	bp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bp.add_child(b)
	bp.custom_minimum_size = Vector2(tail * 0.46, tail * 0.28)
	bp.position = Vector2(tail * 0.54, 0)
	return bp

static func icone_emoji(emoji: String, tail := 40, fond: Color = Color(0, 0, 0, 0), bord := Color(0, 0, 0, 0)) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(tail, tail)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sprite := _icone_atlas(emoji, tail)
	if fond.a > 0:
		var pc := PanelContainer.new()
		pc.add_theme_stylebox_override("panel", panneau(fond, bord, tail / 4, maxi(2, tail / 20)))
		pc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pc.custom_minimum_size = Vector2(tail, tail)
		pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if sprite != null:
			sprite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			pc.add_child(sprite)
		else:
			var l := label(emoji, int(tail * 0.6), TEXT, HORIZONTAL_ALIGNMENT_CENTER)
			pc.add_child(l)
		c.add_child(pc)
	elif sprite != null:
		sprite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		c.add_child(sprite)
	else:
		var l := label(emoji, int(tail * 0.8), TEXT, HORIZONTAL_ALIGNMENT_CENTER)
		l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		c.add_child(l)
	return c

static func _icone_atlas(emoji: String, tail: int) -> TextureRect:
	if not ICONES_ATLAS.has(emoji):
		return null
	var chemin := "res://assets/ui/icones_atlas.svg"
	if not ResourceLoader.exists(chemin):
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = load(chemin)
	atlas.region = Rect2(int(ICONES_ATLAS[emoji]) * 48, 0, 48, 48)
	var image := TextureRect.new()
	image.texture = atlas
	image.custom_minimum_size = Vector2(tail, tail)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image

# ------------------------------------------------------------ modales
# Retourne {racine, contenu, fermer}. racine : voile plein écran + panneau central.
static func modale(titre: String, largeur := 620, hauteur := 0) -> Dictionary:
	var voile := ColorRect.new()
	voile.color = Color(0, 0, 0, 0.45)
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	voile.add_child(centre)
	var cadre := PanelContainer.new()
	cadre.add_theme_stylebox_override("panel", panneau_bois(22))
	var min_x := Vector2(largeur, 0)
	if hauteur > 0: min_x.y = hauteur
	cadre.custom_minimum_size = min_x
	centre.add_child(cadre)
	var v := vbox(10)
	cadre.add_child(v)
	# bandeau titre
	var bande := hbox(8)
	var t := label(titre, 24, PARCH, HORIZONTAL_ALIGNMENT_CENTER, true)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bande.add_child(t)
	var croix := bouton("×", ROUGE, TEXT_CLAIR, 18, 40, 20)
	bande.add_child(croix)
	v.add_child(bande)
	var contenu := vbox(10)
	v.add_child(contenu)
	croix.pressed.connect(func(): fermer(voile))
	return {"racine": voile, "contenu": contenu, "cadre": cadre, "croix": croix}

static func fermer(racine: Control) -> void:
	if is_instance_valid(racine):
		racine.queue_free()

# ------------------------------------------------------------- toast
static func toast(txt: String, coul: Color = PARCH) -> void:
	var ml := Engine.get_main_loop()
	if ml == null: return
	var root: Node = (ml as SceneTree).root
	var voile := label(txt, 20, TEXT, HORIZONTAL_ALIGNMENT_CENTER, true)
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", panneau(coul, BOIS_FONCE, 20, 3))
	pc.add_child(voile)
	pc.z_index = 1000
	root.add_child(pc)
	pc.anchors_preset = Control.PRESET_CENTER_BOTTOM
	pc.anchor_left = 0.5
	pc.anchor_right = 0.5
	pc.anchor_top = 1.0
	pc.anchor_bottom = 1.0
	pc.offset_left = -200
	pc.offset_right = 200
	pc.offset_top = -150
	pc.offset_bottom = -90
	pc.modulate.a = 0.0
	var tw := pc.create_tween()
	tw.tween_property(pc, "modulate:a", 1.0, 0.15)
	tw.tween_interval(1.6)
	tw.tween_property(pc, "modulate:a", 0.0, 0.35)
	tw.tween_callback(pc.queue_free)

# ------------------------------------------------------------- temps
static func fmt_duree(sec: float) -> String:
	sec = max(0, int(sec))
	var j := int(sec) / 86400
	var h := (int(sec) % 86400) / 3600
	var m := (int(sec) % 3600) / 60
	var s := int(sec) % 60
	if j > 0: return "%dj %dh" % [j, h]
	if h > 0: return "%dh %02dm" % [h, m]
	if m > 0: return "%dm %02ds" % [m, s]
	return "%ds" % s
