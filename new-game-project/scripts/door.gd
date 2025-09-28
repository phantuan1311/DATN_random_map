extends Area2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var door_center = $DoorCenter # Node2D đặt ở giữa cửa, làm target hút

func _ready() -> void:
	anim.play("close")

func _on_detect_player_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.speed = 0
		anim.play("open")

		await anim.animation_finished

		var tween := create_tween()
		tween.set_parallel(true) # chạy 2 tween cùng lúc

		# hút vào tâm cửa
		tween.tween_property(body, "position", door_center.global_position, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)

		# thu nhỏ dần player
		if body.has_node("Sprite2D"): # nếu player có sprite con
			var spr: Node2D = body.get_node("Sprite2D")
			tween.tween_property(spr, "scale", Vector2(0.0, 0), 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		else:
			# thu nhỏ cả node player luôn
			tween.tween_property(body, "scale", Vector2(0.0, 0), 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)

		await tween.finished
		get_tree().change_scene_to_file("res://scenes/boss_room.tscn")
