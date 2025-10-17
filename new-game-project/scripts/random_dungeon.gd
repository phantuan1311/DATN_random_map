extends Node2D

@export var minRoomCount: int = 8
@export var maxRoomCount: int = 10

@onready var rooms: Node2D = $rooms
@onready var player_scene = preload("res://scenes/hero.tscn")
@onready var slime1_scene = preload("res://scenes/slime_1.tscn")
@onready var skeleton1_scene = preload("res://scenes/skeleton_1.tscn")
@onready var door = preload("res://scenes/door.tscn")
@onready var bat_scene = preload("res://scenes/bat_1.tscn")

const RANDOM_ROOM = preload("res://scenes/random_room.tscn")

var door_cell: Vector2i
var last_valid_room: Node2D = null
var dungeon_seed: int = 0


func _ready() -> void:
	if Global.has_save and Global.load_requested:
		Global.load_requested = false
		call_deferred("_do_load_game")
		return

	dungeon_seed = randi()
	seed(dungeon_seed)
	await _create_dungeon_with_min_loading(3.0)

	if last_valid_room:
		_spawn_door_in_room(last_valid_room)
	spawn_player()
	spawn_slime1()
	spawn_bat1() 



func _do_load_game() -> void:
	var ok = await Global.load_game()
	if not ok:
		print("❌ Load failed → tạo dungeon mới")
		dungeon_seed = randi()
		seed(dungeon_seed)
		await _create_dungeon_with_min_loading(3.0)

		if last_valid_room:
			_spawn_door_in_room(last_valid_room)
		spawn_player()
		spawn_slime1()
		spawn_bat1()
	# nếu ok == true thì Global.load_game() sẽ tự gọi load_from_data()
	# nên không cần tự tái tạo dungeon ở đây


func get_save_data(player: Node2D) -> Dictionary:
	return {
		"seed": dungeon_seed,
		"player_position": player.global_position
	}


func load_from_data(data: Dictionary) -> void:
	# Reset dungeon cũ
	for c in rooms.get_children():
		if is_instance_valid(c):
			c.queue_free()

	# Tái tạo dungeon từ seed
	if data.has("seed"):
		dungeon_seed = data["seed"]
		seed(dungeon_seed)
		await _create_dungeon_with_min_loading(3.0)

		if last_valid_room:
			_spawn_door_in_room(last_valid_room)

	# Respawn player
	var player := player_scene.instantiate()
	add_child(player)
	player.add_to_group("player")
	if data.has("player_position"):
		player.global_position = data["player_position"]

	if data.has("player_position"):
		player.global_position = data["player_position"]
	else:
		# fallback: spawn player ở phòng đầu
		var existing_rooms = rooms.get_children()
		if existing_rooms.size() > 0 and existing_rooms[0].has_node("FloorLayer"):
			var floor_layer: TileMapLayer = existing_rooms[0].get_node("FloorLayer")
			var floor_cells = floor_layer.get_used_cells()
			if not floor_cells.is_empty():
				var center_cell = floor_cells[floor_cells.size() / 2]
				var spawn_position = floor_layer.map_to_local(center_cell)
				player.global_position = floor_layer.to_global(spawn_position)

	# Spawn enemy
	spawn_slime1()
	spawn_bat1()
	spawn_skeletons_in_room(last_valid_room)

# Hàm helper: tạo dungeon + loading tối thiểu N giây
func _create_dungeon_with_min_loading(min_time: float = 3.0) -> void:
	$CanvasLayer/loading.visible = true
	var timer = get_tree().create_timer(min_time).timeout
	await _create_dungeon()
	$CanvasLayer/loading.visible = false

# -------------------- DUNGEON GENERATION --------------------

func _create_dungeon() -> void:
	var roomCount := randi_range(minRoomCount, maxRoomCount)
	for i in range(roomCount):
		await _create_room()


func _create_room() -> void:
	var existingRooms = rooms.get_children()
	var newRoom = RANDOM_ROOM.instantiate()
	rooms.add_child(newRoom)
	# owner đặt để scene tree editor không bị lẫn khi running trong editor — không bắt buộc khi export
	# newRoom.owner = get_tree().edited_scene_root

	var isFirstRoom = existingRooms.is_empty()
	if isFirstRoom:
		last_valid_room = newRoom
		return
	
	# lọc các phòng còn sống
	var possibleRooms: Array = []
	for room in existingRooms:
		if room == newRoom:
			continue
		if is_instance_valid(room):
			possibleRooms.append(room)
	
	if possibleRooms.is_empty():
		newRoom.queue_free()
		return
	
	var success: bool = false
	var tries: int = 10
	while tries > 0 and not success:
		var selectedRoom = possibleRooms.pick_random()
		# đảm bảo valid trước khi connect
		if not is_instance_valid(selectedRoom):
			tries -= 1
			continue
		# connect_with được implement trong random_room (cần await nếu là coroutine)
		success = await newRoom.connect_with(selectedRoom)
		tries -= 1

	if not success:
		newRoom.queue_free()
	else:
		last_valid_room = newRoom
		spawn_skeletons_in_room(newRoom)


func spawn_skeletons_in_room(room: Node2D) -> void:
	if not room or not room.has_node("FloorLayer"):
		return
	var floor_layer: TileMapLayer = room.get_node("FloorLayer")
	var floor_cells: Array = floor_layer.get_used_cells()
	if floor_cells.is_empty():
		return

	var skeleton_count = randi_range(2, 4)
	for i in range(skeleton_count):
		var skeleton = skeleton1_scene.instantiate()
		add_child(skeleton)

		var random_cell = floor_cells.pick_random()
		var spawn_pos = floor_layer.map_to_local(random_cell)
		skeleton.global_position = floor_layer.to_global(spawn_pos)


func _spawn_door_in_room(room: Node2D) -> void:
	if not room or not room.has_node("FloorLayer"):
		return
	
	var floor_layer: TileMapLayer = room.get_node("FloorLayer")
	var floor_cells: Array = floor_layer.get_used_cells()
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

	# Lấy connection points để tránh trùng
	var connection_points: Array[Vector2i] = []
	if room.has_method("get_connection_points"):
		connection_points = room.get_connection_points()

	# Gom thành các đoạn liên tiếp
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

	# Lọc các đoạn đủ dài, tránh connection_points
	var valid_segments: Array = []
	for seg in segments:
		if seg.size() >= 3:
			var safe_seg: Array = []
			for c in seg:
				if not connection_points.has(c):
					safe_seg.append(c)
			if safe_seg.size() >= 3:
				valid_segments.append(safe_seg)

	if valid_segments.is_empty():
		return

	# Chọn 1 đoạn và lấy cell chính giữa
	var chosen_seg: Array = valid_segments.pick_random()
	var wall_cell: Vector2i = chosen_seg[chosen_seg.size() / 2]
	door_cell = Vector2i(wall_cell.x, wall_cell.y + 1)

	# Spawn cửa
	var door_instance = door.instantiate()
	room.add_child(door_instance)

	var cell_size: Vector2i = floor_layer.tile_set.tile_size
	var wall_pos = floor_layer.map_to_local(wall_cell) + Vector2(cell_size) / 2
	wall_pos.y -= (32 - cell_size.y) / 2

	door_instance.global_position = floor_layer.to_global(wall_pos)
	print("Spawn cửa:", door_instance.global_position)

	if door_instance.has_node("AnimatedSprite2D"):
		var sprite: AnimatedSprite2D = door_instance.get_node("AnimatedSprite2D")
		sprite.play("close")


func spawn_player() -> Node2D:
	var player = player_scene.instantiate()
	add_child(player)
	player.add_to_group("player")

	var existing_rooms = rooms.get_children()
	if existing_rooms.is_empty():
		return player

	var first_room = existing_rooms[0]
	if not first_room.has_node("FloorLayer"):
		player.global_position = first_room.global_position
		return player

	var floor_layer: TileMapLayer = first_room.get_node("FloorLayer")
	var floor_cells: Array = floor_layer.get_used_cells()

	if floor_cells.is_empty():
		player.global_position = first_room.global_position
		return player

	var center_index = int(floor_cells.size() / 2)
	var center_cell = floor_cells[center_index]
	var spawn_position = floor_layer.map_to_local(center_cell)
	player.global_position = floor_layer.to_global(spawn_position)

	return player

func spawn_bat1() -> void:
	var existingRooms = rooms.get_children()
	if existingRooms.is_empty():
		return

	# Bỏ qua phòng đầu tiên (để player không bị tấn công ngay khi spawn)
	for i in range(1, existingRooms.size()):
		var room = existingRooms[i]
		if not room.has_node("FloorLayer"):
			continue
		
		var floor_layer: TileMapLayer = room.get_node("FloorLayer")
		var floor_cells: Array = floor_layer.get_used_cells()
		if floor_cells.is_empty():
			continue

		# số lượng dơi trong mỗi phòng
		var bat_count = randi_range(1, 2)
		for j in range(bat_count):
			var bat = bat_scene.instantiate()
			add_child(bat)

			var random_cell = floor_cells.pick_random()
			var spawn_position = floor_layer.map_to_local(random_cell)
			bat.global_position = floor_layer.to_global(spawn_position)



func spawn_slime1() -> void:
	var existingRooms = rooms.get_children()
	if existingRooms.is_empty():
		return

	# bỏ qua phòng đầu tiên
	for i in range(1, existingRooms.size()):
		var room = existingRooms[i]
		if not room.has_node("FloorLayer"):
			continue
		
		var floor_layer: TileMapLayer = room.get_node("FloorLayer")
		var floor_cells: Array = floor_layer.get_used_cells()
		if floor_cells.is_empty():
			continue

		var slime_count = randi_range(1, 3)
		for j in range(slime_count):
			var slime = slime1_scene.instantiate()
			add_child(slime)

			var random_cell = floor_cells.pick_random()
			var spawn_position = floor_layer.map_to_local(random_cell)
			slime.global_position = floor_layer.to_global(spawn_position)
