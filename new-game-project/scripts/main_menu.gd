extends Node2D

@onready var load_button: Button = $Button_manager/load_game

func _ready() -> void:
	# Ẩn nút nếu không có file save
	load_button.visible = Global.has_save


func _on_new_game_pressed() -> void:
	Global.load_requested = false   # tạo dungeon mới
	get_tree().change_scene_to_file("res://scenes/random_dungeon.tscn")

func _on_quit_game_pressed() -> void:
	get_tree().quit()

func _on_load_game_pressed() -> void:
	if Global.has_save:
		Global.load_requested = true   # báo là muốn load game
		get_tree().change_scene_to_file("res://scenes/random_dungeon.tscn")
	else:
		print("Không có save để load.")
