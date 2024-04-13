extends CharacterBody2D


@export var speed : float = 10.0
var modSpeed : float = 10.0
@export var maxSpeed : float = 60
var modMaxSpeed : float = 60
@export var maxHealth : float = 30
var curHealth : float

@export var damage : float = 8

@onready var sprite : Sprite2D = $mainSprite
@onready var recall_sprite = $recallSprite
@onready var hitBox = $UiNodes/hitBox
@onready var hitColor_timer = $UiNodes/hitBox/hitTimer
@onready var grab_box = $grabBox
@onready var hold_point = $holdPoint
@onready var money = $UiNodes/Money
@onready var grab_timer = $grabTimer
@onready var recall_timer = $recallTimer


var input_direction
var heldObject : Object = null

var canBuy : bool = false
var canGrab : bool = true
var recalling : bool = false
var homePosition : Vector2

func _ready():
	curHealth = maxHealth
	hitBox.visible = false
	CurrencyCount.currency = 0
	modMaxSpeed = maxSpeed
	modSpeed = speed


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
	pass # Replace with function body.
	
func updateCur():
	money.set_text(str(CurrencyCount.currency)) 
	heldObject = null
	modMaxSpeed = maxSpeed
	modSpeed = speed
	canGrab = false
	grab_timer.start()


func updateHealth(val : float):
	curHealth += val

func takeDamage(dmg):
	hitBox.visible = true
	hitColor_timer.start()
	updateHealth(dmg)


func _on_hit_timer_timeout():
	hitBox.visible = false


func _on_grab_timer_timeout():
	canGrab = true



