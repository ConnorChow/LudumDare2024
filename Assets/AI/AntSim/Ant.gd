extends Sprite2D
@export_category("State Authoring")
enum BehaviourState {
	IDLE,
	FOLLOW_PLAYER,
	TASK,
	FIGHT
}
@export var behaviour_state : BehaviourState = BehaviourState.IDLE

enum IdleState {
	PATROL,
	PAUSE
}
@export var idle_state : IdleState = IdleState.PAUSE
var idle_marker : Vector2
var target_patrol_position : Vector2

enum TaskType {
	MINE,
	FORAGE
}
@export var task_state : TaskType
enum MineState {
	FIND,
	DESTROY
}
@export var mine_state : MineState
enum ForageState {
	APPROACH, # move towards the flag set for it
	SURVEY, # patrol around until it finds a grabable item
	GRAB, # go to and grab an item it finds
	RETURN # bring the item back to the base
}
@export var forage_state : ForageState

var item_found : Area2D # use for both grabbable and mineable items

enum FightState {
	APPROACH, # Move towards the enemy it scans
	HIT, # Apply damage each second on enemy it is attacking
	FLEE # Unit will run away if health gets low
}
@export var fight_state : FightState

@export_category("Ant Data")
@onready var navigation_agent_2d : NavigationAgent2D = $NavigationAgent2D
@onready var visibility_scanner : Area2D = $VisibilityScanner
@onready var grabbing_scanner : Area2D = $GrabbingScanner

@export var max_health : float
var health : float

@export var patrol_radius : float = 25

@export var movement_speed : float = 10

@export var mining_strength : float
@export var fighting_strength : float
@export var carry_strength : float

var initialized : bool = false

var player : Node2D
var player_base : Node2D

@export var flag : Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	navigation_agent_2d.path_desired_distance = 4.0
	navigation_agent_2d.target_desired_distance = 4.0
	call_deferred("_ready_navmesh")
	
	player = get_tree().get_nodes_in_group("player").pop_front()
	player_base = get_tree().get_nodes_in_group("player_base").pop_front()
	

func _ready_navmesh():
	await get_tree().physics_frame
	initialized = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	match behaviour_state:
		BehaviourState.IDLE:
			_idle_behaviour(delta)
		BehaviourState.FOLLOW_PLAYER:
			_follow_behaviour(delta)
		BehaviourState.TASK:
			_task_behaviour(delta)
		BehaviourState.FIGHT:
			_fight_behaviour(delta)

func _physics_process(delta):
	if navigation_agent_2d.is_navigation_finished() or !initialized:
		return
	
	var next_position = navigation_agent_2d.get_next_path_position()
	var velocity : Vector2 = global_position.direction_to(next_position) * delta * movement_speed
	global_position += velocity
	if velocity.x > 0:
		flip_h = false
	elif velocity.x < 0:
		flip_h = true

func _idle_behaviour(delta : float):
	match idle_state:
		IdleState.PATROL:
			if navigation_agent_2d.is_navigation_finished():
				idle_state = IdleState.PAUSE
		IdleState.PAUSE:
			target_patrol_position = idle_marker + Vector2(randf_range(-patrol_radius, patrol_radius), randf_range(-patrol_radius, patrol_radius))
			idle_state = IdleState.PATROL
			navigation_agent_2d.target_position = target_patrol_position
			print(target_patrol_position)

func _follow_behaviour(delta : float):
	navigation_agent_2d.target_position = player.global_position

func _task_behaviour(delta : float):
	match task_state:
		TaskType.MINE:
			pass
		TaskType.FORAGE:
			_task_forage_behaviour(delta)

var target_currency : Area2D
func _task_forage_behaviour(delta):
	match forage_state:
		ForageState.APPROACH:
			if navigation_agent_2d.is_navigation_finished() and global_position.distance_to(flag.global_position) < 512:
				idle_marker = flag.global_position
				forage_state = ForageState.SURVEY
			elif navigation_agent_2d.is_navigation_finished() and global_position.distance_to(flag.global_position) >= 512:
				navigation_agent_2d.target_position = flag.global_position
		ForageState.SURVEY:
			if visible_currencies.size() > 0:
				target_currency = visible_currencies.pop_front() as Node2D
				navigation_agent_2d.target_position = target_currency.global_position
				forage_state = ForageState.GRAB
			else:
				_idle_behaviour(delta)
		ForageState.GRAB:
			if reachable_currencies.size() > 0:
				_grab_item(reachable_currencies.pop_front())
				navigation_agent_2d.target_position = player_base.global_position
				forage_state = ForageState.RETURN
		ForageState.RETURN:
			if global_position.distance_to(player_base.global_position) < 10 and grabbed_item_anchor.get_child_count() > 0:
				CurrencyCount.currency += 1
				grabbed_item_anchor.get_child(0).queue_free()
				forage_state = ForageState.APPROACH

@onready var grabbed_item_anchor = $GrabbedItemAnchor
func _grab_item(item : Node2D):
	visible_currencies.erase(item)
	item.global_position = grabbed_item_anchor.global_position
	item.reparent(grabbed_item_anchor)
	(item as Area2D).monitorable = false

func _fight_behaviour(delta : float):
	pass

# set this up via group call with a signal from the player 
func _receive_command_follow():
	behaviour_state = BehaviourState.FOLLOW_PLAYER


var visible_currencies : Array[Node2D]
func _entity_seen(area):
	if area.is_in_group("Grab"):
		visible_currencies.append(area)

func entity_lost_sight(area):
	if area.is_in_group("Grab"):
		visible_currencies.erase(area)


var reachable_currencies : Array[Node2D]
func entity_entered_range(area):
	if area.is_in_group("Grab"):
		reachable_currencies.append(area)

func entity_exited_range(area):
	if area.is_in_group("Grab"):
		reachable_currencies.erase(area)
