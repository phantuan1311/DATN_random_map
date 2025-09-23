extends Node2D

@onready var random_room: Node2D = $RandomRoom
@onready var player: CharacterBody2D = $player
@onready var boss: CharacterBody2D = $GolemBoss

func _ready():
	var floor_layer: TileMapLayer = random_room.get_node("FloorLayer")
	var floor_cells: Array = floor_layer.get_used_cells()

	if floor_cells.is_empty():
		push_error("Không tìm thấy floor trong RandomRoom")
		return

	# --- Player: góc trên bên trái ---
	var top_left_cell: Vector2i = floor_cells[0]
	for cell in floor_cells:
		if cell.x <= top_left_cell.x and cell.y <= top_left_cell.y:
			top_left_cell = cell
	player.position = floor_layer.map_to_local(top_left_cell)

	# --- Boss: giữa phòng ---
	var rect := Rect2i(floor_cells[0], Vector2i(1, 1))
	for cell in floor_cells:
		rect = rect.expand(cell)
	var center_cell: Vector2i = rect.get_center()
	boss.position = floor_layer.map_to_local(center_cell)
