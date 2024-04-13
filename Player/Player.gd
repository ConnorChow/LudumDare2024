extends CharacterBody2D


@export var speed : float = 10.0
var modSpeed : float
@export var maxSpeed : float = 60
@export var maxHealth : float = 30
var curHealth : float

@export var damage : float = 8

@onready var sprite : Sprite2D = $Sprite2D
@onready var hitBox = $UiNodes/hitBox
@onready var hitColor_timer = $UiNodes/hitBox/hitTimer
@onready var grab_box = $grabBox
@onready var hold_point = $holdPoint
@onready var money = $UiNodes/Money


var heldObject : Object = null

var canBuy : bool = false

signal makeMoneyGoUp

func _ready():
	curHealth = maxHealth
	hitBox.visible = false
	CurrencyCount.currency = 0


func _physics_process(delta):
	
	get_input()
	velocity.y = clamp(velocity.y, -maxSpeed, maxSpeed)
	velocity.x = clamp(velocity.x, -maxSpeed, maxSpeed)
	velocity = lerp(velocity, Vector2(0,0), delta*5)
	velocity.normalized()
	if velocity.x > 0:
		if !sprite.flip_h == false:
				sprite.flip_h = false
				
	elif velocity.x < 0:
		if !sprite.flip_h == true:
			sprite.flip_h = true
			
	move_and_slide()

func get_input():
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity += input_direction * speed
	
	if Input.is_action_just_pressed("grab"):
		
		if heldObject != null:
			heldObject.reparent(get_parent())
			heldObject = null
		else:
			var i = grab_box.get_overlapping_areas ( )
			for g in i:
				if g.is_in_group("Grab"):
					g.reparent(self)
					heldObject = g
					g.global_position = hold_point.global_position
					break
		

func updateCur():
	money.set_text(str(CurrencyCount.currency)) 


func updateHealth(val : float):
	curHealth += val

func takeDamage(dmg):
	hitBox.visible = true
	hitColor_timer.start()
	updateHealth(dmg)


func _on_hit_timer_timeout():
	hitBox.visible = false
