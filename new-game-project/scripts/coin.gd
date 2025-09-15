extends Area2D

func _ready():
	$AnimatedSprite2D.play("default")

func _on_body_entered(body):
	if body.is_in_group("player"):
		$AnimatedSprite2D.play("claim")
		await $AnimatedSprite2D.animation_finished
		queue_free()
