extends Sprite2D

enum BehaviourState {
	IDLE,
	FOLLOW_PLAYER,
	TASK,
	FIGHT
}
enum TaskType {
	FORAGE_GEMS,
	MINE_DEPOSITS
}

@onready var navigation_agent_2d : NavigationAgent2D = $NavigationAgent2D
@onready var area_2d : Area2D = $Area2D

@export var max_health : float
var health : float

var movement_speed : float

var mining_strength : float
var fighting_strength : float
var carry_strength : float

var behaviour_state : BehaviourState
var task_state : TaskType

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# set this up via group call with a signal from the player 
func _rally_to_player(player : Node2D):
	pass
