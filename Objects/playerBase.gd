extends Area2D

var player 

@export var minion : PackedScene

var difficulty 
var currency

func _ready():
	difficulty = OptionsController.difficulty
	match difficulty:
		1:
			currency = 3
		2:
			currency = 2
		3:
			currency = 1

func _on_body_entered(body):
	body.buyEnable() 
	player = body
	player.call_spawn_minion = func():
		var entity : Node2D = minion.instantiate() as Node2D
		add_child(entity)
		entity.owner = get_tree().root
		entity.global_position = global_position
		player.following_ants.append(entity)



func _on_body_exited(body):
	body.buyDisable() 



func _input(_event):
	if Input.is_action_just_pressed("recall"):
		player.recall(global_position)


func _on_currency_detector_area_entered(area):
	if !area.is_in_group("Grab"): return
	CurrencyCount.currency += currency
	player.updateCur()
	player.dropItem()
	area.queue_free()
	
