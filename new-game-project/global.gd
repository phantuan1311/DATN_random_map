extends Node

var save_path: String = "user://savegame.save"
var has_save: bool = false
var load_requested: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_check_existing_save()

	var timer := Timer.new()
	timer.wait_time = 5.0
	timer.autostart = true
	timer.one_shot = false
	timer.timeout.connect(_on_autosave)
	add_child(timer)
	print("✅ Global ready, auto-save timer started.")


func _check_existing_save() -> void:
	has_save = FileAccess.file_exists(save_path)


func save_game(dungeon: Node2D, player: Node2D) -> void:
	if dungeon == null or player == null:
		return

	var current_scene: String = get_tree().current_scene.scene_file_path

	var dungeon_data: Dictionary = {}
	if dungeon.has_method("get_save_data"):
		dungeon_data = dungeon.get_save_data(player)

	var player_data: Dictionary = {
		"health": player.health,
		"max_health": player.max_health,
		"position": player.global_position,
	}

	var data: Dictionary = {
		"scene": current_scene,
		"dungeon": dungeon_data,
		"player": player_data,
	}

	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_var(data)
		file.close()
		has_save = true
		print("💾 Game saved at:", Time.get_datetime_string_from_system())


func load_game() -> bool:
	if not has_save:
		return false

	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return false

	var data: Dictionary = file.get_var()
	file.close()

	var scene_path: String = data.get("scene", "res://scenes/random_dungeon.tscn")
	print("📂 Loading save... scene =", scene_path)

	if get_tree().current_scene.scene_file_path != scene_path:
		get_tree().change_scene_to_file(scene_path)
		await get_tree().process_frame

	# restore dungeon
	var d: Node = get_tree().get_first_node_in_group("Dungeon")
	if d and d.has_method("load_from_data"):
		await d.load_from_data(data.get("dungeon", {}))
	else:
		print("❌ Dungeon not found!")

	# restore player
	var p_data: Dictionary = data.get("player", {})
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player:
		if "max_health" in p_data:
			player.max_health = p_data["max_health"]
		if "health" in p_data:
			player.health = clamp(p_data["health"], 0, player.max_health)
			if player.has_method("update_heart_display"):
				player.update_heart_display()
		if "position" in p_data:
			player.global_position = p_data["position"]
	else:
		print("❌ Player not found after load!")

	print("✅ Game loaded from save.")
	return true


func delete_save() -> void:
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
		print("🗑 Save file deleted")
	has_save = false


func _on_autosave() -> void:
	var dungeon: Node2D = get_tree().get_first_node_in_group("Dungeon") as Node2D
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if dungeon and player:
		save_game(dungeon, player)
