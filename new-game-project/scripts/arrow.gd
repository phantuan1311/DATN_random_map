extends Area2D

var speed = 220
@export var damage: int = 35


func _ready():
	set_as_top_level(true) #hàm này để đạn luôn ở layer trên nhất/ không bị che bởi assets khác

func _process(delta):
	position += (Vector2.RIGHT*speed).rotated(rotation) * delta


func _on_visible_on_screen_enabler_2d_screen_exited():
	queue_free()

func get_damage() -> int:
	return damage

func _on_body_entered(body):
	if body.is_in_group("boss"):
		body.take_damage()
		queue_free()
	elif body.is_in_group("monster"):
		queue_free()
	elif body.is_in_group("wall"):
		queue_free()
