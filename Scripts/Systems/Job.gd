class_name Job
extends RefCounted

# Job Typen
enum Type { 
	HARVEST,      # Abbau an einer Ressource
	TRANSPORT,    # Von Lager A nach Lager B
	BUILD,        # Konstruktion eines Gebäudes
	CHARGE        # Drohne muss laden (Self-Job)
}

var id: int
var job_type: Type
var priority: int = 1 # Höhere Zahl = Wichtiger

# Ziel-Daten
var target_hex: Vector2i       # Wo findet der Job statt?
var target_object_id: int = -1 # ID des Gebäudes/Ressource (falls nötig)

# Details
var required_drone_type: int   # Welcher Drohnentyp wird benötigt? (GameManager.DroneType)
var resource_type: String = "" # Z.B. "metal"
var amount_target: int = 0     # Wie viel soll abgebaut/transportiert werden?

# Status
var assigned_drone_id: int = -1

func _init(_id: int, _type: Type, _hex: Vector2i, _drone_type: int):
	id = _id
	job_type = _type
	target_hex = _hex
	required_drone_type = _drone_type
