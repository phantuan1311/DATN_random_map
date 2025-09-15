extends Node2D

@export var maxRoomCount = 12

@onready var rooms: Node2D = $rooms
@onready var player_scene = preload("res://scenes/hero.tscn")
@onready var slime1_scene = preload("res://scenes/skeleton_1.tscn")

const RANDOM_ROOM = preload("res://scenes/random_room.tscn")

func _ready() -> void:
	await _create_dungeon()
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
	if isFirstRoom: return
	
	var possibleRooms = []
	for room in existingRooms:
		if room == newRoom: continue
		possibleRooms.append(room)
	
	var selectedRoom = possibleRooms.pick_random()
	var success = await newRoom.connect_with(selectedRoom)
	
	var tries = 10
	while not success and tries > 0:
		selectedRoom = possibleRooms.pick_random()
		success = await newRoom.connect_with(selectedRoom)
		tries -= 1

	if not success:
		newRoom.queue_free()
		

func _on_button_pressed() -> void:
	for node in rooms.get_children():
		node.queue_free()
		
	await get_tree().create_timer(0.1).timeout
	
	_ready()

func spawn_player():
	var player = player_scene.instantiate()
	add_child(player)

	# lấy phòng đầu tiên trong danh sách rooms
	var existingRooms = rooms.get_children()
	if existingRooms.is_empty():
		return
	
	var first_room = existingRooms[0]
	var floor_layer = first_room.get_node("FloorLayer")

	# lấy tất cả cell đã dùng trong Floor
	var floor_cells = floor_layer.get_used_cells()

	if floor_cells.is_empty():
		player.global_position = first_room.position
		return

	# chọn cell trung tâm
	var center_cell = floor_cells[floor_cells.size() / 2]

	# chuyển từ cell -> toạ độ local -> toạ độ global
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
		
		var floor_layer = room.get_node("FloorLayer")
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
