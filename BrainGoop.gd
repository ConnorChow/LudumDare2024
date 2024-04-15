extends TileMap

@export var world_tilemap : TileMap
@export var tile_damage : float = 20 # dps applied to ants
@export var tile_max_health : float = 100 # max health each tile gets
@export var growth_speed : float = 0.25

@export var spawn_points_system : Node2D
@export var brain : PackedScene
var brains : Array[Node2D]

# Key: Vector2i denoting tile # Value: float denoting health
var tile_healths : Dictionary
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
	set_layer_enabled(1, true)
	add_layer(1)
	
	if spawn_points_system != null:
		for point in spawn_points_system.get_children():
			if point is Node2D:
				_spawn_brain(point.global_position)

func _spawn_brain(location : Vector2):
	var spawn_brain : Node2D = brain.instantiate() as Node2D
	add_child(spawn_brain)
	spawn_brain.owner = get_tree().root
	spawn_brain.global_position = location
	spawn_brain.tile_map = world_tilemap
	brains.append(spawn_brain)

@export var brain_tile_range : int = 2
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for brain in brains:
		var tile : Vector2i = _get_tile_at_position(brain.global_position)
		for cell in _flood_cells([tile], brain_tile_range):
			_grow_goop_in_tile(cell, delta)

# Returns an array of Vecor2i's representing fillable cells
func _flood_cells(in_cell : Array, depth : int = 0, checked_cell : Array = [])->Array:
	for cell in in_cell:
		for neighbor in get_surrounding_cells(cell):
			if _is_cell_floodable(neighbor) and !in_cell.has(neighbor) and !checked_cell.has(neighbor):
				in_cell.append(neighbor)
		checked_cell.append(cell)
	if depth <= 0:
		return in_cell
	else:
		return _flood_cells(in_cell, depth - 1, checked_cell)

func _is_cell_floodable(tile : Vector2i) -> bool:
	return world_tilemap.get_cell_source_id(1, tile) == 3 and !tile_healths.has(tile)

func _spawn_goop(tile : Vector2i):
	set_cell(1, tile, 0, Vector2i(0, 16))
	tile_healths[tile] = tile_max_health

func _get_tile_at_position(global_position : Vector2) -> Vector2i:
	return world_tilemap.local_to_map(world_tilemap.to_local(global_position))

func _grow_goop_in_tile(tile : Vector2i, delta : float):
	if !tile_healths.has(tile):
		if potential_tiles.has(tile):
			potential_tiles[tile] += growth_speed * delta
			if potential_tiles[tile] >= 1.0:
				_spawn_goop(tile)
		elif world_tilemap.get_cell_source_id(1, tile) == 3:
			potential_tiles[tile] = 0.0
