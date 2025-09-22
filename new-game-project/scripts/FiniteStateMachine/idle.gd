extends State


@onready var collision = $"../../detect_player/CollisionShape2D"
@onready var progress_bar = owner.find_child("ProgressBar")

var player_entered: bool = false:
	set(value):
		player_entered = value
		collision.set_deferred("disabled", value)
		progress_bar.set_deferred("visible", value)

		
func transition():
	if player_entered:
		get_parent().change_state("Follow")

func _on_detect_player_body_entered(body):
	player_entered = true
	
