extends Node2D
class_name Drone

# --- Konfiguration ---
enum Type { SCOUT, HAULER }
enum State { IDLE, MOVING, HARVESTING, RETURNING }

# Eigenschaften
var my_type: Type = Type.SCOUT
var current_state: State = State.IDLE
var hex_coords: Vector2i
var home_coords: Vector2i = Vector2i(0, 0) # Wo ist die Basis?

# Bewegung
var target_position: Vector2
var speed: float = 100.0

# Gameplay Werte
var battery: float = 100.0
var max_battery: float = 100.0
var cargo_amount: int = 0
var max_cargo: int = 20
var cargo_type: int = -1 # Welcher Ressourcentyp? (GameManager.TERRAIN...)

# Referenzen
var world_ref: Node2D # Um Positionen zu berechnen (TileMap)
@onready var sprite = $Sprite2D
@onready var label = $Label

# Ein Timer für Aktionen (z.B. Abbauen)
var action_timer: float = 0.0

func setup(start_coords: Vector2i, type: Type, world_layer: Node2D):
	hex_coords = start_coords
	my_type = type
	world_ref = world_layer
	
	# Startposition setzen
	position = world_ref.map_to_local(hex_coords)
	target_position = position
	
	# Werte je nach Typ
	if my_type == Type.SCOUT:
		sprite.modulate = Color("38bdf8")
		label.text = "S"
		speed = 120.0
		max_cargo = 20
	else:
		sprite.modulate = Color("fb923c")
		label.text = "H"
		speed = 80.0
		max_cargo = 50

func _process(delta):
	match current_state:
		State.IDLE:
			# Tu nichts, warte auf Befehle
			pass
			
		State.MOVING, State.RETURNING:
			process_movement(delta)
			
		State.HARVESTING:
			process_harvesting(delta)

func process_movement(delta):
	# Bewegung
	position = position.move_toward(target_position, speed * delta)
	
	# Batterie verbrauchen
	battery -= 2.0 * delta
	
	# Angekommen?
	if position.distance_to(target_position) < 1.0:
		handle_arrival()

func process_harvesting(delta):
	action_timer -= delta
	if action_timer <= 0:
		# Abbau fertig!
		cargo_amount = max_cargo
		print("Abbau beendet. Fracht voll! Kehre zurück.")
		return_to_base()

func handle_arrival():
	# Grid-Position aktualisieren
	hex_coords = world_ref.local_to_map(position)
	
	if current_state == State.MOVING:
		# Wir sind am Ziel (Ressource) angekommen -> Abbauen starten
		start_harvesting()
		
	elif current_state == State.RETURNING:
		# Wir sind an der Basis angekommen -> Abladen
		deposit_cargo()

# --- Befehle & Aktionen ---

func command_move_to(target_hex: Vector2i):
	# Nur bewegen, wenn wir nicht gerade arbeiten (oder Abbruchlogik einbauen)
	hex_coords = target_hex # Ziel merken
	target_position = world_ref.map_to_local(target_hex)
	current_state = State.MOVING
	print("Drohne fliegt zu: ", target_hex)

func start_harvesting():
	print("Starte Abbau...")
	current_state = State.HARVESTING
	action_timer = 2.0 # Dauert 2 Sekunden

func return_to_base():
	current_state = State.RETURNING
	target_position = world_ref.map_to_local(home_coords)

func deposit_cargo():
	if cargo_amount > 0:
		# Hier würden wir dem GameManager sagen: "Füge Ressource hinzu"
		# Da wir noch nicht wissen, WELCHE Ressource, faken wir erst mal Metall
		GameManager.modify_resource("metal", cargo_amount)
		print("Abgeladen: ", cargo_amount, " Metall.")
		cargo_amount = 0
	
	current_state = State.IDLE
	print("Drohne wartet.")
