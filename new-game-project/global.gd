extends Node

var save_path: String = "user://savegame.save"
var has_save: bool = false
var load_requested: bool = false
var auto_save_enabled: bool = true

var coins: int = 0

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


# =========================================================
# Kiểm tra file save hiện có
# =========================================================
func _check_existing_save() -> void:
	has_save = FileAccess.file_exists(save_path)


# =========================================================
# Lưu game (bao gồm coin)
# =========================================================
func save_game(dungeon: Node2D, player: Node2D) -> void:
	if player == null:
		print("⚠ Không tìm thấy player, huỷ save.")
		return

	# ✅ Xác định scene thật sự của player
	var current_scene_node := player.get_tree().current_scene
	var current_scene_path: String = current_scene_node.scene_file_path if current_scene_node else ""
	if current_scene_path == "":
		print("⚠ Không xác định được scene hiện tại.")
		return

	# ✅ Thu thập dữ liệu Dungeon nếu có
	var dungeon_data: Dictionary = {}
	if dungeon and dungeon.has_method("get_save_data"):
		dungeon_data = dungeon.get_save_data(player)

	# ✅ Dữ liệu Player + coin toàn cục
	var player_data: Dictionary = {
		"health": player.health,
		"max_health": player.max_health,
		"position": player.global_position,
		"coins": coins  # 💰 Lưu cả số xu
	}

	# ✅ Gói dữ liệu tổng thể
	var data: Dictionary = {
		"scene": current_scene_path,
		"dungeon": dungeon_data,
		"player": player_data
	}

	# ✅ Ghi file
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_var(data)
		file.close()
		has_save = true
		print("💾 Saved at:", Time.get_datetime_string_from_system(), "| Scene:", current_scene_path, "| Coins:", coins)
	else:
		print("❌ Không thể ghi file save!")


# =========================================================
# Load lại game (bao gồm coin)
# =========================================================
func load_game() -> bool:
	if not has_save:
		print("❌ Không có file save để load.")
		return false

	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		print("❌ Lỗi mở file save.")
		return false

	var data: Dictionary = file.get_var()
	file.close()

	var scene_path: String = data.get("scene", "")
	if scene_path == "":
		print("❌ Save không chứa thông tin scene.")
		return false

	print("📂 Loading save... scene =", scene_path)

	# ✅ Chuyển tới đúng scene cũ
	if get_tree().current_scene.scene_file_path != scene_path:
		get_tree().change_scene_to_file(scene_path)
		await get_tree().process_frame

	# ✅ Load dungeon nếu có
	var d: Node = get_tree().get_first_node_in_group("Dungeon")
	if d and d.has_method("load_from_data"):
		await d.load_from_data(data.get("dungeon", {}))
	else:
		print("ℹ Không có dungeon để load (có thể là boss_room).")

	# ✅ Load player
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

		# 💰 Khôi phục coin
		if "coins" in p_data:
			coins = int(p_data["coins"])
	else:
		print("❌ Không tìm thấy player sau khi load!")

	print("✅ Game loaded thành công từ", scene_path, "| Coins:", coins)
	return true


# =========================================================
# Xoá file save
# =========================================================
func delete_save() -> void:
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
		print("🗑 Save file deleted")
	has_save = false
	auto_save_enabled = false


# =========================================================
# Tự động lưu định kỳ
# =========================================================
func _on_autosave() -> void:
	if not auto_save_enabled:
		return

	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	var dungeon: Node2D = get_tree().get_first_node_in_group("Dungeon") as Node2D
	if player:
		save_game(dungeon, player)
