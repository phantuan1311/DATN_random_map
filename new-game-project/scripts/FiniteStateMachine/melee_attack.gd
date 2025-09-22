extends State

func enter():
	super.enter()
	animation_player.play("melee_attack")
	
func transition():
	if owner.direction.length() > 30:
		get_parent().change_state("Follow")

func _apply_damage_to_hero():
	var hero = get_tree().get_first_node_in_group("player")
	if hero and hero.has_method("take_damage"):
		hero.take_damage(1)
