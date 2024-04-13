extends Area2D

var player 


func _on_body_entered(body):
	body.canBuy = true
	player = body



func _on_body_exited(body):
	body.canBuy = false






func _on_currency_detector_area_entered(area):
	CurrencyCount.currency += 1
	player.updateCur()
	area.queue_free()
