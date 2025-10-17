extends Area2D


func _ready():
	$AnimatedSprite2D.play("default")
	
func _on_body_entered(body):
	if body.is_in_group("player"):
		body.health += 1
		body.update_heart_display()
		$AnimatedSprite2D.play("claim")
		await $AnimatedSprite2D.animation_finished
		queue_free()
