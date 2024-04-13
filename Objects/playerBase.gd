extends Area2D

var player 


func _on_body_entered(body):
	body.buyEnable() 
	player = body



func _on_body_exited(body):
	body.buyDisable() 



func _input(_event):
	if Input.is_action_just_pressed("recall"):
		player.recall(global_position)


func _on_currency_detector_area_entered(area):
	CurrencyCount.currency += 1
	player.updateCur()
	area.queue_free()
	if CurrencyCount.curCost <= CurrencyCount.currency:
		player.buy_minion.set_disabled(false)
