extends CharacterBody2D

var speed = 80
var health: int = 100
var dead: bool = false

var player_state
var bow_equip = true
var bow_cooldown = true
var arrow = preload("res://scenes/arrow.tscn")

var mouse_loc_from_player = null
var is_shooting = false

var is_hit = false
var is_invincible = false

func _physics_process(delta):
	if dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	mouse_loc_from_player = get_global_mouse_position() - self.position
	var direction = Input.get_vector("left","right","up","down")

	# nếu không bắn thì cho di chuyển
	if not is_shooting:
		if direction == Vector2.ZERO:
			player_state = "idle"
		else:
			player_state = "walking"

		velocity = direction * speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		move_and_slide()

	# xoay marker theo chuột
	var mouse_pos = get_global_mouse_position()
	$Marker2D.look_at(mouse_pos)

	# bắn
	if Input.is_action_just_pressed("left_mouse") and bow_equip and bow_cooldown:
		is_shooting = true
		bow_cooldown = false

		var arrow_instance = arrow.instantiate()
		arrow_instance.rotation = $Marker2D.rotation
		arrow_instance.global_position = $Marker2D.global_position
		add_child(arrow_instance)

		await get_tree().create_timer(0.4).timeout
		bow_cooldown = true
		is_shooting = false

	play_anim(direction)

# ----------------- Damage logic -----------------
func take_damage(amount: int):
	if dead or is_invincible:
		return

	health -= amount
	if health > 0:
		start_hit_state()
	else:
		death()
func start_hit_state():
	is_hit = true
	is_invincible = true
	$AnimatedSprite2D.play("hit")

	# nhấp nháy trong 1s
	var blink_time = 1.0
	var blink_interval = 0.1
	var elapsed = 0.0

	while elapsed < blink_time:
		$AnimatedSprite2D.visible = false
		await get_tree().create_timer(blink_interval).timeout
		$AnimatedSprite2D.visible = true
		await get_tree().create_timer(blink_interval).timeout
		elapsed += blink_interval * 2

	is_hit = false
	is_invincible = false


func death():
	dead = true
	velocity = Vector2.ZERO
	$AnimatedSprite2D.play("death")


func play_anim(dir):
	if not is_shooting: # đi lại bình thường
		if player_state == "idle":
			$AnimatedSprite2D.play("idle")
		if player_state == "walking":
			if dir.y == -1:
				$AnimatedSprite2D.play("n-walk")
			if dir.x == 1:
				$AnimatedSprite2D.play("e-walk")
			if dir.y == 1:
				$AnimatedSprite2D.play("s-walk")
			if dir.x == -1:
				$AnimatedSprite2D.play("w-walk")
				
			if dir.x > 0.5 and dir.y < -0.5:
				$AnimatedSprite2D.play("ne-walk")
			if dir.x > 0.5 and dir.y > 0.5:
				$AnimatedSprite2D.play("se-walk")
			if dir.x < -0.5 and dir.y > 0.5:
				$AnimatedSprite2D.play("sw-walk")
			if dir.x < -0.5 and dir.y < -0.5:
				$AnimatedSprite2D.play("nw-walk")

	else: # đang bắn → chơi animation attack
		if mouse_loc_from_player.x >= -25 and mouse_loc_from_player.x <= 25 and mouse_loc_from_player.y < 0:
			$AnimatedSprite2D.play("n-attack")
		if mouse_loc_from_player.y >= -25 and mouse_loc_from_player.y <= 25 and mouse_loc_from_player.x > 0:
			$AnimatedSprite2D.play("e-attack")
		if mouse_loc_from_player.x >= -25 and mouse_loc_from_player.x <= 25 and mouse_loc_from_player.y > 0:
			$AnimatedSprite2D.play("s-attack")
		if mouse_loc_from_player.y >= -25 and mouse_loc_from_player.y <= 25 and mouse_loc_from_player.x < 0:
			$AnimatedSprite2D.play("w-attack")
			
		if mouse_loc_from_player.x >= 25 and mouse_loc_from_player.y <= -25:
			$AnimatedSprite2D.play("ne-attack")
		if mouse_loc_from_player.x >= 0.5 and mouse_loc_from_player.y >= 25:
			$AnimatedSprite2D.play("se-attack")
		if mouse_loc_from_player.x <= -0.5 and mouse_loc_from_player.y >= 25:
			$AnimatedSprite2D.play("sw-attack")
		if mouse_loc_from_player.x <= -25 and mouse_loc_from_player.y <= -25:
			$AnimatedSprite2D.play("nw-attack")
