extends Area2D


func _physics_process(delta):

	# Kiểm tra cha hoặc ancestor có group "floor" thì xóa
	var node = get_parent()
	while node:
		if node.is_in_group("floor"):
			queue_free()
			return
		node = node.get_parent()
