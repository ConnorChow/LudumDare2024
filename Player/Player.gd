extends CharacterBody2D


var input_direction :Vector2

@export var speed : float = 10.0
var modSpeed : float = 10.0
@export var maxSpeed : float = 60
var modMaxSpeed : float = 60
@export var maxHealth : float = 30
var curHealth : float
@export var damage : float = 8

@onready var sprite : Sprite2D = $mainSprite
@onready var hitBox = $UiNodes/hitBox
@onready var hitColor_timer = $UiNodes/hitBox/hitTimer
@onready var money = $UiNodes/Money
@onready var health_bar = $UiNodes/healthBar

@onready var i_frames = $iFrames
var canHurt : bool = true

#upgrades
var canBuy : bool = false
@onready var buy_menu = $UiNodes/buyMenu
#purchase new units
@onready var buy_minion = $UiNodes/buyMenu/buyMinion
@onready var cur_cost_label = $UiNodes/buyMenu/curCostLabel
#buy unit upgrades

@onready var cur_upgrade_label = $UiNodes/buyMenu/curUpgradeLabel
@onready var buy_upgrade = $UiNodes/buyMenu/buyUpgrade
#buy player upgrades
@onready var cur_player_label = $UiNodes/buyMenu/curPlayerLabel
@onready var buy_player = $UiNodes/buyMenu/buyPlayer

#minionwheel
var minionWheel : bool = false
@onready var direct_wheel = $UiNodes/directWheel


#placeable objects
var wheelOpen : bool = false
@onready var place_wheel = $UiNodes/placeWheel

@onready var light_label = $UiNodes/placeWheel/Light/LightLabel
@onready var light_button = $UiNodes/placeWheel/Light/LightButton

@onready var battle_label = $UiNodes/placeWheel/BattleTower/BattleLabel
@onready var battle_tower_button = $UiNodes/placeWheel/BattleTower/BattleTowerButton

var canPlace : bool = true
@onready var placeTimer = $placeTimer
@onready var placeLight = preload("res://Objects/lightPlace.tscn")
@onready var battleStation = preload("res://Objects/battleStation.tscn")


# a short timer to prevent weirdness associated with spam picking up and droppuing
#items
@onready var grab_timer = $grabTimer
@onready var grab_box = $grabBox
@onready var hold_point = $holdPoint
var heldObject : Object = null
var canGrab : bool = true

#duration that the recall takes
@onready var recall_timer = $recallTimer
#the animation that the sprite takes on during the recall. will need to be changed
@onready var recall_sprite = $recallSprite
var recalling : bool = false

#walk timer
@onready var walk_1 = $walkingSfx/walk1

#upgrades
@onready var light_bubble = $lightBubble

var playerUpgrades :int = 0
var antUpgrades : int = 0

#home position gets set when the player laods in the game and touches the base.
#the base calls the players function and tells it it's position. 
#its bad, but it works, and the base can be moved during runtime
var homePosition : Vector2

func _ready():
	curHealth = maxHealth
	hitBox.visible = false
	#this sets the currency to 0 on load, to prevent save abuse associated with 
	#the global script
	#may need a function to reset all upgrades to 0
	CurrencyCount.currency = 0
	modMaxSpeed = maxSpeed
	modSpeed = speed
	health_bar.max_value = maxHealth
	health_bar.value = curHealth
	buy_menu.visible = false


func _physics_process(delta):
	
	get_input()
	velocity.y = clamp(velocity.y, -modMaxSpeed, modMaxSpeed)
	velocity.x = clamp(velocity.x, -modMaxSpeed, modMaxSpeed)
	velocity = lerp(velocity, Vector2(0,0), delta*5)
	velocity.normalized()
	
	#cancel recall
	if recalling:
		if !input_direction == Vector2(0,0) :
			stopRecall()
	
	#walking sound effect
	if !input_direction == Vector2(0,0) :
		if !walk_1.is_playing() :
			walk_1.play()
	else:
		walk_1.stop()





	if velocity.x > 0:
		if !sprite.flip_h == false:
			sprite.flip_h = false
				
	elif velocity.x < 0:
		if !sprite.flip_h == true:
			sprite.flip_h = true
			
	move_and_slide()

func get_input():
	input_direction = Input.get_vector("left", "right", "up", "down")
	velocity += input_direction * modSpeed
	if canBuy:
		if Input.is_action_just_pressed("1"):
			if CurrencyCount.curCost <= CurrencyCount.currency:
				buyMinion()
		if Input.is_action_just_pressed("2"):
			if CurrencyCount.unitUpgradeCost <= CurrencyCount.currency:
				buyUpgrade()
		if Input.is_action_just_pressed("3"):
			if CurrencyCount.playerUpgradeCost <= CurrencyCount.currency:
				buyPlayer()
	elif !canBuy:
		if wheelOpen:
			if Input.is_action_just_pressed("1"):
				placeObject("Light")
			if Input.is_action_just_pressed("2"):
				placeObject("Battle")
			if Input.is_action_just_pressed("3"):
				pass
			if Input.is_action_just_pressed("4"):
				pass
			if Input.is_action_just_pressed("5"):
				pass
		else:
			if Input.is_action_just_pressed("1"):
				antFollow()
			if Input.is_action_just_pressed("2"):
				antFight()
			if Input.is_action_just_pressed("3"):
				antForage()
			if Input.is_action_just_pressed("4"):
				antMine()
			if Input.is_action_just_pressed("5"):
				pass

		
	if Input.is_action_just_pressed("recall"):
		if heldObject != null:
				heldObject.reparent(get_parent())
				dropItem()

	if Input.is_action_just_pressed("wheelToggle"):
		place_wheel.visible = !place_wheel.visible
		wheelOpen = !wheelOpen
		direct_wheel.visible = false
		minionWheel = false
		
	if Input.is_action_just_pressed("minionWheel"):
		direct_wheel.visible = !direct_wheel.visible
		minionWheel= !minionWheel
		place_wheel.visible = false
		wheelOpen = false
	
	if Input.is_action_just_pressed("grab"):
		if canGrab:
			if heldObject != null:
				heldObject.reparent(get_parent())
				dropItem()
			else:
				var i = grab_box.get_overlapping_areas()
				for g in i:
					if g.is_in_group("Grab"):
						g.reparent(self)
						heldObject = g
						g.global_position = hold_point.global_position
						modSpeed = speed * .6
						modMaxSpeed = maxSpeed * .6
						break
	

		
var following_ants : Array

#start recalling
#press b, change sprite / animation / whatever
#after x seconds, recall and change sprite back
#can be cancelled early by moving, change sprite back

func recall(homePos :Vector2):
	if !recalling:
		homePosition = homePos
		sprite.visible=false
		recall_sprite.visible = true
		recalling = true
		recall_timer.start()

func stopRecall():
	recalling = false
	sprite.visible=true
	recall_sprite.visible = false
	recall_timer.stop()

func _on_recall_timer_timeout():
	global_position = homePosition
	takeDamage(6)
	stopRecall()


func updateCur():
	money.set_text("$" +str(CurrencyCount.currency)) 

	if CurrencyCount.curCost > CurrencyCount.currency:
		buy_minion.set_disabled(true)
	elif CurrencyCount.curCost <= CurrencyCount.currency:
		buy_minion.set_disabled(false)
		
	if CurrencyCount.unitUpgradeCost > CurrencyCount.currency:
		buy_upgrade.set_disabled(true)
	elif CurrencyCount.unitUpgradeCost <= CurrencyCount.currency:
		buy_upgrade.set_disabled(false)
	
	if CurrencyCount.playerUpgradeCost > CurrencyCount.currency:
		buy_player.set_disabled(true)
	elif CurrencyCount.playerUpgradeCost <= CurrencyCount.currency:
		buy_player.set_disabled(false)
	

func dropItem():
	modMaxSpeed = maxSpeed
	modSpeed = speed
	heldObject = null
	canGrab = false
	grab_timer.start()

func updateHealth(val : float):
	curHealth += val
	if curHealth > maxHealth:
		curHealth = maxHealth
	health_bar.value = curHealth

func takeDamage(dmg):
	if canHurt:
		hitBox.visible = true
		hitColor_timer.start()
		updateHealth(-dmg)
		i_frames.start()

func _on_i_frames_timeout():
	canHurt = true

func _on_hit_timer_timeout():
	hitBox.visible = false


func _on_grab_timer_timeout():
	canGrab = true


func buyEnable():
	canBuy = true
	buy_menu.visible = true
	wheelOpen = false
	place_wheel.visible = false
	direct_wheel.visible = false
	minionWheel = false

func buyDisable():
	canBuy = false
	buy_menu.visible = false

@export var minion_ant : PackedScene
func _on_buy_minion_pressed():
	buyMinion()
var call_spawn_minion : Callable
func buyMinion():
	#spawn unit
	CurrencyCount.currency -= CurrencyCount.curCost
	call_spawn_minion.call()
	# this needs a better equation
	#when a unit dies, reduce the curcost
	CurrencyCount.curCost = floor(CurrencyCount.curCost * 1.5)
	cur_cost_label.set_text("$" + str(CurrencyCount.curCost))  
	updateCur()

func _on_buy_upgrade_pressed():
	buyUpgrade()
func buyUpgrade():
	antUpgrades +=1
	antUpgrade()
	#upgrade unit
	CurrencyCount.currency -= CurrencyCount.unitUpgradeCost
	#These should probably be fixed costs, and increase based on specific tiers
	#maybe even scale on the quantity of units that the player has
	CurrencyCount.unitUpgradeCost = floor(CurrencyCount.unitUpgradeCost * 1.5)
	cur_upgrade_label.set_text("$" + str(CurrencyCount.unitUpgradeCost))  
	updateCur()

func _on_buy_player_pressed():
	buyPlayer()
func buyPlayer():
	playerUpgrade()
	playerUpgrades +=1
	CurrencyCount.currency -= CurrencyCount.playerUpgradeCost
	#Same deal, these should be flat costs, that have set values based on the 
	#specific upgrade. I don't think we need to scale these based on the players
	#current units? Testing needed though obv
	CurrencyCount.playerUpgradeCost = floor(CurrencyCount.playerUpgradeCost * 1.5)
	cur_player_label.set_text("$" + str(CurrencyCount.playerUpgradeCost))  
	updateCur()

#you might want to improve this to use the tilemap, so objects behave properly
func placeObject(type):
	match type:
		"Light":
			if CurrencyCount.currency > 0:
				if canPlace:
					var l = placeLight.instantiate()
					l.global_position = global_position
					get_parent().add_child(l)
					CurrencyCount.currency -=1
					updateCur()
					placeTimer.start()
					canPlace = false
		"Battle":
			if CurrencyCount.currency > 4:
				if canPlace:
					var b = battleStation.instantiate()
					b.global_position = global_position
					get_parent().add_child(b)
					CurrencyCount.currency -=5
					updateCur()
					placeTimer.start()
					canPlace = false

func _on_place_timer_timeout():
	canPlace = true

func _on_light_button_pressed():
	placeObject("Light")

func _on_battle_tower_button_pressed():
	placeObject("Battle")

func roleCall():
	for ant in get_tree().get_nodes_in_group("ant"):
		(ant as Node2D).call_deferred("_receive_command_follow")
		following_ants.append(ant as Node2D)

	
func antForage():
	for ant in following_ants:
		ant.call_deferred("_receive_command_forage")
		following_ants.clear()

	
func antFollow():
	var i = grab_box.get_overlapping_areas()
	for g in i:
		var potential_ant : Node2D = g.get_parent() as Node2D
		if potential_ant.is_in_group("ant"):
			potential_ant.call_deferred("_receive_command_follow")
			following_ants.append(potential_ant)

func antFight():
	
	pass
func antMine():
	
	pass

func _on_fight_button_pressed():
	antFight()
func _on_follow_button_pressed():
	antFollow()
func _on_mine_button_pressed():
	antMine()
func _on_gather_button_pressed():
	antForage()
func _on_role_call_pressed():
	roleCall()

func antUpgrade():
	match antUpgrades:
		0:
			pass
		1:
			#ant speed +
			pass
		2:
			pass
			#ant health +
		3:
			#ant damage +
			pass
		4:
			#ant speed +
			pass
		5:
			#ant health +
			pass
		6:
			#ant damage +
			pass
		_:
			#all stats up
			pass

func playerUpgrade():
	match playerUpgrades:
		0:
			pass
		1:
			speed += 2
			maxSpeed +=2
		2:
			light_bubble.set_texture_scale(1.1)
		3:
			speed += 3
			maxSpeed +=3
		4:
			light_bubble.set_texture_scale(1.4)
		_:
			speed += 1
			maxSpeed +=1

