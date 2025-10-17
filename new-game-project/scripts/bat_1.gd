extends CharacterBody2D

@onready var ray_cast = $RayCast2D
@onready var timer = $Timer
@onready var sprite = $AnimatedSprite2D
@export var ammo: PackedScene

@export var stun_duration: float = 0.4
@export var speed: float = 30.0
@export var shoot_range: float = 150.0
@export var knockback_force: float = 120.0   # lực đẩy ban đầu
@export var knockback_friction: float = 8.0  # tốc độ giảm lực knockback

var chasing: bool = false
@export var chase_duration: float = 3.0
@export var chase_distance: float = 80.0


var health: int = 150
var dead: bool = false
var stunned: bool = false
var stun_timer: float = 0.0
var direction: int = 1
var knockback_velocity: Vector2 = Vector2.ZERO

@onready var hp_potion = preload("res://scenes/hp_potion.tscn")
var start_pos: Vector2
var patrol_points: Array[Vector2] = []
var patrol_index: int = 0
var waiting: bool = false


var player: Node = null
var start_x: float
@export var patrol_range: float = 30.0


func _ready():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	else:
		push_warning("⚠ Enemy could not find any node in group 'player'")

	dead = false
	start_x = position.x
	start_pos = global_position

	# Tạo 4 điểm hình vuông (40px)
	var size = 40
	patrol_points = [
		start_pos + Vector2(size, 0),   # phải
		start_pos + Vector2(size, size), # xuống
		start_pos + Vector2(0, size),   # trái
		start_pos                       # lên (về gốc)
	]



func _physics_process(delta):
	if dead:
		return
	
	# Knockback (ưu tiên nhất)
	if knockback_velocity.length() > 0.1:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction)
		move_and_slide()
		return
	
	# Choáng
	if stunned:
		stun_timer -= delta
		if stun_timer <= 0.0:
			stunned = false
		return
	
	# Nếu đang truy đuổi
	if chasing and player:
		_chase_player(delta)
		return
	
	# Bình thường: tuần tra
	_patrol(delta)
	
	# Ngắm và bắn
	if player:
		_aim()
		_check_player_collision()

func _chase_player(delta):
	if not player:
		return

	var dist = global_position.distance_to(player.global_position)
	var dir = (player.global_position - global_position).normalized()

	# Nếu còn xa hơn khoảng cách mong muốn → tiến lại gần
	if dist > chase_distance:
		velocity = dir * speed * 1.5  # bay nhanh hơn bình thường một chút
	else:
		velocity = Vector2.ZERO  # đủ gần thì dừng lại, giữ khoảng cách
	
	move_and_slide()

	# Mặt theo hướng người chơi
	if sprite:
		sprite.flip_h = player.global_position.x < global_position.x


func _patrol(delta):
	if waiting:
		velocity = Vector2.ZERO
		return

	var target = patrol_points[patrol_index]
	var dir = (target - global_position).normalized()
	velocity = dir * speed
	move_and_slide()

	# Đến gần điểm patrol thì dừng 1s rồi đổi hướng
	if global_position.distance_to(target) < 2:
		waiting = true
		await get_tree().create_timer(1.0).timeout
		waiting = false
		patrol_index = (patrol_index + 1) % patrol_points.size()

	# Cập nhật hướng sprite
	if sprite and not stunned:
		if abs(dir.x) > abs(dir.y):
			sprite.flip_h = dir.x < 0



func _aim():
	var target = to_local(player.position + Vector2(0, 5))
	ray_cast.target_position = target
	
	if sprite and not stunned:
		sprite.flip_h = player.global_position.x < global_position.x


func _check_player_collision():
	if not player:
		return

	var dist = global_position.distance_to(player.global_position)
	if dist > shoot_range:
		if not timer.is_stopped():
			timer.stop()
		return

	var collider = ray_cast.get_collider()
	if collider == player and timer.is_stopped():
		timer.start()
	elif collider != player and not timer.is_stopped():
		timer.stop()


func _on_timer_timeout():
	if not stunned:
		shoot()


func shoot():
	if not player:
		return

	if global_position.distance_to(player.global_position) > shoot_range:
		return

	var bullet = ammo.instantiate()
	bullet.position = position
	bullet.direction = (ray_cast.target_position).normalized()
	get_tree().current_scene.add_child(bullet)


func _on_hitbox_area_entered(area):
	if area.is_in_group("arrow"):
		take_damage(area.damage)


func take_damage(damage: int):
	if dead:
		return
	
	health -= damage
	_flash_hit()
	
	stunned = true
	stun_timer = stun_duration
	
	# Knockback vật lý
	if player:
		var knock_dir = sign(global_position.x - player.global_position.x)
		knockback_velocity = Vector2(knock_dir * knockback_force, -knockback_force / 3)
	
	# Sau khi bị đánh, bắt đầu truy đuổi trong vài giây
	if not chasing:
		chasing = true
		_start_chase_timer()
	
	if health <= 0:
		death()

func _start_chase_timer():
	await get_tree().create_timer(chase_duration).timeout
	chasing = false


func _flash_hit():
	if sprite:
		sprite.modulate = Color(2, 2, 2)
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color(1, 1, 1)


func death():
	if dead:
		return
	dead = true

	# Ngắt hoạt động AI
	timer.stop()
	stunned = true
	set_collision_layer(0)
	set_collision_mask(0)

	# Rơi vật lý tự nhiên
	velocity = Vector2(0, 10)  # tốc độ rơi ban đầu
	var gravity = 20.0
	var fall_time = 0.0
	var max_fall_time = 0.5

	while fall_time < max_fall_time:
		velocity.y += gravity * get_physics_process_delta_time()
		position += velocity * get_physics_process_delta_time()
		fall_time += get_physics_process_delta_time()
		await get_tree().process_frame

	# Tan biến dần
	if sprite:
		for i in range(10):
			sprite.modulate.a = lerp(1.0, 0.0, i / 10.0)
			await get_tree().create_timer(0.05).timeout

	# 🎲 Xác suất rơi potion 10%
	if randi() % 100 < 10:
		var potion_instance = hp_potion.instantiate()
		potion_instance.global_position = global_position
		get_tree().current_scene.add_child(potion_instance)

	queue_free()
