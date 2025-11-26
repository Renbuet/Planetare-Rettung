extends Node2D
class_name Drone

enum State { IDLE, MOVING_TO_JOB, HARVESTING, RETURNING, LOOKING_FOR_WORK }

# Eigenschaften
var my_type: int = GameManager.DroneType.HARVESTER
var current_state = State.IDLE
var hex_coords: Vector2i
var drone_id: int 

# Bewegung
var target_position: Vector2
var speed: float = 100.0

# Gameplay
var cargo_amount: int = 0
var max_cargo: int = 20
var cargo_resource_name: String = ""

# Referenzen
var world_layer_ref: Node2D
var game_world: Node2D 
var job_manager_ref: JobManager = null
var current_job: Job = null
var action_timer: float = 0.0

func setup(_id: int, _type: int, _world, _job_manager, _tile_map):
	drone_id = _id
	my_type = _type
	game_world = _world
	job_manager_ref = _job_manager
	world_layer_ref = _tile_map
	
	update_appearance()

func update_appearance():
	if my_type == GameManager.DroneType.HARVESTER:
		$Label.text = "H"
		$Sprite2D.modulate = Color("38bdf8")
		speed = 100.0
	elif my_type == GameManager.DroneType.TRANSPORTER:
		$Label.text = "T"
		$Sprite2D.modulate = Color("fb923c")
		speed = 80.0
		max_cargo = 50

func _process(delta):
	var dt = GameManager.get_scaled_delta(delta)
	
	match current_state:
		State.IDLE:
			current_state = State.LOOKING_FOR_WORK
		State.LOOKING_FOR_WORK:
			check_for_jobs()
		State.MOVING_TO_JOB:
			process_movement(dt)
		State.HARVESTING:
			process_harvesting(dt)
		State.RETURNING:
			process_movement(dt)

func check_for_jobs():
	if job_manager_ref:
		# Wir übergeben unsere aktuelle Position (hex_coords)
		var job = job_manager_ref.request_job(drone_id, my_type, hex_coords)
		if job:
			accept_job(job)
		else:
			# Kein Job da? Kurz warten (nichts tun im Frame)
			pass

func accept_job(job):
	current_job = job
	# Zielposition berechnen
	command_move_to(job.target_hex)
	current_state = State.MOVING_TO_JOB

func process_movement(dt):
	position = position.move_toward(target_position, speed * dt)
	
	# Hex-Koordinaten während des Fluges aktualisieren (für Distanz-Checks)
	hex_coords = world_layer_ref.local_to_map(position)

	if position.distance_to(target_position) < 1.0:
		handle_arrival()

func handle_arrival():
	match current_state:
		State.MOVING_TO_JOB:
			if current_job:
				start_harvesting()
			else:
				current_state = State.IDLE
		State.RETURNING:
			deposit_cargo()

func start_harvesting():
	current_state = State.HARVESTING
	action_timer = 2.0 

func process_harvesting(dt):
	action_timer -= dt
	if action_timer <= 0:
		finish_harvesting()

func finish_harvesting():
	var space_left = max_cargo - cargo_amount
	var harvested = 0
	
	if game_world and game_world.has_method("harvest_tile"):
		harvested = game_world.harvest_tile(hex_coords, space_left)
	
	if harvested > 0:
		cargo_amount += harvested
		if current_job:
			cargo_resource_name = current_job.resource_type
		return_to_base()
	else:
		# Nichts bekommen (Feld leer?) -> Job fertig, Ressourcen erschöpft
		complete_current_job(false) # false = Job nicht neu erstellen
		current_state = State.IDLE

func return_to_base():
	current_state = State.RETURNING
	var dropoff_hex = Vector2i(0,0)
	if game_world and game_world.has_method("get_nearest_dropoff"):
		dropoff_hex = game_world.get_nearest_dropoff(hex_coords)
	
	target_position = world_layer_ref.map_to_local(dropoff_hex)

func deposit_cargo():
	if cargo_amount > 0:
		GameManager.modify_resource(cargo_resource_name, cargo_amount)
		# print("Drohne ", drone_id, " liefert ", cargo_amount, " ", cargo_resource_name)
		cargo_amount = 0
		cargo_resource_name = ""
	
	# Loop: Versuche den Job direkt zu behalten (Chaining)
	complete_current_job(true)
	
	# Wenn wir den Job behalten haben (accept_job wurde in complete_current_job aufgerufen),
	# ist der Status jetzt MOVING_TO_JOB. Falls nicht, setzen wir auf IDLE.
	if current_state == State.RETURNING:
		current_state = State.IDLE

func complete_current_job(should_recreate: bool):
	if current_job and job_manager_ref:
		var old_target = current_job.target_hex
		var old_res = current_job.resource_type
		
		# 1. Aktuellen Job als erledigt markieren
		job_manager_ref.complete_job(drone_id)
		current_job = null # Referenz löschen
		
		# 2. Prüfen, ob wir ihn neu anlegen (und direkt behalten!) sollen
		if should_recreate:
			if game_world.has_resource(old_target):
				# Wir versuchen den Job direkt zu "ketten"
				var next_job = job_manager_ref.create_and_assign_harvest_job(old_target, old_res, drone_id)
				
				if next_job:
					# Wir haben ihn bekommen! Direkt annehmen.
					accept_job(next_job)
				else:
					# Fallback: Regulär erstellen
					job_manager_ref.create_harvest_job(old_target, old_res)
			else:
				pass

# --- DIESE FUNKTION FEHLTE ---
func command_move_to(target_hex: Vector2i):
	target_position = world_layer_ref.map_to_local(target_hex)
