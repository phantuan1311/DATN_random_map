extends Node

var save_path := "user://savegame.save"
var has_save: bool = false
var load_requested: bool = false

# Auto save mỗi 2 giây
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_check_existing_save()
	# Timer auto-save
	var timer := Timer.new()
	timer.wait_time = 2.0
	timer.autostart = true
	timer.one_shot = false
	timer.timeout.connect(_on_autosave)
	add_child(timer)


func _check_existing_save() -> void:
	if FileAccess.file_exists(save_path):
		has_save = true
	else:
		has_save = false


func save_game(dungeon: Node2D, player: Node2D) -> void:
	var data = dungeon.get_save_data(player)
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_var(data)
		file.close()
		has_save = true
		print("Game saved.")


func load_game(dungeon: Node2D) -> bool:
	if not has_save:
		return false

	var file := FileAccess.open(save_path, FileAccess.READ)
	if file:
		var data: Dictionary = file.get_var()
		file.close()
		dungeon.load_from_data(data)
		return true
	return false


func _on_autosave() -> void:
	# chỉ auto-save nếu có player trong scene
	var dungeon := get_tree().get_first_node_in_group("Dungeon")
	var player := get_tree().get_first_node_in_group("Player")
	if dungeon and player:
		save_game(dungeon, player)
