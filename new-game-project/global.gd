extends Node

var save_path := "user://savegame.save"
var has_save: bool = false
var load_requested: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_check_existing_save()
	#print(ProjectSettings.globalize_path("user://savegame.save"))
	# Tạo timer auto-save
	var timer := Timer.new()
	timer.wait_time = 5.0
	timer.autostart = true
	timer.one_shot = false
	timer.timeout.connect(_on_autosave)
	add_child(timer)

	print("Global ready, auto-save timer started.")


func _check_existing_save() -> void:
	if FileAccess.file_exists(save_path):
		has_save = true
	else:
		has_save = false


func save_game(dungeon: Node2D, player: Node2D) -> void:
	# yêu cầu dungeon có func get_save_data(player) -> Dictionary
	if not dungeon or not player:
		return

	var data = dungeon.get_save_data(player)

	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_var(data)
		file.close()
		has_save = true
		print("Game saved at:", Time.get_datetime_string_from_system())


func load_game(dungeon: Node2D) -> bool:
	if not has_save:
		return false

	var file := FileAccess.open(save_path, FileAccess.READ)
	if file:
		var data: Dictionary = file.get_var()
		file.close()
		# yêu cầu dungeon có func load_from_data(data: Dictionary)
		dungeon.load_from_data(data)
		return true
	return false


func _on_autosave() -> void:
	var dungeon := get_tree().get_first_node_in_group("Dungeon")
	var player := get_tree().get_first_node_in_group("player")

	print("Autosave tick. Dungeon:", dungeon, " Player:", player)

	if dungeon and player:
		save_game(dungeon, player)
