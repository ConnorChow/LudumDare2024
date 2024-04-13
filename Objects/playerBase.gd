extends Area2D




func _on_body_entered(body):
	body.canBuy = true



func _on_body_exited(body):
	body.canBuy = false

