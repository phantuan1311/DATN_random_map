extends CharacterBody2D

var speed = 80
var max_health: int = 3
var health: int = max_health
var dead: bool = false
var hearts_list : Array[TextureRect]

var is_shooting = false
var is_reloading = false
var is_invincible = false

const MAG_SIZE = 10
var ammo: int = MAG_SIZE

@onready var arrow = preload("res://scenes/arrow.tscn")
@onready var anim = $AnimatedSprite2D
@onready var marker = $Marker2D
@onready var game_over_ui = $CanvasLayer/game_over
@onready var label_coin = $health_bar/HBoxContainer2/Sprite2D/Label
func _ready() -> void:
	game_over_ui.visible = false
	var hearts_parent = $health_bar/HBoxContainer
	for child in hearts_parent.get_children():
		hearts_list.append(child)
		

func _physics_process(delta):
	label_coin.text = str(Global.coins)
	if dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# di chuyển 4 chiều
	var input_vec = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	).normalized()

	velocity = input_vec * speed
	move_and_slide()

	# xoay marker theo chuột (chỉ để bắn)
	aim_to_mouse()

	# chọn animation
	if not is_shooting and not is_reloading:
		if input_vec == Vector2.ZERO:
			anim.play("idle")
		else:
			anim.play("run")

	# flip sprite: khi bắn thì theo chuột, còn lại thì theo hướng di chuyển
	if is_shooting:
		var mouse_pos = get_global_mouse_position()
		if mouse_pos.x < global_position.x:
			anim.flip_h = true
		else:
			anim.flip_h = false
	else:
		if input_vec.x < 0:
			anim.flip_h = true
		elif input_vec.x > 0:
			anim.flip_h = false

	# bắn
	if Input.is_action_just_pressed("shoot") and not is_shooting and not is_reloading:
		if ammo > 0:
			shoot()
		else:
			start_reload()

	# reload thủ công
	if Input.is_action_just_pressed("reload") and not is_reloading:
		start_reload()


# ---------------- Aim theo chuột ----------------
func aim_to_mouse():
	var mouse_pos = get_global_mouse_position()
	var dir = (mouse_pos - global_position).normalized()
	marker.rotation = dir.angle()


# ---------------- Shooting ----------------
func shoot():
	is_shooting = true
	ammo -= 1
	anim.play("shoot")

	var arrow_instance = arrow.instantiate()
	arrow_instance.global_position = marker.global_position
	arrow_instance.rotation = marker.global_rotation
	get_parent().add_child(arrow_instance)

	await get_tree().create_timer(0.3).timeout
	is_shooting = false

	if ammo <= 0:
		start_reload()


# ---------------- Reload ----------------
func start_reload():
	is_reloading = true
	anim.play("reload")
	await anim.animation_finished
	ammo = MAG_SIZE
	is_reloading = false


# ---------------- Damage logic ----------------
func take_damage(amount: int = 1):
	if dead or is_invincible:
		return

	health -= amount
	update_heart_display()
	if health > 0:
		start_invincible()
	else:
		death()

func update_heart_display():
	for i in range(hearts_list.size()):
		hearts_list[i].visible = i < health

func start_invincible():
	is_invincible = true
	var blink_time = 1.0
	var blink_interval = 0.1
	var elapsed = 0.0

	while elapsed < blink_time:
		anim.visible = false
		await get_tree().create_timer(blink_interval).timeout
		anim.visible = true
		await get_tree().create_timer(blink_interval).timeout
		elapsed += blink_interval * 2

	is_invincible = false


func death():
	dead = true
	velocity = Vector2.ZERO
	anim.play("death")
	$CollisionShape2D.queue_free()
	game_over_ui.visible = true

	# Xoá save khi thua
	Global.delete_save()
