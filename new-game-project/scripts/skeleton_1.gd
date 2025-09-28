extends CharacterBody2D

@export var stun_duration: float = 0.2
@export var speed: float = 30.0
@export var tile_size: int = 16
@export var patrol_tiles: int = 3
@export var rest_time: float = 3.0

@onready var coin_scene = preload("res://scenes/coin.tscn")

var health: int = 100
var damage: int = 1
var attack_cooldown: float = 1.0
var attack_timer: float = 0.0
var dead: bool = false
var player_in_area: bool = false
var player_in_attack: bool = false
var player: Node2D = null

var stunned: bool = false
var stun_timer: float = 0.0

# --- Tuần tra ---
var is_patrolling: bool = false
var target_pos: Vector2
var resting: bool = false
var last_pos: Vector2


func _ready():
	dead = false
	$detect_area/CollisionShape2D.disabled = false
	$attack_area/CollisionShape2D.disabled = false
	start_patrol()


func _physics_process(delta):
	if dead:
		$detect_area/CollisionShape2D.disabled = true
		$attack_area/CollisionShape2D.disabled = true
		$AnimatedSprite2D.play("death")
		return

	if attack_timer > 0:
		attack_timer -= delta

	# --- Stun logic ---
	if stunned:
		stun_timer -= delta
		if stun_timer <= 0.0:
			stunned = false
		else:
			# giữ nguyên anim hit trong suốt stun
			if $AnimatedSprite2D.animation != "hit":
				$AnimatedSprite2D.play("hit")
		velocity = Vector2.ZERO
		move_and_slide()
		return


	# --- Logic khi gặp player ---
	if player_in_attack and player:
		velocity = Vector2.ZERO
		$AnimatedSprite2D.play("attack") 

		if attack_timer <= 0:
			if player.has_method("take_damage"):
				player.take_damage(1)
			attack_timer = attack_cooldown
		move_and_slide()
		return

	elif player_in_area and player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		$AnimatedSprite2D.play("move")

		# flip khi chase player
		if direction.x < 0:
			$AnimatedSprite2D.flip_h = true
		elif direction.x > 0:
			$AnimatedSprite2D.flip_h = false

		move_and_slide()
		return

	# --- Tuần tra nếu không có player ---
	if is_patrolling:
		var direction = (target_pos - global_position).normalized()
		velocity = direction * speed
		$AnimatedSprite2D.play("move")

		# flip theo hướng đi
		if direction.x < 0:
			$AnimatedSprite2D.flip_h = true
		elif direction.x > 0:
			$AnimatedSprite2D.flip_h = false

		move_and_slide()

		# check đến đích
		if global_position.distance_to(target_pos) < 2:
			velocity = Vector2.ZERO
			is_patrolling = false
			start_rest()

		# check kẹt (nếu di chuyển không đổi vị trí)
		elif global_position.distance_to(last_pos) < 0.5:
			velocity = Vector2.ZERO
			is_patrolling = false
			start_rest()

		last_pos = global_position
	else:
		if not resting:
			start_patrol()
		else:
			velocity = Vector2.ZERO
			$AnimatedSprite2D.play("idle")
			move_and_slide()


# --- Patrol logic ---
func start_patrol():
	if dead: return
	var dirs = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	var dir = dirs[randi() % dirs.size()]
	var distance = patrol_tiles * tile_size
	target_pos = global_position + dir * distance
	is_patrolling = true
	resting = false
	last_pos = global_position

func start_rest():
	resting = true
	$AnimatedSprite2D.play("idle")
	await get_tree().create_timer(rest_time).timeout
	resting = false
	start_patrol()


# --- Detect area ---
func _on_detect_area_body_entered(body):
	if body.is_in_group("player"):
		player_in_area = true
		player = body

func _on_detect_area_body_exited(body):
	if body == player:
		player_in_area = false
		if not player_in_attack:
			player = null


# --- Attack area ---
func _on_attack_area_body_entered(body):
	if body.is_in_group("player"):
		player_in_attack = true
		player = body

func _on_attack_area_body_exited(body):
	if body == player:
		player_in_attack = false
		if not player_in_area:
			player = null


# --- Nhận damage từ arrow ---
func _on_hitbox_area_entered(area):
	if area.is_in_group("arrow"):
		take_damage(area.damage)


func take_damage(damage: int):
	if dead:
		return
	health -= damage
	stun(stun_duration) 

	if health <= 0:
		death()


func stun(time: float):
	stunned = true
	stun_timer = time
	velocity = Vector2.ZERO
	$AnimatedSprite2D.play("hit")

func death():
	dead = true
	$AnimatedSprite2D.play("death")
	$CollisionShape2D.set_deferred("disabled", true)   
	$detect_area/CollisionShape2D.set_deferred("disabled", true)
	$attack_area/CollisionShape2D.set_deferred("disabled", true)

	var rng = randi_range(0, 4)
	for i in rng:
		var coin = coin_scene.instantiate()
		var offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
		coin.global_position = global_position + offset
		get_parent().add_child(coin)
	await get_tree().create_timer(1).timeout
	queue_free()
