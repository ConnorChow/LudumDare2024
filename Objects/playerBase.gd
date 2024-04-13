extends Area2D




func _on_body_entered(body):
	body.canBuy = true



func _on_body_exited(body):
	body.canBuy = false



func _on_currency_detector_body_entered(body):
	CurrencyCount.currency += body.worth


