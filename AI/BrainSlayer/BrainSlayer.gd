extends Sprite2D

@export var tile_map : TileMap # global tilemap, use to keep track of which tile to move on

var spawn_location : Vector2 # Origin of the Brain to spawn back at

var next_tile_loc : Vector2

var growth_percent : float = 0
@export var growth_rate : float = 0.5 

var health : float = 100


# Called when the node enters the scene tree for the first time.
func _ready():
	spawn_location = global_position
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _physics_process(delta):
	if _is_grown():
		pass
	else:
		growth_percent += delta * growth_rate
		scale = Vector2.ONE * growth_percent

func _is_grown()->bool:
	return growth_percent >= 1.0

func _respawn():
	global_position = spawn_location
	growth_percent = 0
