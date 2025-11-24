extends Camera2D

# Konfiguration
@export var pan_speed: float = 1.0
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 3.0

# Status-Variablen für Dragging
var is_dragging: bool = false
var last_mouse_pos: Vector2 = Vector2.ZERO

func _unhandled_input(event: InputEvent):
	# --- Zoom (Mausrad) ---
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_in()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_out()
			
		# --- Start Dragging (Linke Maustaste oder Mittlere) ---
		# Wir prüfen auf 'cam_drag', was wir in den Projekteinstellungen definiert haben
		# oder einfach direkt auf Button Left/Middle
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				start_drag()
			else:
				stop_drag()

	# --- Dragging Bewegung ---
	if event is InputEventMouseMotion and is_dragging:
		# Wir bewegen die Kamera entgegen der Mausbewegung
		position -= event.relative / zoom.x

func start_drag():
	is_dragging = true
	
func stop_drag():
	is_dragging = false

func zoom_in():
	var new_zoom = zoom.x + zoom_speed
	set_zoom_level(new_zoom)

func zoom_out():
	var new_zoom = zoom.x - zoom_speed
	set_zoom_level(new_zoom)

func set_zoom_level(value: float):
	# Begrenzen (Clamp) und anwenden
	value = clamp(value, min_zoom, max_zoom)
	zoom = Vector2(value, value)
