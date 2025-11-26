extends Node
class_name JobManager

# HINWEIS: Wir nutzen hier die globale Klasse "Job", die in Job.gd definiert ist.
# Keine innere "class Job" Definition mehr hier!

# Warteschlangen
# Key: DroneType (int), Value: Array[Job]
var pending_jobs = {} 
var active_jobs = {}  # Key: drone_id, Value: Job

var _job_id_counter = 0

func _ready():
	for type in GameManager.DroneType.values():
		pending_jobs[type] = []

# --- JOB ERSTELLUNG ---

func create_harvest_job(hex: Vector2i, resource_name: String):
	# Prüfen, ob für dieses Hex schon ein Job existiert, um Doppelungen zu vermeiden
	if _is_job_existing_for_hex(hex):
		return
		
	# Wir nutzen die globale Job Klasse
	var new_job = Job.new(
		_get_next_id(),
		Job.Type.HARVEST,
		hex,
		GameManager.DroneType.HARVESTER
	)
	new_job.resource_type = resource_name
	
	_add_job_to_queue(new_job)

# NEU: Erstellt einen Job und weist ihn direkt einer Drohne zu (Chain-Reaction)
# Umgeht die Warteschlange, damit Drohnen an ihrer Ressource bleiben.
func create_and_assign_harvest_job(hex: Vector2i, resource_name: String, drone_id: int) -> Job:
	if _is_job_existing_for_hex(hex):
		return null
		
	var new_job = Job.new(
		_get_next_id(),
		Job.Type.HARVEST,
		hex,
		GameManager.DroneType.HARVESTER
	)
	new_job.resource_type = resource_name
	
	# Direkt zuweisen (am Pending vorbei)
	new_job.assigned_drone_id = drone_id
	active_jobs[drone_id] = new_job
	
	# print("Job direkt zugewiesen (Chain): ", hex)
	return new_job

# --- JOB VERWALTUNG ---

func _add_job_to_queue(job: Job):
	pending_jobs[job.required_drone_type].append(job)
	# print("Job erstellt: ", Job.Type.keys()[job.job_type], " @ ", job.target_hex)

# Wird von einer Drohne aufgerufen, die Arbeit sucht
# Nimmt 3 Argumente: ID, Typ und Position der Drohne
func request_job(drone_id: int, drone_type: int, drone_pos_hex: Vector2i) -> Job:
	var list = pending_jobs[drone_type]
	if list.is_empty():
		return null
	
	# --- DISTANZ LOGIK ---
	var best_job = null
	var min_dist = 999999
	var best_index = -1
	
	# Wir suchen den Job, der am nächsten an der Drohne ist
	for i in range(list.size()):
		var job = list[i]
		# Einfache Distanzberechnung (Quadrat reicht für Vergleich)
		var dist = Vector2(drone_pos_hex).distance_squared_to(Vector2(job.target_hex))
		
		if dist < min_dist:
			min_dist = dist
			best_job = job
			best_index = i
	
	if best_job:
		# Job aus der Warteschlange entfernen
		list.remove_at(best_index)
		
		# Der Drohne zuweisen
		best_job.assigned_drone_id = drone_id
		active_jobs[drone_id] = best_job
		return best_job
		
	return null

# Wenn eine Drohne fertig ist oder zerstört wird
func complete_job(drone_id: int):
	if active_jobs.has(drone_id):
		# var job = active_jobs[drone_id]
		# print("Job ", job.id, " erledigt von Drohne ", drone_id)
		active_jobs.erase(drone_id)

# Wenn eine Drohne den Job abbricht (z.B. Batterie leer), muss er zurück in den Pool
func return_job_to_pool(drone_id: int):
	if active_jobs.has(drone_id):
		var job = active_jobs[drone_id]
		job.assigned_drone_id = -1
		
		# Wieder vorne anstellen (High Priority)
		pending_jobs[job.required_drone_type].push_front(job)
		
		active_jobs.erase(drone_id)
		print("Job ", job.id, " zurück in Warteschlange.")

# --- HILFSFUNKTIONEN ---

func _get_next_id() -> int:
	_job_id_counter += 1
	return _job_id_counter

func _is_job_existing_for_hex(hex: Vector2i) -> bool:
	# Check in Pending
	for list in pending_jobs.values():
		for j in list:
			if j.target_hex == hex: return true
	# Check in Active
	for j in active_jobs.values():
		if j.target_hex == hex: return true
	return false
