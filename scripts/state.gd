# state.gd — État global, économie, sauvegarde. Autoload "State" (chargé après "Data").
extends Node

signal maj                  # quelconque : monnaies, énergie, événement…
signal commandes_maj        # la liste des commandes a changé
signal taches_maj           # progression des tâches quotidiennes

const FICHIER := "user://save.json"
const CAP_ENERGIE := 100
const REGEN_ENERGIE := 60.0        # secondes par point
const MAX_PALIERS := 15
const COMMANDE_DUREE := 2700.0     # 45 min avant qu'une commande soit remplacée

var d := {}                        # tout ce qui persiste

func _ready() -> void:
	charger()
	_regen_hors_ligne()
	_init_quotidien()
	var t := Timer.new()
	t.wait_time = 5.0
	t.timeout.connect(_on_tick)
	add_child(t)
	t.start()

# ------------------------------------------------------------------ helpers d'accès
func _v(cle: String, defaut) -> void:
	if not d.has(cle):
		d[cle] = defaut

func nouveau_save() -> void:
	d = {
		"version": 2,
		"coins": 77, "feuilles": 43, "energie": 60, "energie_ts": 0,
		"xp": 0, "niveau": 1,
		"langue": "fr",
		"plateau": {},                       # "c{col}r{row}" -> "bois-2"
		"gen": {},                           # "idx" -> {chaine, charges, pret}
		"cases_verrouillees": {},            # index -> prix
		"commandes": [],                     # [{obj, qty, coins, feuilles}]
		"jour": {"date": "", "taches": {}, "cadeau_pris": false},
		"stats": {"fusions": 0, "commandes": 0, "coins_gagnes": 0, "fouilles": 0},
		"event": {"points": 0, "fin": 0, "vip": false, "vip_lux": false,
			"pris_gratuit": [], "pris_vip": [], "classement_pris": []},
		"ile": {"construits": {}, "chantiers": {}, "collecte": 0},   # chantiers : clé -> ts de fin
		"fouille": {"finis": {}, "prochain": {}},     # prochain : id -> ts
		"roue": {"pret": 0, "total": 0},              # roue de la fortune : prochaine rotation
		"don": {"pret": 0},                           # 天赐好礼 : gros cadeau minuté
		"tuto": {},
	}

func charger() -> void:
	nouveau_save()
	if FileAccess.file_exists(FICHIER):
		var f := FileAccess.open(FICHIER, FileAccess.READ)
		if f:
			var parsed = JSON.parse_string(f.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				var versions: Dictionary = parsed
				for k in versions:
					d[k] = versions[k]
	# v2 : plateau 7×10, générateurs posés sur la grille, caisses verrouillées en bas.
	# Les sauvegardes v1 gardent des objets sur des cases devenues verrouillées : on repart propre.
	if int(d.get("version", 1)) < 2:
		d["plateau"] = {}
		d["gen"] = {}
		d["cases_verrouillees"] = {}
		d["commandes"] = []
		d["tuto_sem"] = false
		d["version"] = 2

func sauver() -> void:
	var f := FileAccess.open(FICHIER, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		sauver()

func _on_tick() -> void:
	_regen_energie()
	commandes_expirees()
	sauver()
	maj.emit()

# ------------------------------------------------------------------ monnaies
func coins() -> int: return int(d["coins"])
func feuilles() -> int: return int(d["feuilles"])
func energie() -> int: return int(d["energie"])

func ajouter_coins(n: int) -> void:
	d["coins"] = int(d["coins"]) + n
	if n > 0:
		d["stats"]["coins_gagnes"] += n
		_progresser_tache("coins_earned", n)
	maj.emit(); taches_maj.emit()

func depenser_coins(n: int) -> bool:
	if int(d["coins"]) < n: return false
	d["coins"] = int(d["coins"]) - n
	maj.emit()
	return true

func ajouter_feuilles(n: int) -> void:
	d["feuilles"] = int(d["feuilles"]) + n
	maj.emit()

func depenser_feuilles(n: int) -> bool:
	if int(d["feuilles"]) < n: return false
	d["feuilles"] = int(d["feuilles"]) - n
	maj.emit()
	return true

func _regen_energie() -> void:
	var ts: float = Time.get_unix_time_from_system()
	var dernier: float = float(d.get("energie_ts", ts))
	if int(d["energie"]) >= CAP_ENERGIE:
		d["energie_ts"] = ts
		return
	var gagne := int((ts - dernier) / REGEN_ENERGIE)
	if gagne > 0:
		d["energie"] = min(CAP_ENERGIE, int(d["energie"]) + gagne)
		d["energie_ts"] = dernier + gagne * REGEN_ENERGIE
		maj.emit()

func _regen_hors_ligne() -> void:
	d["energie_ts"] = Time.get_unix_time_from_system()
	_regen_energie()

func depenser_energie(n: int = 1) -> bool:
	_regen_energie()
	if int(d["energie"]) < n: return false
	d["energie"] = int(d["energie"]) - n
	maj.emit()
	return true

func temps_prochain_energie() -> float:
	if int(d["energie"]) >= CAP_ENERGIE: return 0.0
	var ts: float = Time.get_unix_time_from_system()
	var dernier: float = float(d.get("energie_ts", ts))
	return max(0.0, REGEN_ENERGIE - (ts - dernier))

# ------------------------------------------------------------------ xp / prospérité
func xp_par_niveau() -> int:
	return 60 + Data.LEVELS_PER_CHAIN * 20 * int(d["niveau"])

func ajouter_xp(n: int) -> void:
	d["xp"] = int(d["xp"]) + n
	while int(d["xp"]) >= xp_par_niveau():
		d["xp"] = int(d["xp"]) - xp_par_niveau()
		d["niveau"] = int(d["niveau"]) + 1
	maj.emit()

func prosperite_totale() -> int:
	var total := 0
	var construits: Dictionary = d["ile"]["construits"]
	for zone in Data.ZONES:
		for b in Data.ZONES[zone]["batiments"]:
			if construits.has(b["cle"]):
				total += int(b["prosperite"])
	return total

# ------------------------------------------------------------------ plateau : cases verrouillees
# Comme dans le jeu de reference : un bloc de caisses en bois sur les deux rangees du bas,
# ouvert au milieu. On debloque progressivement en payant des pieces.
func init_cases_verrouillees() -> void:
	if not d["cases_verrouillees"].is_empty(): return
	var r := Data.BOARD_ROWS - 1
	var cibles := [
		r * Data.BOARD_COLS + 1, r * Data.BOARD_COLS + 0,
		(r - 1) * Data.BOARD_COLS + 1, (r - 1) * Data.BOARD_COLS + 0,
		r * Data.BOARD_COLS + 2, r * Data.BOARD_COLS + 6,
		(r - 1) * Data.BOARD_COLS + 6, r * Data.BOARD_COLS + 5,
		(r - 1) * Data.BOARD_COLS + 5, r * Data.BOARD_COLS + 4,
	]
	var prix := [60, 90, 130, 180, 240, 320, 420, 560, 720, 900]
	for i in cibles.size():
		d["cases_verrouillees"][str(cibles[i])] = prix[i]

func est_verrouillee(idx: int) -> bool:
	return d["cases_verrouillees"].has(str(idx))

# ------------------------------------------------------------------ générateurs posés sur le plateau
func init_generateurs() -> void:
	if not d["gen"].is_empty(): return
	var chaines: Array = Data.CHAINS.keys()
	for i in Data.GEN_POSITIONS.size():
		d["gen"][str(Data.GEN_POSITIONS[i])] = {
			"chaine": chaines[i % chaines.size()],
			"charges": Data.GEN_CHARGES,
			"pret": 0.0,
		}

func gen_at(idx: int) -> Dictionary:
	return d["gen"].get(str(idx), {})

func gen_est_gen(idx: int) -> bool:
	return d["gen"].has(str(idx))

func gen_recharge_restante(idx: int) -> float:
	var g := gen_at(idx)
	if g.is_empty() or int(g.get("charges", 0)) > 0: return 0.0
	return max(0.0, float(g.get("pret", 0.0)) - Time.get_unix_time_from_system())

func gen_consommer(idx: int) -> bool:
	var g := gen_at(idx)
	if g.is_empty(): return false
	if int(g["charges"]) <= 0:
		if float(g.get("pret", 0.0)) > Time.get_unix_time_from_system(): return false
		g["charges"] = Data.GEN_CHARGES      # recharge terminée
	g["charges"] = int(g["charges"]) - 1
	if int(g["charges"]) <= 0:
		g["pret"] = Time.get_unix_time_from_system() + Data.GEN_RECHARGE
	maj.emit()
	return true

func deplacer_gen(src: int, dst: int) -> bool:
	if not d["gen"].has(str(src)) or d["gen"].has(str(dst)): return false
	d["gen"][str(dst)] = d["gen"][str(src)]
	d["gen"].erase(str(src))
	return true

func prix_case(idx: int) -> int:
	return int(d["cases_verrouillees"][str(idx)])

func deverrouiller_case(idx: int) -> bool:
	var p := prix_case(idx)
	if not depenser_coins(p): return false
	d["cases_verrouillees"].erase(str(idx))
	maj.emit()
	return true

# ------------------------------------------------------------------ commandes (lapins)
func nb_commandes() -> int:
	return d["commandes"].size()

func _generer_commande() -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.randomize()
	var chaines: Array = Data.CHAINS.keys()
	var chaine: String = chaines[r.randi_range(0, chaines.size() - 1)]
	var max_lvl := clampi(2 + int(d["niveau"]) / 4, 2, 5)
	var lvl := r.randi_range(2, max_lvl)
	var obj := "%s-%d" % [chaine, lvl]
	var qty := 1
	if lvl <= 2: qty = r.randi_range(2, 3)
	elif lvl <= 4: qty = r.randi_range(1, 2)
	var coins_r := qty * (10 + lvl * lvl * 2 + r.randi_range(0, 6))
	var feuilles_r := 0
	if r.randf() < 0.25: feuilles_r = 1 + (1 if lvl >= 4 else 0)
	return {"obj": obj, "qty": qty, "coins": coins_r, "feuilles": feuilles_r,
		"expire": Time.get_unix_time_from_system() + COMMANDE_DUREE}

# Une commande non livrée à temps disparaît : c'est ce qui crée la pression du jeu source.
func commandes_expirees() -> bool:
	var now := Time.get_unix_time_from_system()
	var change := false
	for i in range(d["commandes"].size()):
		if float(d["commandes"][i].get("expire", 0)) <= now:
			d["commandes"][i] = _generer_commande()
			change = true
	if change:
		commandes_maj.emit()
	return change

func temps_commande(i: int) -> float:
	if i < 0 or i >= d["commandes"].size(): return 0.0
	return max(0.0, float(d["commandes"][i].get("expire", 0)) - Time.get_unix_time_from_system())

func remplir_commandes() -> void:
	init_cases_verrouillees()
	init_generateurs()
	while d["commandes"].size() < Data.MAX_ORDER_SLOTS:
		d["commandes"].append(_generer_commande())
	commandes_maj.emit()

func livraison_possible(c: Dictionary) -> bool:
	var compte := compter_objet(c["obj"])
	return compte >= int(c["qty"])

func compter_objet(obj: String) -> int:
	var n := 0
	for k in d["plateau"]:
		if d["plateau"][k] == obj: n += 1
	return n

func livrer(idx: int) -> bool:
	if idx < 0 or idx >= d["commandes"].size(): return false
	var c: Dictionary = d["commandes"][idx]
	if not livraison_possible(c): return false
	var reste: int = int(c["qty"])
	for k in d["plateau"].keys():
		if reste <= 0: break
		if d["plateau"][k] == c["obj"]:
			d["plateau"].erase(k)
			reste -= 1
	d["commandes"].remove_at(idx)
	d["commandes"].append(_generer_commande())
	ajouter_coins(int(c["coins"]))
	if int(c["feuilles"]) > 0: ajouter_feuilles(int(c["feuilles"]))
	ajouter_xp(3 + int(c["obj"].get_slice("-", 1)) * 3)
	d["stats"]["commandes"] += 1
	_progresser_tache("orders", 1)
	_ajouter_points_event(10 * int(c["obj"].get_slice("-", 1)))
	commandes_maj.emit(); taches_maj.emit(); maj.emit()
	return true

# ------------------------------------------------------------------ fusions / stats
func noter_fusion() -> void:
	d["stats"]["fusions"] += 1
	_progresser_tache("merges", 1)
	taches_maj.emit()

func noter_fouille() -> void:
	d["stats"]["fouilles"] += 1
	_progresser_tache("hidden", 1)
	taches_maj.emit()

# ------------------------------------------------------------------ quotidien : tâches + cadeau
func _jour_actuel() -> String:
	return Time.get_date_string_from_system()

func _init_quotidien() -> void:
	var jour: String = _jour_actuel()
	if d["jour"]["date"] != jour:
		d["jour"] = {"date": jour, "taches": {}, "cadeau_pris": false}
		for t in Data.TASKS:
			d["jour"]["taches"][t["id"]] = {"prog": 0, "pris": false}
		if d["event"]["fin"] == 0:
			d["event"]["fin"] = Time.get_unix_time_from_system() + Data.EVENT_DURATION_DAYS * 86400.0
		maj.emit(); taches_maj.emit()

func tache_progression(id: String) -> int:
	_init_quotidien()
	var taches: Dictionary = d["jour"]["taches"]
	if not taches.has(id): return 0
	return int(taches[id]["prog"])

func tache_prise(id: String) -> bool:
	var taches: Dictionary = d["jour"]["taches"]
	return taches.has(id) and bool(taches[id]["pris"])

func _progresser_tache(type: String, n: int) -> void:
	_init_quotidien()
	for t in Data.TASKS:
		if t["but"]["type"] == type:
			var taches: Dictionary = d["jour"]["taches"]
			taches[t["id"]]["prog"] = int(taches[t["id"]]["prog"]) + n
	# (pas d'émission ici ; les appelants émettent)

func tache_disponible(t: Dictionary) -> bool:
	if tache_prise(t["id"]): return false
	return tache_progression(t["id"]) >= int(t["but"]["pallier"])

func reclam_nombre_tache(t: Dictionary) -> void:
	if not tache_disponible(t): return
	d["jour"]["taches"][t["id"]]["pris"] = true
	ajouter_coins(int(t["coins"]))
	if int(t["feuilles"]) > 0: ajouter_feuilles(int(t["feuilles"]))
	_ajouter_points_event(int(t["points"]))
	maj.emit(); taches_maj.emit()

func cadeau_du_jour_dispo() -> bool:
	_init_quotidien()
	return not d["jour"]["cadeau_pris"]

func prendre_cadeau() -> void:
	if not cadeau_du_jour_dispo(): return
	d["jour"]["cadeau_pris"] = true
	d["energie"] = min(CAP_ENERGIE, int(d["energie"]) + 20)
	ajouter_coins(40)
	ajouter_feuilles(2)
	_ajouter_points_event(100)
	maj.emit()

# ------------------------------------------------------------------ événement (pass + points)
func secondes_event_restantes() -> float:
	var fin: float = float(d["event"].get("fin", 0.0))
	return max(0.0, fin - Time.get_unix_time_from_system())

func _ajouter_points_event(n: int) -> void:
	d["event"]["points"] = int(d["event"]["points"]) + n
	maj.emit()

func points_event() -> int:
	return int(d["event"]["points"])

func palier_atteint(i: int) -> bool:   # i = 1..15
	if i - 1 >= Data.PASS_PALIERS.size(): return true
	return points_event() >= int(Data.PASS_PALIERS[i - 1])

func palier_pris(i: int, voie: String) -> bool:
	var cle := "pris_gratuit" if voie == "gratuit" else "pris_vip"
	return d["event"][cle].has(i)

func reclam_palier(i: int, voie: String) -> bool:
	if not palier_atteint(i) or palier_pris(i, voie): return false
	if voie != "gratuit" and not d["event"]["vip"]: return false
	var cle := "pris_gratuit" if voie == "gratuit" else "pris_vip"
	d["event"][cle].append(i)
	var mult := 1
	if voie != "gratuit": mult = 2
	ajouter_coins(80 * i * mult)
	if i % 3 == 0: ajouter_feuilles(2 * mult)
	if voie == "gratuit":
		_ajouter_points_event(0)
	else:
		_ajouter_points_event(50)
	maj.emit()
	return true

func acheter_vip(luxe: bool) -> void:
	d["event"]["vip"] = true
	d["event"]["vip_lux"] = luxe
	if luxe:
		_ajouter_points_event(200)
	maj.emit()

# ------------------------------------------------------------------ classement (fictif, deterministic)
func bots_classement() -> Array:
	var seedv := int(Time.get_unix_time_from_system() / 86400.0)
	var r := RandomNumberGenerator.new()
	r.seed = seedv * 7919 + 13
	var noms := ["Moji", "Luna", "Yun", "Pia", "Jack", "Mei", "Ravi", "Noé", "Zao", "Elif", "Bao", "Suki"]
	var out: Array = []
	var base := maxi(points_event(), 300)
	for i in 12:
		out.append({"nom": noms[i % noms.size()] + str(1 + (i % 9)), "points": base / 3 + r.randi_range(0, base / 2) + i * 37})
	return out

func rang_joueur(scores: Array) -> int:
	var rang := 1
	for s in scores:
		if int(s["points"]) > points_event(): rang += 1
	return rang

func reclam_recompense_rang() -> bool:
	var cle := "classement_pris"
	if d["event"][cle].has(_jour_actuel()): return false
	var bots := bots_classement()
	var rang := rang_joueur(bots)
	if rang > 3: return false
	d["event"][cle].append(_jour_actuel())
	ajouter_feuilles(4 - rang)
	ajouter_coins(200 * (4 - rang))
	maj.emit()
	return true

# ------------------------------------------------------------------ île : construction
func construction_fin_tts(cle: String) -> float:
	if d["ile"]["chantiers"].has(cle):
		return float(d["ile"]["chantiers"][cle])
	return -1.0

func batiment_construit(cle: String) -> bool:
	return d["ile"]["construits"].has(cle)

func batiment_en_chantier(cle: String) -> bool:
	return d["ile"]["chantiers"].has(cle)

func zone_cle_depuis_batiment(cle: String) -> String:
	for z in Data.ZONES:
		for b in Data.ZONES[z]["batiments"]:
			if b["cle"] == cle: return z
	return ""

func zone_requise(zone: String) -> int:
	return int(Data.ZONES[zone]["prosperite_requise"])

func payer_construction(b: Dictionary) -> bool:
	if batiment_construit(b["cle"]) or batiment_en_chantier(b["cle"]): return false
	var zone := zone_cle_depuis_batiment(b["cle"])
	if zone != "" and prosperite_totale() < zone_requise(zone): return false
	if not depenser_coins(int(b["coins"])): return false
	if int(b["feuilles"]) > 0:
		if not depenser_feuilles(int(b["feuilles"])):
			ajouter_coins(int(b["coins"]))
			return false
	d["ile"]["chantiers"][b["cle"]] = Time.get_unix_time_from_system() + float(b["temps"])
	maj.emit()
	return true

func batiment_pret(cle: String) -> bool:
	return batiment_en_chantier(cle) and Time.get_unix_time_from_system() >= construction_fin_tts(cle)

func collecter_chantier(b: Dictionary) -> bool:
	if not batiment_pret(b["cle"]): return false
	d["ile"]["chantiers"].erase(b["cle"])
	d["ile"]["construits"][b["cle"]] = true
	ajouter_coins(int(b["coins"]) / 2)
	ajouter_xp(10)
	maj.emit()
	return true

# ------------------------------------------------------------------ île : butin par bâtiment
# Chaque bâtiment construit accumule ses propres pièces (prospérité ÷ 6 par minute) et
# affiche une bulle quand il y a quelque chose à ramasser. C'est le principe des boutons
# minutés autour de la carte dans le jeu de référence.
const ILE_CAP_HEURES := 8.0

func _assurer_caisse() -> void:
	if not d["ile"].has("caisse"):
		d["ile"]["caisse"] = {}

func taux_batiment(cle: String) -> float:
	var b := Data.batiment_par_cle(cle)
	if b.is_empty(): return 0.0
	return float(b["prosperite"]) / 6.0

func taux_ile_min() -> float:
	var total := 0.0
	for zone in Data.ZONES:
		for b in Data.ZONES[zone]["batiments"]:
			if batiment_construit(str(b["cle"])):
				total += taux_batiment(str(b["cle"]))
	return total

func butin_batiment(cle: String) -> int:
	if not batiment_construit(cle): return 0
	_assurer_caisse()
	var maintenant := Time.get_unix_time_from_system()
	var dernier := float(d["ile"]["caisse"].get(cle, 0))
	if dernier <= 0.0:
		d["ile"]["caisse"][cle] = maintenant
		return 0
	var ecoule := clampf(maintenant - dernier, 0.0, ILE_CAP_HEURES * 3600.0)
	return int(taux_batiment(cle) * ecoule / 60.0)

func collecter_batiment(cle: String) -> int:
	var n := butin_batiment(cle)
	if n <= 0: return 0
	d["ile"]["caisse"][cle] = Time.get_unix_time_from_system()
	ajouter_coins(n)
	maj.emit()
	return n

func butin_total() -> int:
	var total := 0
	for zone in Data.ZONES:
		for b in Data.ZONES[zone]["batiments"]:
			total += butin_batiment(str(b["cle"]))
	return total

func collecter_tout_ile() -> int:
	var total := 0
	for zone in Data.ZONES:
		for b in Data.ZONES[zone]["batiments"]:
			total += collecter_batiment(str(b["cle"]))
	return total

# ------------------------------------------------------------------ fouilles (objets cachés)
func fouille_finie(id: String) -> bool:
	return d["fouille"]["finis"].has(id)

# Les niveaux de 寻物 se débloquent dans l'ordre, comme dans le jeu de référence.
func fouille_debloquee(i: int) -> bool:
	if i <= 0: return true
	if i >= Data.FOUILLES.size(): return false
	return fouille_finie(Data.FOUILLES[i - 1]["id"])

func fouille_cooldown_restant(id: String) -> float:
	if not d["fouille"]["prochain"].has(id): return 0.0
	var t: float = float(d["fouille"]["prochain"][id]) - Time.get_unix_time_from_system()
	return max(0.0, t)

func terminer_fouille(f: Dictionary) -> void:
	d["fouille"]["finis"][f["id"]] = true
	d["fouille"]["prochain"][f["id"]] = Time.get_unix_time_from_system() + float(f["delai"])
	ajouter_coins(int(f["coins"]))
	ajouter_feuilles(int(f["feuilles"]))
	# La fouille est la source d'énergie « méritée » : on joue, on recharge.
	if int(f.get("energie", 0)) > 0:
		d["energie"] = mini(CAP_ENERGIE, int(d["energie"]) + int(f["energie"]))
	_ajouter_points_event(int(f["points"]))
	noter_fouille()
	maj.emit()

# ------------------------------------------------------------------ roue de la fortune
const ROUE_ATTENTE := 1800.0      # 30 min entre deux rotations

func roue_prete() -> bool:
	return float(d["roue"]["pret"]) <= Time.get_unix_time_from_system()

func roue_attente() -> float:
	return max(0.0, float(d["roue"]["pret"]) - Time.get_unix_time_from_system())

func tirer_secteur_roue() -> int:
	var total := 0
	for s in Data.ROUE:
		total += int(s["poids"])
	var r := RandomNumberGenerator.new()
	r.randomize()
	var tirage := r.randi_range(1, total)
	var cumul := 0
	for i in range(Data.ROUE.size()):
		cumul += int(Data.ROUE[i]["poids"])
		if tirage <= cumul: return i
	return 0

# ------------------------------------------------------------------ 天赐好礼 (gros cadeau minuté)
const DON_ATTENTE := 10800.0      # 3 heures

func don_prete() -> bool:
	return float(d["don"]["pret"]) <= Time.get_unix_time_from_system()

func don_attente() -> float:
	return max(0.0, float(d["don"]["pret"]) - Time.get_unix_time_from_system())

func reclamer_don() -> bool:
	if not don_prete(): return false
	d["don"]["pret"] = Time.get_unix_time_from_system() + DON_ATTENTE
	d["energie"] = mini(CAP_ENERGIE, int(d["energie"]) + 50)
	ajouter_coins(200)
	maj.emit()
	return true

func tourner_roue(index: int) -> Dictionary:
	var prix: Dictionary = Data.ROUE[index]
	d["roue"]["pret"] = Time.get_unix_time_from_system() + ROUE_ATTENTE
	d["roue"]["total"] = int(d["roue"].get("total", 0)) + 1
	if int(prix.get("energie", 0)) > 0:
		d["energie"] = mini(CAP_ENERGIE, int(d["energie"]) + int(prix["energie"]))
	if int(prix.get("coins", 0)) > 0:
		ajouter_coins(int(prix["coins"]))
	if int(prix.get("feuilles", 0)) > 0:
		ajouter_feuilles(int(prix["feuilles"]))
	maj.emit()
	return prix

# ------------------------------------------------------------------ langue
func langue_actuelle() -> String:
	return d.get("langue", "fr")
