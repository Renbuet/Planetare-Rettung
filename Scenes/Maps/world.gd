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

# Nebel-Logik (vorbereitet)
var explored_hexes = {}

func _ready():
	# Signal verbinden: Wenn der Button im HUD gedrückt wird
	GameManager.spawn_requested.connect(_on_spawn_requested)
	
	generate_map()
	spawn_base()
	center_camera()
	selector.visible = false
	
	# Einen Start-Scout spawnen
	spawn_drone(Vector2i(1, 0), Drone.Type.SCOUT)
	
	reveal_fog(Vector2i(0,0), 3)

func generate_map():
	for q in range(-MAP_RADIUS, MAP_RADIUS + 1):
		var r1 = max(-MAP_RADIUS, -q - MAP_RADIUS)
		var r2 = min(MAP_RADIUS, -q + MAP_RADIUS)
		for r in range(r1, r2 + 1):
			var hex = Vector2i(q, r)
			var terrain_id = decide_terrain(q, r)
			ground_layer.set_cell(hex, 0, Vector2i(0,0), terrain_id)

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
	pass # Kamera macht das selbst

func spawn_base():
	var base_instance = building_scene.instantiate()
	buildings_container.add_child(base_instance)
	base_instance.position = ground_layer.map_to_local(Vector2i(0, 0))
	base_instance.setup(Vector2i(0, 0), GameManager.TERRAIN.BASE)

func spawn_drone(coords: Vector2i, type):
	var drone = drone_scene.instantiate()
	units_container.add_child(drone)
	drone.setup(coords, type, ground_layer)
	active_drones.append(drone)
	reveal_fog(coords, 3)

# Diese Funktion wird vom GameManager aufgerufen (vom HUD Button)
func _on_spawn_requested(type):
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
	# Platzhalter für später
	pass

# --- WICHTIGE ÄNDERUNG HIER ---
func handle_click():
	# Prüfen, ob Feld gültig ist
	if ground_layer.get_cell_source_id(current_hover_hex) == -1:
		return

	print("Klick auf: ", current_hover_hex)
	
	# Wir suchen eine Drohne, die Zeit hat (State == IDLE)
	var drone_sent = false
	
	for drone in active_drones:
		# Wir prüfen: Ist es ein Scout? UND hat er gerade nichts zu tun?
		if drone.my_type == Drone.Type.SCOUT and drone.current_state == Drone.State.IDLE:
			drone.command_move_to(current_hover_hex)
			drone_sent = true
			break # WICHTIG: Wir brechen ab, damit nur EINE Drohne losfliegt!
	
	if not drone_sent:
		print("Keine freie Drohne verfügbar! (Alle beschäftigt)")
