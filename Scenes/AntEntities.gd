extends MultiMeshInstance2D

enum Faction {
	PLAYER,
	BRAIN_SLAYER,
	ROOK_INVASION
}

@export var mesh : Mesh
# Maximum number of ants that can exist in a scene at any time
@export var max_ant_count : int = 500

var active_ant_queue : Array
var available_ant_queue : Array

# Key is a unique identifier for each ant. Value is the faction
var ant_colony_factions : Dictionary
# Key is the unique identifier
# Value is dictionary of data for the ant behaviour
var ant_colony_data : Dictionary

# Value holds a dictionary with values for the position and heading of an ant
var ant_colony_transforms : Dictionary

func _ant_exists(entity : int)->bool:
	return ant_colony_data.has(entity) and ant_colony_factions.has(entity) and ant_colony_transforms.has(entity)

# All string keys for data types in sim
var ant_max_health = "max_health"
var ant_health = "health"
var ant_speed = "speed"
var ant_damage = "damage"

var ant_transform_position = "position"
var ant_transform_heading = "heading"
var ant_transform_desired_heading = "desired_heading"

# Called when the node enters the scene tree for the first time.
func _ready():
	available_ant_queue = range(0, max_ant_count)
	available_ant_queue.reverse()
	multimesh = MultiMesh.new()
	multimesh.mesh = mesh
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.instance_count = max_ant_count
	multimesh.visible_instance_count = 0
	
	var default_data : Dictionary = {
		ant_max_health = 100 as float,
		ant_health = 100 as float,
		ant_speed = 5 as float,
		ant_damage = 20 as float
	}
	
	for i in range(0, 20):
		_spawn_ant(Faction.PLAYER, Vector2(randf_range(-1, 1) * 30, randf_range(-1, 1) * 30), default_data)

# Allows an ant to get spawned in
func _spawn_ant(faction : Faction, spawn_position : Vector2, data : Dictionary)->int:
	if available_ant_queue.size() > 0:
		var entity : int = available_ant_queue.pop_back() as int
		ant_colony_factions[entity] = faction
		ant_colony_data[entity] = data
		ant_colony_transforms[entity] = {
			ant_transform_position : spawn_position,
			ant_transform_heading : Vector2.ZERO.direction_to(Vector2(randf_range(-1, 1), randf_range(-1, 1)))
		}
		
		active_ant_queue.push_front(entity)
		
		multimesh.visible_instance_count+=1
		return entity
	else:
		return -1

func _kill_ant(entity : int):
	# delete all data
	ant_colony_factions.erase(entity)
	ant_colony_data.erase(entity)
	ant_colony_transforms.erase(entity)
	# update entity lists
	available_ant_queue.push_front(entity)
	active_ant_queue.erase(entity)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_process_multimesh(delta)

func _process_ants(delta : float):
	for entity in active_ant_queue:
		_process_singular_ant_behaviour(entity, delta)

func _process_singular_ant_behaviour(entity : int, delta : float):
	if _ant_exists(entity):
		var faction : Faction = ant_colony_factions[entity]
	

func _process_multimesh(delta : float):
	active_ant_queue.sort_custom(func(a : int, b : int):
		var a_pos : Vector2 = multimesh.get_instance_transform_2d(a).origin
		var b_pos : Vector2 =  multimesh.get_instance_transform_2d(b).origin
		
		if a_pos.y < b_pos.y:
			return true
		elif a_pos.y == b_pos.y and a_pos.x < b_pos.x:
			return true
		
		return false
	)
	var multimesh_index = 0
	for entity in active_ant_queue:
		var mesh_position : Vector2 = ant_colony_transforms[entity][ant_transform_position] as Vector2
		print(mesh_position)
		multimesh.set_instance_transform_2d(multimesh_index, Transform2D(0, mesh_position))
		multimesh_index += 1
