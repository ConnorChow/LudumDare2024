extends CharacterBody2D


const SPEED = 10.0
const MaxSpeed = 60
var collects : int = 0
var hasSeen : bool = false
var canEnd : bool = false
var score : int = 0

@onready var sprite = $Sprite2D
# Get the gravity from the pr$Sprite2Doject settings to be synced with RigidBody nodes.



func _physics_process(delta):
	
	get_input()
	velocity.y = clamp(velocity.y, -MaxSpeed, MaxSpeed)
	velocity.x = clamp(velocity.x, -MaxSpeed, MaxSpeed)
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
	velocity += input_direction * SPEED
