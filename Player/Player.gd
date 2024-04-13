extends CharacterBody2D


@export var speed : float = 10.0
@export var maxSpeed : float = 60
@export var maxHealth : float = 30
var curHealth : float

@export var damage : float = 8

@onready var sprite : Sprite2D = $Sprite2D
@onready var hitBox = $UiNodes/hitBox
@onready var hitColor_timer = $UiNodes/hitBox/hitTimer

var canBuy : bool = false



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
	
	
func updateHealth(val : float):
	curHealth += val

func takeDamage(damage):
	hitBox.visible = true
	hitColor_timer.start()
	updateHealth(damage)


func _on_hit_timer_timeout():
	hitBox.visible = false
