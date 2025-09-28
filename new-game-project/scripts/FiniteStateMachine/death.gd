extends State

func enter():
	super.enter()
	$"../../CollisionShape2D".queue_free()
	$"../../Pivot/Area2D/CollisionShape2D".queue_free()
	animation_player.play("death")
	await animation_player.animation_finished
	animation_player.play("boss_slained")
	
