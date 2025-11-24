extends Node2D

@export var type_id: int = GameManager.TERRAIN.BASE
var hex_coords: Vector2i

# Lagerraum (wichtig für Logistik)
var storage = {
	"biomass": 0,
	"metal": 0,
	"tech": 0
}

func setup(coords: Vector2i, type: int):
	hex_coords = coords
	type_id = type
	
	# Optik anpassen je nach Typ (Basis vs Relais)
	if type == GameManager.TERRAIN.RELAY:
		$Sprite2D.modulate = Color("a855f7") # Lila
		$Label.text = "R"
	else:
		$Sprite2D.modulate = Color("f97316") # Orange
		$Label.text = "B"
