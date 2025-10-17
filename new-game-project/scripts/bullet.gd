extends Area2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var player = get_parent().find_child("player")

var accel: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var turn_speed := 6.0 # tốc độ xoay góc, càng thấp càng mượt

func _ready():
	# Sau 2 giây tự huỷ
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _physics_process(delta):
	if not player or not player.is_inside_tree():
		queue_free()
		return

	# Tính hướng tới player
	var desired_dir = (player.global_position - global_position).normalized()
	var desired_angle = desired_dir.angle()

	# ✅ Xoay mượt tới hướng mục tiêu
	rotation = lerp_angle(rotation, desired_angle, turn_speed * delta)

	# Cập nhật vận tốc
	accel = Vector2.RIGHT.rotated(rotation) * 300
	velocity += accel * delta
	velocity = velocity.limit_length(150)
	position += velocity * delta

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(1)
		queue_free()
