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
# NEU: Speichert Daten zu den Kacheln (Menge an Ressourcen)
var tile_data = {} 
# NEU: Liste aller Gebäude (Basis + Relais)
var buildings = []
# Nebel-Logik (vorbereitet)
var explored_hexes = {}
# Kosten Konstante (muss mit HUD übereinstimmen oder zentral im GameManager liegen)
# Der Einfachheit halber definieren wir sie hier lokal nochmal für den Check
const COST_RELAY = { "metal": 40, "tech": 5 }

func _ready():
	GameManager.spawn_requested.connect(_on_spawn_requested)
	# NEU: Wir hören auf Modus-Änderungen (optional, falls wir den Cursor ändern wollen)
	
	generate_map()
	
	# Basis erstellen (und zur Liste hinzufügen)
	spawn_building(Vector2i(0,0), GameManager.TERRAIN.BASE)
	
	center_camera()
	selector.visible = false
	
	spawn_drone(Vector2i(1, 0), Drone.Type.SCOUT)
	reveal_fog(Vector2i(0,0), 3)

func generate_map():
	tile_data.clear() # Reset
	
	for q in range(-MAP_RADIUS, MAP_RADIUS + 1):
		var r1 = max(-MAP_RADIUS, -q - MAP_RADIUS)
		var r2 = min(MAP_RADIUS, -q + MAP_RADIUS)
		for r in range(r1, r2 + 1):
			var hex = Vector2i(q, r)
			var terrain_id = decide_terrain(q, r)
			ground_layer.set_cell(hex, 0, Vector2i(0,0), terrain_id)
			
			# NEU: Wenn es eine Ressource ist, Daten speichern
			if terrain_id in [GameManager.TERRAIN.BIO, GameManager.TERRAIN.METAL, GameManager.TERRAIN.TECH]:
				# Wir geben jedem Feld zufällig 50 bis 150 Einheiten
				tile_data[hex] = {
					"amount": randi_range(50, 150),
					"max_amount": 150 # Für spätere Progress-Bars
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
	pass # Kamera macht das selbst

# Diese Funktion kann jetzt Basis UND Relais bauen
func spawn_building(coords: Vector2i, type_id: int):
	var b_instance = building_scene.instantiate()
	buildings_container.add_child(b_instance)
	
	# Positionieren
	b_instance.position = ground_layer.map_to_local(coords)
	b_instance.setup(coords, type_id)
	
	# In Liste speichern
	buildings.append(b_instance)
	
	# Map-Daten aktualisieren (damit man nicht nochmal drauf baut)
	# Wir setzen die Zelle auf der Map visuell passend (oder lassen sie wie sie ist)
	# Wichtig: Wir markieren im `tile_data` oder prüfen `get_building_at` später.
	
	# Nebel aufdecken
	reveal_fog(coords, 4)

# NEU: Bau-Versuch
func try_build_relay(coords: Vector2i):
	# 1. Ist das Feld leer? (Keine Ressource, kein anderes Gebäude)
	if has_resource(coords):
		print("Kann hier nicht bauen: Ressource im Weg!")
		return
		
	for b in buildings:
		if b.hex_coords == coords:
			print("Hier steht schon ein Gebäude!")
			return

	# 2. Haben wir genug Ressourcen? (Sicherheitscheck, falls sich Werte seit Klick geändert haben)
	var res = GameManager.resources
	if res["metal"] >= COST_RELAY.metal and res["tech"] >= COST_RELAY.tech:
		
		# 3. Bezahlen
		GameManager.modify_resource("metal", -COST_RELAY.metal)
		GameManager.modify_resource("tech", -COST_RELAY.tech)
		
		# 4. Bauen
		spawn_building(coords, GameManager.TERRAIN.RELAY)
		print("Relais gebaut bei: ", coords)
		
		# 5. Modus zurücksetzen
		GameManager.set_mode(GameManager.Mode.SELECT)
		
	else:
		print("Nicht genug Ressourcen!")
		GameManager.set_mode(GameManager.Mode.SELECT)

# Alte Logik ausgelagert in eigene Funktion
func send_drone_to_target(coords: Vector2i):
	print("Klick auf: ", coords)
	var drone_sent = false
	for drone in active_drones:
		if drone.my_type == Drone.Type.SCOUT and drone.current_state == Drone.State.IDLE:
			drone.command_move_to(coords)
			drone_sent = true
			break
	if not drone_sent:
		print("Keine freie Drohne verfügbar!")
		
func spawn_drone(coords: Vector2i, type):
	var drone = drone_scene.instantiate()
	units_container.add_child(drone)
	drone.setup(coords, type, ground_layer)
	active_drones.append(drone)
	reveal_fog(coords, 3)
# NEU: Diese Funktion ruft die Drohne auf, um etwas abzubauen
# Gibt zurück, wie viel tatsächlich abgebaut wurde
func harvest_tile(coords: Vector2i, requested_amount: int) -> int:
	# Gibt es hier Daten?
	if not tile_data.has(coords):
		return 0
	
	var available = tile_data[coords]["amount"]
	var taken = min(available, requested_amount)
	
	# Menge reduzieren
	tile_data[coords]["amount"] -= taken
	
	# Wenn leer -> Tile ändern zu "EMPTY" (Boden)
	if tile_data[coords]["amount"] <= 0:
		tile_data.erase(coords)
		ground_layer.set_cell(coords, 0, Vector2i(0,0), GameManager.TERRAIN.EMPTY)
		print("Ressource bei ", coords, " erschöpft!")
		
	return taken

# NEU: Hilfsfunktion für die Drohne: Gibt es da noch was?
func has_resource(coords: Vector2i) -> bool:
	return tile_data.has(coords) and tile_data[coords]["amount"] > 0
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
	# Check: Ist Feld gültig?
	if ground_layer.get_cell_source_id(current_hover_hex) == -1:
		return

	# --- MODUS UNTERSCHEIDUNG ---
	
	if GameManager.current_mode == GameManager.Mode.BUILD_RELAY:
		try_build_relay(current_hover_hex)
		
	elif GameManager.current_mode == GameManager.Mode.SELECT:
		# Unsere alte Drohnen-Logik
		send_drone_to_target(current_hover_hex)

# Sucht das nächste Gebäude (Basis oder Relais) von einer Position aus
func get_nearest_dropoff(from_hex: Vector2i) -> Vector2i:
	var nearest_hex = Vector2i(0, 0) # Fallback: Basis
	var min_dist = 99999.0
	
	for b in buildings:
		# Abstand berechnen (wir nehmen einfach Euklidischen Abstand der Hex-Koordinaten)
		var dist = Vector2(from_hex).distance_to(Vector2(b.hex_coords))
		if dist < min_dist:
			min_dist = dist
			nearest_hex = b.hex_coords
			
	return nearest_hex
