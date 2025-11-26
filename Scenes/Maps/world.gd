extends Node2D

@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var selector: Sprite2D = $Selector
@onready var buildings_container = $Buildings
@onready var units_container = $Units

var building_scene = preload("res://Scenes/Entities/Building.tscn")
var drone_scene = preload("res://Scenes/Entities/Drone.tscn")

const MAP_RADIUS = 10 
var current_hover_hex: Vector2i = Vector2i.ZERO
var active_drones = []

# Daten zu den Kacheln (Menge an Ressourcen)
var tile_data = {} 
# Liste aller Gebäude (Basis + Relais)
var buildings = []
# Nebel-Logik
var explored_hexes = {}

const COST_RELAY = { "metal": 40, "tech": 5 }

# --- NEU: Job Manager Referenz ---
var job_manager: JobManager

func _ready():
	GameManager.spawn_requested.connect(_on_spawn_requested)
	
	# 1. JobManager initialisieren
	job_manager = JobManager.new()
	add_child(job_manager)
	
	generate_map()
	
	# Basis erstellen
	spawn_building(Vector2i(0,0), GameManager.TERRAIN.BASE)
	
	center_camera()
	selector.visible = false
	
	# Start-Drohne
	spawn_drone(Vector2i(1, 0), GameManager.DroneType.HARVESTER)
	reveal_fog(Vector2i(0,0), 3)

func generate_map():
	tile_data.clear() 
	for q in range(-MAP_RADIUS, MAP_RADIUS + 1):
		var r1 = max(-MAP_RADIUS, -q - MAP_RADIUS)
		var r2 = min(MAP_RADIUS, -q + MAP_RADIUS)
		for r in range(r1, r2 + 1):
			var hex = Vector2i(q, r)
			var terrain_id = decide_terrain(q, r)
			# terrain_id als "alternative_tile" setzen (4. Parameter)
			ground_layer.set_cell(hex, 0, Vector2i(0,0), terrain_id)
			
			if terrain_id in [GameManager.TERRAIN.BIO, GameManager.TERRAIN.METAL, GameManager.TERRAIN.TECH]:
				tile_data[hex] = {
					"amount": randi_range(50, 150),
					"max_amount": 150
				}

func decide_terrain(q, r) -> int:
	if q == 0 and r == 0:
		return GameManager.TERRAIN.EMPTY
	var rng = randf()
	if rng < 0.08: return GameManager.TERRAIN.ROCK
	elif rng < 0.16: return GameManager.TERRAIN.BIO
	elif rng < 0.22: return GameManager.TERRAIN.METAL
	elif rng < 0.25: return GameManager.TERRAIN.TECH
	return GameManager.TERRAIN.EMPTY

func center_camera():
	pass 

func spawn_building(coords: Vector2i, type_id: int):
	var b_instance = building_scene.instantiate()
	buildings_container.add_child(b_instance)
	b_instance.position = ground_layer.map_to_local(coords)
	b_instance.setup(coords, type_id)
	buildings.append(b_instance)
	reveal_fog(coords, 4)

func try_build_relay(coords: Vector2i):
	if has_resource(coords):
		print("Kann hier nicht bauen: Ressource im Weg!")
		return
		
	for b in buildings:
		if b.hex_coords == coords:
			print("Hier steht schon ein Gebäude!")
			return

	var res = GameManager.resources
	if res["metal"] >= COST_RELAY.metal and res["tech"] >= COST_RELAY.tech:
		GameManager.modify_resource("metal", -COST_RELAY.metal)
		GameManager.modify_resource("tech", -COST_RELAY.tech)
		spawn_building(coords, GameManager.TERRAIN.RELAY)
		print("Relais gebaut bei: ", coords)
		GameManager.set_mode(GameManager.Mode.SELECT)
	else:
		print("Nicht genug Ressourcen!")
		GameManager.set_mode(GameManager.Mode.SELECT)

# --- NEU: Aktualisierte Spawn Funktion ---
func spawn_drone(coords: Vector2i, type):
	var drone = drone_scene.instantiate()
	units_container.add_child(drone)
	
	# Hier nutzen wir die neue setup Signatur
	# Wir übergeben 'self' (World), den 'job_manager' und die 'ground_layer'
	drone.setup(drone.get_instance_id(), type, self, job_manager, ground_layer)
	
	# Position manuell setzen, da setup() keine Koordinaten mehr nimmt
	drone.position = ground_layer.map_to_local(coords)
	# Falls die Drohne interne Koordinaten speichert:
	if "hex_coords" in drone:
		drone.hex_coords = coords
		
	active_drones.append(drone)
	reveal_fog(coords, 3)

func harvest_tile(coords: Vector2i, requested_amount: int) -> int:
	if not tile_data.has(coords):
		return 0
	
	var available = tile_data[coords]["amount"]
	var taken = min(available, requested_amount)
	tile_data[coords]["amount"] -= taken
	
	if tile_data[coords]["amount"] <= 0:
		tile_data.erase(coords)
		# Visuell entfernen (auf EMPTY setzen)
		ground_layer.set_cell(coords, 0, Vector2i(0,0), GameManager.TERRAIN.EMPTY)
		print("Ressource bei ", coords, " erschöpft!")
		
	return taken

func has_resource(coords: Vector2i) -> bool:
	return tile_data.has(coords) and tile_data[coords]["amount"] > 0

func _on_spawn_requested(type):
	# Spawnt an der Basis (0,0)
	spawn_drone(Vector2i(0, 0), type)
	print("Neue Drohne erstellt!")

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			handle_click()

func _process(_delta):
	update_hover()

func update_hover():
	var mouse_pos = get_global_mouse_position()
	var local_pos = ground_layer.to_local(mouse_pos)
	var map_coords = ground_layer.local_to_map(local_pos)
	
	if map_coords != current_hover_hex:
		current_hover_hex = map_coords
		if ground_layer.get_cell_source_id(map_coords) != -1:
			selector.visible = true
			selector.position = ground_layer.map_to_local(map_coords)
		else:
			selector.visible = false

func reveal_fog(_center_hex: Vector2i, _radius: int):
	pass

# --- NEU: Aktualisierte Klick-Logik ---
func handle_click():
	if ground_layer.get_cell_source_id(current_hover_hex) == -1:
		return

	if GameManager.current_mode == GameManager.Mode.BUILD_RELAY:
		try_build_relay(current_hover_hex)
		
	elif GameManager.current_mode == GameManager.Mode.SELECT:
		# Anstatt eine Drohne direkt zu steuern, erstellen wir einen Job!
		
		# 1. Prüfen: Ist da eine Ressource?
		var res_name = get_resource_name_at(current_hover_hex)
		
		if res_name != "":
			# Job erstellen: "Ernte Biomass an Position X"
			job_manager.create_harvest_job(current_hover_hex, res_name)
			
			# Kleines visuelles Feedback (optional)
			# print("Auftrag erstellt: Abbau von " + res_name)
		else:
			print("Hier gibt es nichts abzubauen.")

# Hilfsfunktion: Wandelt Tile-ID in Ressourcen-Namen um
func get_resource_name_at(coords: Vector2i) -> String:
	# Wir nutzen die alternative_tile ID, die wir beim Generieren gesetzt haben
	var tile_id = ground_layer.get_cell_alternative_tile(coords)
	
	match tile_id:
		GameManager.TERRAIN.BIO: return "biomass"
		GameManager.TERRAIN.METAL: return "metal"
		GameManager.TERRAIN.TECH: return "tech"
	
	return ""

func get_nearest_dropoff(from_hex: Vector2i) -> Vector2i:
	var nearest_hex = Vector2i(0, 0)
	var min_dist = 99999.0
	
	for b in buildings:
		var dist = Vector2(from_hex).distance_to(Vector2(b.hex_coords))
		if dist < min_dist:
			min_dist = dist
			nearest_hex = b.hex_coords
			
	return nearest_hex
