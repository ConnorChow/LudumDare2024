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
	
	if Input.is_action_just_pressed("recall"):
		if heldObject != null:
				heldObject.reparent(get_parent())
				heldObject = null
				modMaxSpeed = maxSpeed
				modSpeed = speed
	
	if Input.is_action_just_pressed("grab"):
		if canGrab:
			canGrab = false
			grab_timer.start()
			if heldObject != null:
				heldObject.reparent(get_parent())
				heldObject = null
				modMaxSpeed = maxSpeed
				modSpeed = speed
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
	heldObject = null
	modMaxSpeed = maxSpeed
	modSpeed = speed
	canGrab = false
	grab_timer.start()
	
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
	


func updateHealth(val : float):
	curHealth += val
	if curHealth > maxHealth:
		curHealth = maxHealth
	health_bar.value = curHealth

func takeDamage(dmg):
	hitBox.visible = true
	hitColor_timer.start()
	updateHealth(-dmg)


func _on_hit_timer_timeout():
	hitBox.visible = false


func _on_grab_timer_timeout():
	canGrab = true
	

func buyEnable():
	canBuy = true
	buy_menu.visible = true


func buyDisable():
	canBuy = false
	buy_menu.visible = false


func _on_buy_minion_pressed():
	buyMinion()
	
func buyMinion():
	#spawn unit
	CurrencyCount.currency -= CurrencyCount.curCost
	# this needs a better equation
	#when a unit dies, reduce the curcost
	CurrencyCount.curCost = floor(CurrencyCount.curCost * 1.5)
	cur_cost_label.set_text("$" + str(CurrencyCount.curCost))  
	updateCur()



func _on_buy_upgrade_pressed():
	buyUpgrade()


func buyUpgrade():
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
	#upgrade player
	CurrencyCount.currency -= CurrencyCount.playerUpgradeCost
	#Same deal, these should be flat costs, that have set values based on the 
	#specific upgrade. I don't think we need to scale these based on the players
	#current units? Testing needed though obv
	CurrencyCount.playerUpgradeCost = floor(CurrencyCount.playerUpgradeCost * 1.5)
	cur_upgrade_label.set_text("$" + str(CurrencyCount.playerUpgradeCost))  
	updateCur()
