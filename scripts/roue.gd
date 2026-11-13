# roue.gd — Disque de la roue de la fortune. Tourne, s'arrête sur le secteur tiré,
# puis émet `fini(index)` : c'est l'appelant qui crédite le gain.
extends Control
signal fini(index)

const COULEURS := [
	Color("#f6e3bd"), Color("#dfecc6"), Color("#f7d9cf"), Color("#d8e8ef"),
	Color("#f3e2b6"), Color("#e6d9f0"), Color("#f7d9cf"), Color("#dfecc6"),
]

var _en_cours := false
var _n := 0
var _etiquettes_liste: Array = []

func _ready() -> void:
	_n = Data.ROUE.size()
	custom_minimum_size = Vector2(420, 420)
	pivot_offset = custom_minimum_size * 0.5
	_etiquettes()

func _etiquettes() -> void:
	var c := custom_minimum_size * 0.5
	var rayon := custom_minimum_size.x * 0.30
	for i in _n:
		var a := deg_to_rad(-90.0 + i * 360.0 / _n + 180.0 / _n)
		var s: Dictionary = Data.ROUE[i]
		var l := UiKit.label(str(s["emoji"]), 26, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
		l.size = Vector2(56, 34)
		l.pivot_offset = l.size * 0.5
		l.position = c + Vector2(cos(a), sin(a)) * rayon - l.size * 0.5
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(l)
		_etiquettes_liste.append(l)
		var v := UiKit.label(_valeur(s), 13, Color("#6b5433"), HORIZONTAL_ALIGNMENT_CENTER, true)
		v.size = Vector2(56, 18)
		v.pivot_offset = v.size * 0.5
		v.position = c + Vector2(cos(a), sin(a)) * rayon + Vector2(-28, 16)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(v)
		_etiquettes_liste.append(v)

# Les étiquettes restent droites pendant que le disque tourne : sinon, à l'arrêt,
# la moitié du texte se retrouve à l'envers.
func _process(_delta: float) -> void:
	for l in _etiquettes_liste:
		if is_instance_valid(l):
			(l as Control).rotation = -rotation

func _valeur(s: Dictionary) -> String:
	if int(s["energie"]) > 0: return "+%d" % int(s["energie"])
	if int(s["coins"]) > 0: return "+%d" % int(s["coins"])
	return "+%d" % int(s["feuilles"])

func _draw() -> void:
	var c := size * 0.5
	var r: float = min(size.x, size.y) * 0.5 - 6.0
	if _n <= 0: return
	for i in _n:
		var a0 := deg_to_rad(-90.0 + i * 360.0 / _n)
		var a1 := deg_to_rad(-90.0 + (i + 1) * 360.0 / _n)
		var pts := PackedVector2Array([c])
		for k in range(13):
			var a: float = lerpf(a0, a1, k / 12.0)
			pts.append(c + Vector2(cos(a), sin(a)) * r)
		draw_colored_polygon(pts, COULEURS[i % COULEURS.size()])
		draw_line(c, c + Vector2(cos(a0), sin(a0)) * r, Color(1, 1, 1, 0.6), 2.0)
	draw_arc(c, r, 0.0, TAU, 72, Color("#8f6a4c"), 5.0, true)
	draw_circle(c, r * 0.13, Color("#fdf6e9"))
	draw_arc(c, r * 0.13, 0.0, TAU, 32, Color("#8f6a4c"), 3.0, true)

func tourner(index: int) -> void:
	if _en_cours: return
	_en_cours = true
	# On veut que le centre du secteur `index` finisse sous le curseur (en haut).
	var cible := deg_to_rad(-(index * 360.0 / _n + 180.0 / _n))
	var depart := rotation
	var delta := fmod(cible - depart, TAU)
	if delta < 0.0: delta += TAU
	var arrivee := depart + delta + 5.0 * TAU
	var t := create_tween()
	t.tween_property(self, "rotation", arrivee, 3.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await t.finished
	_en_cours = false
	fini.emit(index)
