extends TileMap

@onready var area_2d : Area2D = $Area2D

@export var world_tilemap : TileMap
@export var tile_damage : float = 20 # dps applied to ants
@export var tile_max_health : float = 100 # max health each tile gets
@export var growth_speed : float = 0.25

@export var spawn_points_system : Node2D
@export var brain : PackedScene
var brains : Array[Node2D]

# Key: Vector2i denoting tile # Value: float denoting health
var tile_healths : Dictionary
var tile_colliders : Dictionary
var collider_tiles : Dictionary
# Key: tile we want to grow goop # Value: progress to spawning goop
var potential_tiles : Dictionary

func _spawn_cell(tile : Vector2i):
	if tile_healths.has(tile):
		tile_healths[tile] = tile_max_health

func _damage_cell(tile : Vector2i, damage : float):
	if tile_healths.has(tile):
		tile_healths[tile] -= damage

@export var goop_tileset : TileSet

# Called when the node enters the scene tree for the first time.
func _ready():
	tile_set = goop_tileset
	add_layer(1)
	set_layer_enabled(1, true)
	
	#_spawn_goop(Vector2i(-4,7))
	
	if spawn_points_system != null:
		for point in spawn_points_system.get_children():
			if point is Node2D:
				_spawn_brain(point.global_position)

func _spawn_brain(location : Vector2):
	var spawn_brain : Node2D = brain.instantiate() as Node2D
	spawn_brain.global_position = location
	spawn_brain.tile_map = world_tilemap
	add_child(spawn_brain)
	spawn_brain.owner = get_tree().root
	brains.append(spawn_brain)

# does nothing currently
@export var brain_tile_range : int = 0
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for brain in brains:
		if !(brain._is_grown() as bool): continue
		var tile : Vector2i = _get_tile_at_position(brain.global_position)
		for cell in _flood_cells([tile], brain_tile_range):
			_grow_goop_in_tile(cell, delta)

# Returns an array of Vecor2i's representing fillable cells
func _flood_cells(in_cell : Array, depth : int = 0, checked_cell : Array = [])->Array:
	for cell in in_cell.duplicate():
		if checked_cell.has(cell): continue
		#print("main cell: ", cell)
		for offset in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
			var neighbor : Vector2i = cell + offset
			if _is_cell_floodable(neighbor) and !in_cell.has(neighbor) and !checked_cell.has(neighbor):
				in_cell.append(neighbor)
				#print(neighbor)
		checked_cell.append(cell)
	return in_cell

func _is_cell_floodable(tile : Vector2i) -> bool:
	return world_tilemap.get_cell_source_id(0, tile) == 3 and !tile_healths.has(tile)

@export var collision_square : RectangleShape2D
func _spawn_goop(tile : Vector2i):
	set_cell(1, tile, 0, Vector2i(0, 1))
	tile_healths[tile] = tile_max_health
	var tile_position : Vector2 = world_tilemap.to_global(world_tilemap.map_to_local(tile))
	
	tile_colliders[tile] = CollisionShape2D.new() as CollisionShape2D
	var new_collider = tile_colliders[tile] as CollisionShape2D
	
	new_collider.global_position = tile_position
	new_collider.owner = get_tree().root
	new_collider.shape = collision_square
	
	area_2d.add_child(new_collider)
	#collider_tiles[new_collider] = tile

func _damage_goop(shape_index : int, damage : float):
	var shape = area_2d.shape_find_owner(shape_index)
	var tile : Vector2i = world_tilemap.local_to_map((area_2d.shape_owner_get_owner(shape) as Node2D).global_position)
	if tile_healths.has(tile):
		tile_healths[tile] -= damage
	else:
		_kill_goop(tile)

func _kill_goop(tile : Vector2i):
	erase_cell(1, tile)
	tile_healths.erase(tile)
	tile_colliders.erase(tile)
	(tile_colliders[tile] as Node2D).queue_free()

func _get_tile_at_position(global_position : Vector2) -> Vector2i:
	return world_tilemap.local_to_map(world_tilemap.to_local(global_position))

func _grow_goop_in_tile(tile : Vector2i, delta : float):
	if !tile_healths.has(tile):
		if potential_tiles.has(tile):
			potential_tiles[tile] += growth_speed * delta
			if potential_tiles[tile] >= 1.0:
				potential_tiles.erase(tile)
				_spawn_goop(tile)
		elif world_tilemap.get_cell_source_id(0, tile) == 3:
			potential_tiles[tile] = 0.0
