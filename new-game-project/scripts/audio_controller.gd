extends Node2D

@export var mute: bool = false

var _last_scene_path: String = ""

func _ready():
	if not mute:
		play_music_by_group()

	set_process(true)


func _process(_delta):
	var current_scene = get_tree().current_scene
	if current_scene == null:
		return

	var scene_path = current_scene.scene_file_path
	if scene_path != _last_scene_path:
		_last_scene_path = scene_path
		play_music_by_group()


func play_music_by_group():
	$main.stop()
	$dungeon.stop()
	$boss.stop()

	var current_scene = get_tree().current_scene
	if current_scene == null:
		return

	if current_scene.is_in_group("menu"):
		$main.play()
		print("🎵 Playing main theme (menu)")

	elif current_scene.is_in_group("dungeon_bg"):
		$dungeon.play()
		print("🎵 Playing dungeon theme")

	elif current_scene.is_in_group("boss_bg"):
		$boss.play()
		print("🎵 Playing boss theme")

	else:
		print("🎵 Scene không thuộc group nào để phát nhạc.")
