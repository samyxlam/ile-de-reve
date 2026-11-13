# cinematique.gd — Séquence d'ouverture : cinq tableaux générés par outils/atelier_assets.py,
# fondu enchaîné, léger zoom avant, puis titre. Un clic passe.
extends Control

const IMAGES := [
	"res://assets/cine/cine_1_mer.png",
	"res://assets/cine/cine_2_barque.png",
	"res://assets/cine/cine_3_ile.png",
	"res://assets/cine/cine_4_lanternes.png",
	"res://assets/cine/cine_5_titre.png",
]
const DUREE := 3.0
const FONDU := 0.8

var main = null
var _rects: Array = []
var _fini := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 500

	var noir := ColorRect.new()
	noir.color = Color.BLACK
	noir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	noir.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(noir)

	for chemin in IMAGES:
		var t: Texture2D = load(chemin) if ResourceLoader.exists(chemin) else null
		var r := TextureRect.new()
		r.texture = t
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.modulate.a = 0.0
		add_child(r)
		_rects.append(r)

	var sauter := UiKit.label(Data.t("Toucher pour passer", "Tap to skip", "点击跳过"), 14, Color(1, 1, 1, 0.55), HORIZONTAL_ALIGNMENT_CENTER)
	sauter.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	sauter.offset_top = -56
	sauter.offset_bottom = -26
	sauter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sauter)

	await get_tree().process_frame
	for r in _rects:
		(r as TextureRect).pivot_offset = size / 2.0
	_jouer()

func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed:
		_terminer()
	elif ev is InputEventScreenTouch and ev.pressed:
		_terminer()

func _jouer() -> void:
	for i in range(_rects.size()):
		if _fini: return
		var r: TextureRect = _rects[i]
		r.scale = Vector2(1.06, 1.06)
		var t1 := create_tween()
		t1.tween_property(r, "modulate:a", 1.0, FONDU)
		# zoom lent pendant toute la durée du tableau
		var t2 := create_tween()
		t2.tween_property(r, "scale", Vector2(1.0, 1.0), DUREE + FONDU)
		if i > 0:
			var prec: TextureRect = _rects[i - 1]
			var t3 := create_tween()
			t3.tween_property(prec, "modulate:a", 0.0, FONDU)
		if i == _rects.size() - 1:
			_titre()
		await get_tree().create_timer(DUREE).timeout
	_terminer()

func _titre() -> void:
	var v := UiKit.vbox(6)
	v.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	v.offset_left = -260
	v.offset_right = 260
	v.offset_top = -120
	v.offset_bottom = 120
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.modulate.a = 0.0
	add_child(v)
	v.add_child(UiKit.label(Data.t("Île de Rêve", "Island of Dreams", "有梦小岛"), 52, UiKit.PARCH, HORIZONTAL_ALIGNMENT_CENTER, true))
	v.add_child(UiKit.label(Data.t("去有梦的小岛 · prototype", "去有梦的小岛 · prototype", "去有梦的小岛 · 原型"), 18, Color(1, 1, 1, 0.75), HORIZONTAL_ALIGNMENT_CENTER))
	var t := create_tween()
	t.tween_property(v, "modulate:a", 1.0, 1.2)

func _terminer() -> void:
	if _fini: return
	_fini = true
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.45)
	await t.finished
	if main != null:
		main._apres_cinematique()
	queue_free()
