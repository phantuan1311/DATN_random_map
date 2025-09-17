extends Area2D

@onready var anim = $AnimatedSprite2D   # gắn node AnimatedSprite2D vào đây

func _ready() -> void:
	anim.play("close")   # mặc định cửa đóng

func _on_detect_player_body_entered(body):
	if body.is_in_group("player"):
		anim.play("open")
