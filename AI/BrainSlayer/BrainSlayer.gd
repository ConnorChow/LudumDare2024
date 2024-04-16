extends Sprite2D

@export var tile_map : TileMap # global tilemap, use to keep track of which tile to move on

var spawn_location : Vector2 # Origin of the Brain to spawn back at

var next_tile_loc : Vector2

var growth_percent : float = 0
@export var growth_rate : float = 0.5 

var health : float = 100

@export var move_speed : float = 5.0
# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	
	spawn_location = global_position
	next_tile_loc = global_position
	
	print(next_tile_loc)
	print(global_position)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#print(global_position.distance_to(next_tile_loc))
	if global_position.distance_to(next_tile_loc) < 0.25 and tile_map != null:
		var potential_walk : Array
		var current_tile = tile_map.local_to_map(tile_map.to_local(global_position))
		for offset in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
			var neighbor : Vector2i = current_tile + offset
			if tile_map.get_cell_source_id(0, neighbor) == 3:
				potential_walk.append(neighbor)
		
		next_tile_loc = tile_map.to_global(tile_map.map_to_local(potential_walk.pick_random()))
		print("set: ", next_tile_loc)
	else:
		global_position += global_position.direction_to(next_tile_loc) * delta * move_speed

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
