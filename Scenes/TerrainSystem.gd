extends Node

@export var cell_distance_limit : Vector2i
@export var noise_threshold : float = 0.5
@export var noise_offset : float = 2.5

@onready var terrain_map : TileMap = $TerrainMap
@export var tile_set : TileSet

var noise : FastNoiseLite
var active_cells : Dictionary

# Called when the node enters the scene tree for the first time.
func _ready():
	terrain_map.tile_set = tile_set
	terrain_map.add_layer(1)
	terrain_map.set_layer_enabled(1, true)
	
	noise = FastNoiseLite.new()
	
	for x in range(-cell_distance_limit.x, cell_distance_limit.x):
		for y in range(-cell_distance_limit.y, cell_distance_limit.y):
			var noise_val : float = noise.get_noise_2d(x * noise_offset, y * noise_offset)
			print(noise_val)
			if noise_val > noise_threshold and Vector2.ZERO.distance_to(Vector2(x, y)) > 5:
				terrain_map.set_cell(1, Vector2i(x, y), 0, Vector2i.ZERO)
			else:
				terrain_map.set_cell(1, Vector2i(x, y), 0, Vector2i(1, 0))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

