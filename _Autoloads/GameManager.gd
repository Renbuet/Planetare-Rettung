extends Node

# Signale: "Radio-Durchsagen", wenn sich Werte ändern
signal resources_updated(res_dict)
signal mode_changed(new_mode)
signal log_message(text)

# Spiel-Modi (Enum statt Strings, um Tippfehler zu vermeiden)
enum Mode { SELECT, BUILD_RELAY, BUILD_SCOUT, BUILD_HAULER }
var current_mode = Mode.SELECT

# Ressourcen (wie dein 'state.res')
var resources = {
	"energy": 100.0,
	"max_energy": 200.0,
	"biomass": 20.0,
	"metal": 50.0,
	"tech": 10.0
}

# Terrain-Definitionen (wie dein 'T'-Objekt)
# Wir nutzen hier die "Atlas-Koordinaten" oder IDs, die wir gleich im TileSet anlegen.
# Da wir Alternative Tiles nutzen werden, speichern wir hier die "Alternative ID".
const TERRAIN = {
	"EMPTY": 0,  # Basis-Tile
	"ROCK": 1,   # Alternative 1
	"BIO": 2,    # Alternative 2 usw...
	"METAL": 3,
	"TECH": 4,
	"BASE": 5,
	"RELAY": 6
}

func _ready():
	# Einmaliger Aufruf zum Start, damit die UI Bescheid weiß
	emit_signal("resources_updated", resources)

# Hilfsfunktion zum Ändern von Ressourcen
func modify_resource(type: String, amount: float):
	if type in resources:
		resources[type] += amount
		
		# Limits beachten (z.B. Max Energie oder nicht unter 0)
		if type == "energy":
			resources[type] = clamp(resources[type], 0, resources["max_energy"])
		else:
			resources[type] = max(0, resources[type]) # Nicht negativ werden
			
		emit_signal("resources_updated", resources)

# Hilfsfunktion für den Modus
func set_mode(new_mode):
	current_mode = new_mode
	emit_signal("mode_changed", current_mode)

# Hilfsfunktion für das Log
func log(text: String):
	print(text) # Auch in die Konsole drucken
	emit_signal("log_message", text)
