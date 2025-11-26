extends Node

# Signale
signal resources_updated(res_dict)
signal mode_changed(new_mode)
signal log_message(text)
signal spawn_requested(drone_type)

# Spiel-Modi
enum Mode { SELECT, BUILD_RELAY, BUILD_SCOUT, BUILD_HAULER }
var current_mode = Mode.SELECT

# --- ZEIT SYSTEM ---
# 1.0 = Normale Geschwindigkeit, 2.0 = Doppelte Geschwindigkeit (Paid Mode)
var game_speed_modifier: float = 1.0 

# Ressourcen
var resources = {
	"energy": 100.0,
	"max_energy": 200.0,
	"biomass": 20.0,
	"metal": 50.0,
	"tech": 10.0
}

# Terrain Definitionen
const TERRAIN = {
	"EMPTY": 0, "ROCK": 1, "BIO": 2, "METAL": 3, "TECH": 4, "BASE": 5, "RELAY": 6
}

# Drohnen Typen (Global verfügbar machen)
enum DroneType { HARVESTER, TRANSPORTER, BUILDER }

func _ready():
	emit_signal("resources_updated", resources)

# Hilfsfunktion, um überall im Spiel die korrekte Delta-Zeit zu bekommen
func get_scaled_delta(delta: float) -> float:
	return delta * game_speed_modifier

func set_paid_mode(active: bool):
	game_speed_modifier = 2.0 if active else 1.0
	#log("Geschwindigkeit auf " + str(game_speed_modifier) + "x gesetzt.")
	print("Geschwindigkeit auf " + str(game_speed_modifier) + "x gesetzt.")

func modify_resource(type: String, amount: float):
	if type in resources:
		resources[type] += amount
		if type == "energy":
			resources[type] = clamp(resources[type], 0, resources["max_energy"])
		else:
			resources[type] = max(0, resources[type])
		emit_signal("resources_updated", resources)

func set_mode(new_mode):
	current_mode = new_mode
	emit_signal("mode_changed", current_mode)

func log(text: String):
	print(text)
	emit_signal("log_message", text)
