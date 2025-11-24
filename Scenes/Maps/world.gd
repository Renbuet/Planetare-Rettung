extends Node2D

@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var selector: Sprite2D = $Selector

# Container
@onready var buildings_container = $Buildings
@onready var units_container = $Units # Neuer Container für Einheiten!

# Szenen
var building_scene = preload("res://Scenes/Entities/Building.tscn")
var drone_scene = preload("res://Scenes/Entities/Drone.tscn") # NEU

const MAP_RADIUS = 10 
var current_hover_hex: Vector2i = Vector2i.ZERO

# Liste aller aktiven Drohnen (für einfachen Zugriff)
var active_drones = []

func _ready():
	generate_map()
	spawn_base() # NEU
	center_camera()
	selector.visible = false
	spawn_drone(Vector2i(1, 0), Drone.Type.SCOUT)
	
func spawn_base():
	var base_coords = Vector2i(0, 0)
	
	# Instanz erstellen (wie 'new Drone()' in JS)
	var base_instance = building_scene.instantiate()
	
	# Zum Container hinzufügen
	buildings_container.add_child(base_instance)
	
	# Positionieren
	base_instance.position = ground_layer.map_to_local(base_coords)
	base_instance.setup(base_coords, GameManager.TERRAIN.BASE)
	
func generate_map():
	# ... (dein bestehender Code bleibt hier gleich) ...
	for q in range(-MAP_RADIUS, MAP_RADIUS + 1):
		var r1 = max(-MAP_RADIUS, -q - MAP_RADIUS)
		var r2 = min(MAP_RADIUS, -q + MAP_RADIUS)
		for r in range(r1, r2 + 1):
			var hex_coords = Vector2i(q, r)
			var terrain_id = decide_terrain(q, r)
			ground_layer.set_cell(hex_coords, 0, Vector2i(0,0), terrain_id)

func decide_terrain(q, r) -> int:
	# ... (dein bestehender Code bleibt hier gleich) ...
	# ACHTUNG: Wir entfernen hier "BASE", da die Basis jetzt ein echtes Objekt wird!
	if q == 0 and r == 0:
		return GameManager.TERRAIN.EMPTY # Erstmal leerer Boden
	
	var rng = randf()
	if rng < 0.08: return GameManager.TERRAIN.ROCK
	elif rng < 0.16: return GameManager.TERRAIN.BIO
	elif rng < 0.22: return GameManager.TERRAIN.METAL
	elif rng < 0.25: return GameManager.TERRAIN.TECH
	return GameManager.TERRAIN.EMPTY

# NEU: Drohnen Spawner
func spawn_drone(coords: Vector2i, type):
	var drone = drone_scene.instantiate()
	units_container.add_child(drone)
	
	# Setup aufrufen (wir übergeben ground_layer für die Positions-Berechnung)
	drone.setup(coords, type, ground_layer)
	
	active_drones.append(drone)
	print("Drohne gespawnt bei: ", coords)

func center_camera():
	pass

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
		
		# Check: Sind wir überhaupt auf einem gültigen Tile?
		if ground_layer.get_cell_source_id(map_coords) != -1:
			selector.visible = true
			# HIER IST DER TRICK: Wir setzen die Position des Sprites auf die Mitte des Hexagons
			selector.position = ground_layer.map_to_local(map_coords)
			
			# Optional: Farbe ändern, je nachdem ob man bauen kann (später)
		else:
			selector.visible = false

func handle_click():
	# Prüfen, ob Feld gültig ist
	var source_id = ground_layer.get_cell_source_id(current_hover_hex)
	if source_id == -1:
		return

	print("Klick auf: ", current_hover_hex)
	
	# Wir nehmen einfach die erste Drohne zum Testen
	if active_drones.size() > 0:
		var scout = active_drones[0]
		
		# Was ist auf dem Feld?
		var tile_type = ground_layer.get_cell_alternative_tile(current_hover_hex)
		
		# Logik: Wenn es eine Ressource ist (ID 2, 3, 4), flieg hin
		# (2=Bio, 3=Metal, 4=Tech laut GameManager)
		if tile_type in [2, 3, 4]:
			scout.command_move_to(current_hover_hex)
			# Ressourcentyp merken wir uns später noch genauer
		else:
			# Wenn es leeres Land ist, flieg einfach nur hin (ohne Abbauen)
			# Das müssen wir in der Drohne noch unterscheiden, aber 
			# für jetzt reicht move_to, da die Drohne dann versucht abzubauen 
			# und nach 2 Sekunden zurückkommt.
			scout.command_move_to(current_hover_hex)
