extends CharacterBody2D


@export var speed = 10.0
@export var maxSpeed = 60
@export var maxHealth = 30
var curHealth

@export var damage = 8

@onready var sprite = $Sprite2D
# Get the gravity from the pr$Sprite2Doject settings to be synced with RigidBody nodes.



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
