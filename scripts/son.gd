# son.gd — Autoload "Son" : effets sonores synthétisés (outils/generer_sons.py)
# et musique d'ambiance en boucle (outils/generer_musique.py).
# Six lecteurs tournants : un même son peut se chevaucher sans se couper.
extends Node

const NOMS := ["fusion", "piece", "clic", "erreur", "succes", "construire"]

var _flux := {}
var _lecteurs: Array = []
var _suivant := 0
var _musique: AudioStreamPlayer = null
var muet := false

func _ready() -> void:
	for n in NOMS:
		var chemin := "res://assets/sons/%s.wav" % n
		if ResourceLoader.exists(chemin):
			_flux[n] = load(chemin)
	for i in 6:
		var j := AudioStreamPlayer.new()
		add_child(j)
		_lecteurs.append(j)
	muet = bool(State.d.get("muet", false))
	# Musique d'ambiance : boucle 72 s, volume bas, suit le même interrupteur muet.
	_musique = AudioStreamPlayer.new()
	add_child(_musique)
	var chemin_musique := "res://assets/musique/ambiance.ogg"
	if ResourceLoader.exists(chemin_musique):
		var flux: AudioStream = load(chemin_musique)
		if flux is AudioStreamOggVorbis:
			flux.loop = true
		_musique.stream = flux
		_musique.volume_db = -9.0
		if not muet:
			_musique.play()

func jouer(nom: String, volume_db := 0.0) -> void:
	if muet or not _flux.has(nom): return
	var j: AudioStreamPlayer = _lecteurs[_suivant]
	_suivant = (_suivant + 1) % _lecteurs.size()
	j.stream = _flux[nom]
	j.volume_db = volume_db
	j.play()

func basculer_muet() -> bool:
	muet = not muet
	State.d["muet"] = muet
	State.sauver()
	if muet:
		_musique.stop()
	elif _musique.stream != null:
		_musique.play()
	return muet
