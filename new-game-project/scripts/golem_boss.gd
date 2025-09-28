extends CharacterBody2D

@onready var player = get_parent().find_child("player")
@onready var sprite = $Sprite2D
@onready var progress_bar = $UI/ProgressBar
@onready var idle = $FiniteStateMachine/Idle
var direction : Vector2
var DEF = 0

var health = 100:
	set(value):
		health = value
		progress_bar.value = value
		if value < 100:
			idle.player_entered = true
		if value <= 0:
			progress_bar.visible = false
			find_child("FiniteStateMachine").change_state("Death")
		elif value <= progress_bar.max_value / 2 and DEF == 0:
			DEF = 1
			find_child("FiniteStateMachine").change_state("ArmorBuff")
		elif value <= progress_bar.max_value / 4 and DEF == 3:
			DEF = 2
			find_child("FiniteStateMachine").change_state("ArmorBuff")

func _ready():
	set_physics_process(false)
func _process(_delta):
	direction = player.position - position
	
	if direction.x < 0:
		sprite.flip_h = true
	else:
		sprite.flip_h = false
		
func _physics_process(delta):
	velocity = direction.normalized() * 40
	move_and_collide(velocity * delta)

func take_damage():
		health -= 4 - DEF
		flash_white()

func flash_white():
	var original_color = sprite.modulate
	sprite.modulate = Color(2, 2, 2, 1) # sáng gấp đôi
	await get_tree().create_timer(0.1).timeout
	if sprite:
		sprite.modulate = original_color



func _on_area_2d_body_entered(body):
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(1)
