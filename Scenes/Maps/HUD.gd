#extends CanvasLayer
#
## Referenzen zu den Labels (Pass die Pfade an, falls nötig!)
#@onready var lbl_energy = $TopBar/HBoxContainer/LblEnergy
#@onready var lbl_bio = $TopBar/HBoxContainer/LblBio
#@onready var lbl_metal = $TopBar/HBoxContainer/LblMetal
#@onready var lbl_tech = $TopBar/HBoxContainer/LblTech
#
#func _ready():
	## Wir verbinden uns mit dem Signal vom GameManager
	## Wann immer sich Ressourcen ändern, ruft er unsere Funktion '_on_resources_updated' auf.
	#GameManager.resources_updated.connect(_on_resources_updated)
	#
	## Initiales Update erzwingen, damit nicht "Label" da steht
	#_on_resources_updated(GameManager.resources)
#
#func _on_resources_updated(res: Dictionary):
	## Text aktualisieren. Wir runden die Werte (floor), damit keine Kommazahlen stören.
	#lbl_energy.text = "Energie: " + str(floor(res["energy"]))
	#lbl_bio.text = "Bio: " + str(floor(res["biomass"]))
	#lbl_metal.text = "Metall: " + str(floor(res["metal"]))
	#lbl_tech.text = "Tech: " + str(floor(res["tech"]))
extends CanvasLayer

# Referenzen Oben
@onready var lbl_energy = $TopBar/HBoxContainer/LblEnergy
@onready var lbl_bio = $TopBar/HBoxContainer/LblBio
@onready var lbl_metal = $TopBar/HBoxContainer/LblMetal
@onready var lbl_tech = $TopBar/HBoxContainer/LblTech

# Referenzen Rechts (Pfade anpassen falls nötig!)
@onready var btn_scout = $RightPanel/MarginContainer/VBoxContainer/BtnBuildScout

# Kosten (Konstanten)
const COST_SCOUT = { "metal": 20, "tech": 2 }

func _ready():
	GameManager.resources_updated.connect(_on_resources_updated)
	
	# Button Signal verbinden
	btn_scout.pressed.connect(_on_btn_scout_pressed)
	
	_on_resources_updated(GameManager.resources)

func _on_resources_updated(res: Dictionary):
	# Labels
	lbl_energy.text = "Energie: " + str(floor(res["energy"]))
	lbl_bio.text = "Bio: " + str(floor(res["biomass"]))
	lbl_metal.text = "Metall: " + str(floor(res["metal"]))
	lbl_tech.text = "Tech: " + str(floor(res["tech"]))
	
	# Button aktivieren/deaktivieren je nach Ressourcen
	if res["metal"] >= COST_SCOUT.metal and res["tech"] >= COST_SCOUT.tech:
		btn_scout.disabled = false
	else:
		btn_scout.disabled = true

func _on_btn_scout_pressed():
	# Ressourcen abziehen
	GameManager.modify_resource("metal", -COST_SCOUT.metal)
	GameManager.modify_resource("tech", -COST_SCOUT.tech)
	GameManager.spawn_requested.emit(Drone.Type.SCOUT)
	
	print("Signal 'spawn_requested' gesendet.")
