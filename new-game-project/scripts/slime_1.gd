extends CharacterBody2D
@export var stun_duration: float = 0.2
@export var speed: float = 30.0

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

func _ready():
	dead = false
	$detect_area/CollisionShape2D.disabled = false
	$attack_area/CollisionShape2D.disabled = false

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
		velocity = Vector2.ZERO
		$AnimatedSprite2D.play("idle")
		move_and_slide()
		return

	# --- Logic di chuyển / attack ---
	if player_in_attack and player:
		velocity = Vector2.ZERO
		$AnimatedSprite2D.play("attack") 

		if attack_timer <= 0:
			if player.has_method("take_damage"):
				player.take_damage(damage)
			attack_timer = attack_cooldown

	elif player_in_area and player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		$AnimatedSprite2D.play("move")
	else:
		velocity = Vector2.ZERO
		$AnimatedSprite2D.play("idle")

	move_and_slide()


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
		stun(stun_duration)



func take_damage(damage: int):
	if dead:
		return
	
	health -= damage
	$AnimatedSprite2D.play("hit")
	velocity = Vector2.ZERO
	
	# stun tạm thời
	set_physics_process(false)
	await get_tree().create_timer(stun_duration).timeout
	set_physics_process(true)

	if health <= 0:
		death()

func stun(time: float):
	$AnimatedSprite2D.play("hit")
	stunned = true
	stun_timer = time

func death():
	dead = true
	$AnimatedSprite2D.play("death")
	$CollisionShape2D.queue_free()
	# spawn coin ngẫu nhiên từ 0 đến 3
	var rng = randi_range(0, 3)
	for i in rng:
		var coin = coin_scene.instantiate()

		# offset ngẫu nhiên để tránh trùng vị trí
		var offset = Vector2(
			randf_range(-10, 10),
			randf_range(-10, 10)
		)
		coin.global_position = global_position + offset
		get_parent().add_child(coin)
	
	await get_tree().create_timer(1).timeout
	queue_free()
