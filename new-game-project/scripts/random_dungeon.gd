extends Node2D

@export var maxRoomCount = 15

@onready var rooms: Node2D = $rooms
@onready var player_scene = preload("res://scenes/hero.tscn")
@onready var slime1_scene = preload("res://scenes/slime_1.tscn")
@onready var skeleton1_scene = preload("res://scenes/skeleton_1.tscn")
@onready var door = preload("res://scenes/door.tscn")

const RANDOM_ROOM = preload("res://scenes/random_room.tscn")
var door_cell : Vector2i
var last_valid_room: Node2D = null

func _ready() -> void:
	await _create_dungeon()
	
	if last_valid_room:
		_spawn_door_in_room(last_valid_room)

	spawn_player()
	spawn_slime1()
	
func _create_dungeon() -> void:
	var roomCount := randi_range(8, maxRoomCount)

	for i in roomCount: 
		await _create_room()

		
func _create_room():
	var existingRooms = rooms.get_children()
	
	var newRoom = RANDOM_ROOM.instantiate()
	rooms.add_child(newRoom)
	newRoom.owner = get_tree().edited_scene_root
	
	var isFirstRoom = existingRooms.is_empty()
	if isFirstRoom:
		last_valid_room = newRoom
		spawn_skeletons_in_room(newRoom)
		return
	
	var possibleRooms = []
	for room in existingRooms:
		if room == newRoom: continue
		possibleRooms.append(room)
	
	var selectedRoom = possibleRooms.pick_random()
	var success = await newRoom.connect_with(selectedRoom)
	
	var tries = 8
	while not success and tries > 0:
		selectedRoom = possibleRooms.pick_random()
		success = await newRoom.connect_with(selectedRoom)
		tries -= 1

	if not success:
		newRoom.queue_free()
	else:
		last_valid_room = newRoom
		spawn_skeletons_in_room(newRoom)

func spawn_skeletons_in_room(room: Node2D):
	if not room.has_node("FloorLayer"):
		return
	var floor_layer: TileMapLayer = room.get_node("FloorLayer")
	var floor_cells = floor_layer.get_used_cells()
	if floor_cells.is_empty():
		return

	var skeleton_count = randi_range(2, 4)
	for i in skeleton_count:
		var skeleton = skeleton1_scene.instantiate()
		add_child(skeleton)

		var random_cell = floor_cells.pick_random()
		var spawn_pos = floor_layer.map_to_local(random_cell)
		skeleton.global_position = floor_layer.to_global(spawn_pos)


func _spawn_door_in_room(room: Node2D):
	if not room.has_node("FloorLayer"):
		return
	
	var floor_layer: TileMapLayer = room.get_node("FloorLayer")
	var floor_cells = floor_layer.get_used_cells()
	if floor_cells.is_empty():
		return

	# Xác định hàng top nhất của floor
	var top_y = floor_cells[0].y
	for cell in floor_cells:
		if cell.y < top_y:
			top_y = cell.y

	# Tìm tất cả wall cell nằm trên hàng floor cao nhất
	var wall_row: Array[Vector2i] = []
	for cell in floor_cells:
		if cell.y == top_y:
			var wall_cell = cell + Vector2i(0, -1)
			wall_row.append(wall_cell)

	if wall_row.is_empty():
		return

	# --- Gom thành các đoạn liên tiếp ---
	wall_row.sort_custom(func(a, b): return a.x < b.x)
	var segments: Array = []
	var current_segment: Array = []
	for wc in wall_row:
		if current_segment.is_empty() or wc.x == current_segment[-1].x + 1:
			current_segment.append(wc)
		else:
			if current_segment.size() > 0:
				segments.append(current_segment.duplicate())
			current_segment.clear()
			current_segment.append(wc)
	if current_segment.size() > 0:
		segments.append(current_segment)

	# Lọc các đoạn đủ dài để đặt cửa
	var valid_segments: Array = []
	for seg in segments:
		if seg.size() >= 3:
			valid_segments.append(seg)

	if valid_segments.is_empty():
		return

	# Chọn 1 đoạn và lấy cell chính giữa
	var chosen_seg: Array = valid_segments.pick_random()
	var wall_cell: Vector2i = chosen_seg[chosen_seg.size() / 2]
	door_cell = Vector2i(wall_cell.x, wall_cell.y + 1) # floor ngay dưới cửa

	# --- Tạo cửa ---
	var door_instance = door.instantiate()
	room.add_child(door_instance)

	var cell_size: Vector2i = floor_layer.tile_set.tile_size
	var wall_pos = floor_layer.map_to_local(wall_cell) + Vector2(cell_size) / 2

	# Vì cửa cao 48, tile 32 → dịch cho vừa wall
	wall_pos.y -= (32 - cell_size.y) / 2

	door_instance.global_position = floor_layer.to_global(wall_pos)
	print("Spawn cửa ở giữa TOP WALL tại:", door_instance.global_position)

	# Animation mặc định
	if door_instance.has_node("AnimatedSprite2D"):
		var sprite: AnimatedSprite2D = door_instance.get_node("AnimatedSprite2D")
		sprite.play("close")

func spawn_player():
	var player = player_scene.instantiate()
	add_child(player)

	var existing_rooms = rooms.get_children()
	if existing_rooms.is_empty():
		return

	# Lấy phòng đầu tiên
	var first_room = existing_rooms[0]
	var floor_layer: TileMapLayer = first_room.get_node("FloorLayer")

	# Spawn ở giữa phòng đầu tiên
	var floor_cells = floor_layer.get_used_cells()
	if floor_cells.is_empty():
		# Nếu map chưa có ô nào, đặt ở chính giữa phòng
		player.global_position = first_room.global_position
		return

	var center_index = floor_cells.size() / 2
	var center_cell = floor_cells[center_index]
	var spawn_position = floor_layer.map_to_local(center_cell)
	player.global_position = floor_layer.to_global(spawn_position)



func spawn_slime1():
	var existingRooms = rooms.get_children()
	if existingRooms.is_empty():
		return

	# bỏ qua phòng đầu tiên (tutorial room)
	for i in range(1, existingRooms.size()):
		var room = existingRooms[i]
		if not room.has_node("FloorLayer"):
			continue
		
		var floor_layer: TileMapLayer = room.get_node("FloorLayer")
		var floor_cells = floor_layer.get_used_cells()
		if floor_cells.is_empty():
			continue

		# số slime ngẫu nhiên trong phòng 
		var slime_count = randi_range(1, 3)
		for j in slime_count:
			var slime = slime1_scene.instantiate()
			add_child(slime)

			# chọn một cell bất kỳ trong floor
			var random_cell = floor_cells.pick_random()
			var spawn_position = floor_layer.map_to_local(random_cell)
			slime.global_position = floor_layer.to_global(spawn_position)
