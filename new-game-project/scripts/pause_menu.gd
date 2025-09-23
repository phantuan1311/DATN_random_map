extends Control

var is_paused: bool = false : set = set_is_paused

func _ready() -> void:
	# Ẩn menu lúc bắt đầu
	visible = false
	# Cho phép menu hoạt động kể cả khi game paused
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		is_paused = !is_paused

func set_is_paused(value: bool) -> void:
	is_paused = value
	get_tree().paused = is_paused
	visible = is_paused   # menu hiện khi pause, ẩn khi resume

func _on_continue_pressed() -> void:
	is_paused = false     # resume game + ẩn menu

func _on_back_to_menu_pressed() -> void:
	is_paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
