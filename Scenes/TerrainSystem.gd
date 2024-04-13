extends Node2D

@export var cell_distance_limit : Vector2i
@export var noise_threshold : float = 0.5

@onready var place_holder_map = $placeHolderMap

var noise : NoiseTexture2D = NoiseTexture2D.new()
var active_cells : Dictionary

# Called when the node enters the scene tree for the first time.
func _ready():
	for x in range(-cell_distance_limit.x, cell_distance_limit.x):
		for y in range(-cell_distance_limit.y, cell_distance_limit.y):
			var noise_val : float = noise.noise.get_noise_2d(x, y)
			if noise_val > noise_threshold:
				pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

