extends Area2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var player = get_parent().find_child("player")

var accel: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO

func _ready():
	# Sau 2 giây tự huỷ
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _physics_process(delta):
	accel = (player.position - position).normalized() * 300
	velocity += accel * delta
	rotation = velocity.angle()
	velocity = velocity.limit_length(150)
	position += velocity * delta

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(1)
		queue_free()  
