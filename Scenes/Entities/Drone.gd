#extends Node2D
#class_name Drone
#
## --- Konfiguration ---
#enum Type { SCOUT, HAULER }
#enum State { IDLE, MOVING, HARVESTING, RETURNING }
#
## Eigenschaften
#var my_type: Type = Type.SCOUT
#var current_state: State = State.IDLE
#var hex_coords: Vector2i
#var home_coords: Vector2i = Vector2i(0, 0)
#var current_job_hex: Vector2i
#
## Bewegung
#var target_position: Vector2
#var speed: float = 100.0
#
## Gameplay Werte
#var battery: float = 100.0
#var max_battery: float = 100.0
#var cargo_amount: int = 0
#var max_cargo: int = 20
#var cargo_resource_name: String = "" # NEU: Welchen Typ tragen wir?
#
## Referenzen
#var world_layer_ref: Node2D # Für Koordinaten (TileMapLayer)
#var game_world: Node2D # Für Logik (World.gd) - NEU
#@onready var sprite = $Sprite2D
#@onready var label = $Label
#
## Ein Timer für Aktionen (z.B. Abbauen)
#var action_timer: float = 0.0
#
#func setup(start_coords: Vector2i, type: Type, world_layer: Node2D):
	#hex_coords = start_coords
	#my_type = type
	#world_layer_ref = world_layer
	#
	## WICHTIG: Wir holen uns das World-Skript (den Parent vom TileMapLayer)
	#game_world = world_layer.get_parent()
	#
	#position = world_layer_ref.map_to_local(hex_coords)
	#target_position = position
	#
	#if my_type == Type.SCOUT:
		#sprite.modulate = Color("38bdf8")
		#label.text = "S"
		#speed = 120.0
		#max_cargo = 20
	#else:
		#sprite.modulate = Color("fb923c")
		#label.text = "H"
		#speed = 80.0
		#max_cargo = 50
	#
	## Werte je nach Typ
	#if my_type == Type.SCOUT:
		#sprite.modulate = Color("38bdf8")
		#label.text = "S"
		#speed = 120.0
		#max_cargo = 20
	#else:
		#sprite.modulate = Color("fb923c")
		#label.text = "H"
		#speed = 80.0
		#max_cargo = 50
#
#func _process(delta):
	#match current_state:
		#State.IDLE:
			#pass
		#State.MOVING, State.RETURNING:
			#process_movement(delta)
		#State.HARVESTING:
			#process_harvesting(delta)
#
#func process_movement(delta):
	#position = position.move_toward(target_position, speed * delta)
	#battery -= 2.0 * delta
	#if position.distance_to(target_position) < 1.0:
		#handle_arrival()
	#
	## Angekommen?
	#if position.distance_to(target_position) < 1.0:
		#handle_arrival()
#
#func process_harvesting(delta):
	#action_timer -= delta
	#if action_timer <= 0:
		#var space_left = max_cargo - cargo_amount
		#
		## KORREKTUR: Wir rufen harvest_tile auf 'game_world' auf, nicht auf dem Layer
		#if game_world and game_world.has_method("harvest_tile"):
			#var harvested = game_world.harvest_tile(hex_coords, space_left)
			#
			#if harvested > 0:
				#cargo_amount += harvested
				#identify_resource_type() # Typ erkennen
			#
		#print("Abbau beendet. Fracht: ", cargo_amount, " ", cargo_resource_name)
		#return_to_base()
#
## NEU: Hilfsfunktion, um anhand der Kachel-ID den Namen zu bestimmen
#func identify_resource_type():
	## Wir schauen uns das Tile auf der Karte an
	#var tile_id = world_layer_ref.get_cell_alternative_tile(hex_coords)
	#
	## Mapping basierend auf GameManager.TERRAIN
	#match tile_id:
		#2: cargo_resource_name = "biomass" # ID 2 = BIO
		#3: cargo_resource_name = "metal"   # ID 3 = METAL
		#4: cargo_resource_name = "tech"    # ID 4 = TECH
		#_: cargo_resource_name = "metal"   # Fallback
#
#func handle_arrival():
	#hex_coords = world_layer_ref.local_to_map(position)
	#if current_state == State.MOVING:
		#start_harvesting()
	#elif current_state == State.RETURNING:
		#deposit_cargo()
#
## --- Befehle & Aktionen ---
#
## ANPASSUNG: command_move_to merkt sich den Job
#func command_move_to(target_hex: Vector2i):
	#current_job_hex = target_hex
	#hex_coords = target_hex
	#target_position = world_layer_ref.map_to_local(target_hex)
	#current_state = State.MOVING
	#print("Drohne startet Job bei: ", target_hex)
#
#
#func start_harvesting():
	#print("Starte Abbau...")
	#current_state = State.HARVESTING
	#action_timer = 2.0
#
#func return_to_base():
	#current_state = State.RETURNING
	#target_position = world_layer_ref.map_to_local(home_coords)
#
#func deposit_cargo():
	#if cargo_amount > 0:
		## KORREKTUR: Wir nutzen jetzt den echten Typen
		#if cargo_resource_name != "":
			#GameManager.modify_resource(cargo_resource_name, cargo_amount)
			#print("Abgeladen: ", cargo_amount, " ", cargo_resource_name)
		#else:
			#print("Fehler: Unbekannte Fracht!")
			#
		#cargo_amount = 0
		#cargo_resource_name = ""
	#
	## KORREKTUR: Loop-Check über 'game_world'
	#if game_world and game_world.has_method("has_resource") and game_world.has_resource(current_job_hex):
		#print("Kehre zum Abbaugebiet zurück: ", current_job_hex)
		#hex_coords = current_job_hex
		#target_position = world_layer_ref.map_to_local(current_job_hex)
		#current_state = State.MOVING
	#else:
		#current_state = State.IDLE
		#print("Auftrag erledigt. Ressource erschöpft. Warte auf Befehle.")

#-------------------------------------
#extends Node2D
#class_name Drone
#
## ... (Enums und Variablen oben bleiben gleich) ...
#enum Type { SCOUT, HAULER }
#enum State { IDLE, MOVING, HARVESTING, RETURNING }
#
#var my_type: Type = Type.SCOUT
#var current_state: State = State.IDLE
#var hex_coords: Vector2i
#var home_coords: Vector2i = Vector2i(0, 0)
#var current_job_hex: Vector2i
#
## Bewegung
#var target_position: Vector2
#var speed: float = 100.0
#
## Gameplay Werte
#var battery: float = 100.0
#var max_battery: float = 100.0
#var cargo_amount: int = 0
#var max_cargo: int = 20
#var cargo_resource_name: String = "" # NEU: Welchen Typ tragen wir?
#
## Referenzen
#var world_layer_ref: Node2D # Für Koordinaten (TileMapLayer)
#var game_world: Node2D # Für Logik (World.gd) - NEU
#@onready var sprite = $Sprite2D
#@onready var label = $Label
#
#var action_timer: float = 0.0
#
#func setup(start_coords: Vector2i, type: Type, world_layer: Node2D):
	#hex_coords = start_coords
	#my_type = type
	#world_layer_ref = world_layer
	#
	## WICHTIG: Wir holen uns das World-Skript (den Parent vom TileMapLayer)
	#game_world = world_layer.get_parent()
	#
	#position = world_layer_ref.map_to_local(hex_coords)
	#target_position = position
	#
	#if my_type == Type.SCOUT:
		#sprite.modulate = Color("38bdf8")
		#label.text = "S"
		#speed = 120.0
		#max_cargo = 20
	#else:
		#sprite.modulate = Color("fb923c")
		#label.text = "H"
		#speed = 80.0
		#max_cargo = 50
#
#func _process(delta):
	#match current_state:
		#State.IDLE:
			#pass
		#State.MOVING, State.RETURNING:
			#process_movement(delta)
		#State.HARVESTING:
			#process_harvesting(delta)
#
#func process_movement(delta):
	#position = position.move_toward(target_position, speed * delta)
	#battery -= 2.0 * delta
	#if position.distance_to(target_position) < 1.0:
		#handle_arrival()
#
#func process_harvesting(delta):
	#action_timer -= delta
	#if action_timer <= 0:
		#var space_left = max_cargo - cargo_amount
		#
		## FIX: Typ bestimmen BEVOR wir abbauen.
		## Wenn das Feld durch den Abbau leer wird (EMPTY), würden wir sonst 
		## fälschlicherweise "metal" (Fallback) erkennen.
		#if cargo_amount == 0:
			#identify_resource_type()
		#
		#if game_world and game_world.has_method("harvest_tile"):
			#var harvested = game_world.harvest_tile(hex_coords, space_left)
			#
			#if harvested > 0:
				#cargo_amount += harvested
				## identify_resource_type() <-- HIER WAR DER FEHLER (zu spät!)
			#
		#print("Abbau beendet. Fracht: ", cargo_amount, " ", cargo_resource_name)
		#return_to_base()
#
## NEU: Hilfsfunktion, um anhand der Kachel-ID den Namen zu bestimmen
#func identify_resource_type():
	## Wir schauen uns das Tile auf der Karte an
	#var tile_id = world_layer_ref.get_cell_alternative_tile(hex_coords)
	#
	## Mapping basierend auf GameManager.TERRAIN
	#match tile_id:
		#2: cargo_resource_name = "biomass" # ID 2 = BIO
		#3: cargo_resource_name = "metal"   # ID 3 = METAL
		#4: cargo_resource_name = "tech"    # ID 4 = TECH
		#_: cargo_resource_name = "metal"   # Fallback
#
#func handle_arrival():
	#hex_coords = world_layer_ref.local_to_map(position)
	#if current_state == State.MOVING:
		#start_harvesting()
	#elif current_state == State.RETURNING:
		#deposit_cargo()
#
#func command_move_to(target_hex: Vector2i):
	#current_job_hex = target_hex
	#hex_coords = target_hex
	#target_position = world_layer_ref.map_to_local(target_hex)
	#current_state = State.MOVING
	#print("Drohne startet Job bei: ", target_hex)
#
#func start_harvesting():
	#print("Starte Abbau...")
	#current_state = State.HARVESTING
	#action_timer = 2.0
#
#func return_to_base():
	#current_state = State.RETURNING
	#target_position = world_layer_ref.map_to_local(home_coords)
#
#func deposit_cargo():
	#if cargo_amount > 0:
		## KORREKTUR: Wir nutzen jetzt den echten Typen
		#if cargo_resource_name != "":
			#GameManager.modify_resource(cargo_resource_name, cargo_amount)
			#print("Abgeladen: ", cargo_amount, " ", cargo_resource_name)
		#else:
			#print("Fehler: Unbekannte Fracht!")
			#
		#cargo_amount = 0
		#cargo_resource_name = ""
	#
	## KORREKTUR: Loop-Check über 'game_world'
	#if game_world and game_world.has_method("has_resource") and game_world.has_resource(current_job_hex):
		#print("Kehre zum Abbaugebiet zurück: ", current_job_hex)
		#hex_coords = current_job_hex
		#target_position = world_layer_ref.map_to_local(current_job_hex)
		#current_state = State.MOVING
	#else:
		#current_state = State.IDLE
		#print("Auftrag erledigt. Ressource erschöpft. Warte auf Befehle.")
		
#-----------------------------------
extends Node2D
class_name Drone

# ... (Enums und Variablen oben bleiben gleich) ...
enum Type { SCOUT, HAULER }
enum State { IDLE, MOVING, HARVESTING, RETURNING }

var my_type: Type = Type.SCOUT
var current_state: State = State.IDLE
var hex_coords: Vector2i
var home_coords: Vector2i = Vector2i(0, 0)
var current_job_hex: Vector2i

# Bewegung
var target_position: Vector2
var speed: float = 100.0

# Gameplay Werte
var battery: float = 100.0
var max_battery: float = 100.0
var cargo_amount: int = 0
var max_cargo: int = 20
var cargo_resource_name: String = "" 

# Referenzen
var world_layer_ref: Node2D 
var game_world: Node2D 
@onready var sprite = $Sprite2D
@onready var label = $Label

var action_timer: float = 0.0

func setup(start_coords: Vector2i, type: Type, world_layer: Node2D):
	hex_coords = start_coords
	my_type = type
	world_layer_ref = world_layer
	game_world = world_layer.get_parent()
	
	position = world_layer_ref.map_to_local(hex_coords)
	target_position = position
	
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
			pass
		State.MOVING, State.RETURNING:
			process_movement(delta)
		State.HARVESTING:
			process_harvesting(delta)

func process_movement(delta):
	position = position.move_toward(target_position, speed * delta)
	battery -= 2.0 * delta
	if position.distance_to(target_position) < 1.0:
		handle_arrival()

func process_harvesting(delta):
	action_timer -= delta
	if action_timer <= 0:
		var space_left = max_cargo - cargo_amount
		
		# Typ bestimmen BEVOR wir abbauen
		if cargo_amount == 0:
			identify_resource_type()
		
		if game_world and game_world.has_method("harvest_tile"):
			var harvested = game_world.harvest_tile(hex_coords, space_left)
			
			if harvested > 0:
				cargo_amount += harvested
		
		# --- OPTIMIERUNG ---
		if cargo_amount > 0:
			# Wir haben Beute -> Ab nach Hause!
			print("Abbau beendet. Fracht: ", cargo_amount, " ", cargo_resource_name)
			return_to_base()
		else:
			# Wir sind leer (Feld war schon erschöpft) -> Bleib hier
			print("Nichts gefunden (Ressource leer). Warte auf neue Befehle.")
			current_state = State.IDLE
			# Hier könnte man später direkt 'check_for_nearby_jobs()' aufrufen

func identify_resource_type():
	var tile_id = world_layer_ref.get_cell_alternative_tile(hex_coords)
	match tile_id:
		2: cargo_resource_name = "biomass"
		3: cargo_resource_name = "metal" 
		4: cargo_resource_name = "tech"
		_: cargo_resource_name = "metal" 

func handle_arrival():
	hex_coords = world_layer_ref.local_to_map(position)
	if current_state == State.MOVING:
		start_harvesting()
	elif current_state == State.RETURNING:
		deposit_cargo()

func command_move_to(target_hex: Vector2i):
	current_job_hex = target_hex
	hex_coords = target_hex
	target_position = world_layer_ref.map_to_local(target_hex)
	current_state = State.MOVING
	print("Drohne startet Job bei: ", target_hex)

func start_harvesting():
	# print("Starte Abbau...") # Optional: Weniger Spam im Log
	current_state = State.HARVESTING
	action_timer = 2.0

func return_to_base():
	current_state = State.RETURNING
	target_position = world_layer_ref.map_to_local(home_coords)

func deposit_cargo():
	if cargo_amount > 0:
		if cargo_resource_name != "":
			GameManager.modify_resource(cargo_resource_name, cargo_amount)
			print("Abgeladen: ", cargo_amount, " ", cargo_resource_name)
		else:
			print("Fehler: Unbekannte Fracht!")
			
		cargo_amount = 0
		cargo_resource_name = ""
	
	# Loop-Check
	if game_world and game_world.has_method("has_resource") and game_world.has_resource(current_job_hex):
		# print("Kehre zum Abbaugebiet zurück...") # Weniger Spam
		hex_coords = current_job_hex
		target_position = world_layer_ref.map_to_local(current_job_hex)
		current_state = State.MOVING
	else:
		current_state = State.IDLE
		print("Auftrag erledigt. Ressource erschöpft.")
