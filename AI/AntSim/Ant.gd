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
	SEEK, # Move towards the enemy it scans
	HIT, # Apply damage each second on enemy it is attacking
	FLEE # Unit will run away if health gets low
}
@export var fight_state : FightState

@export_category("Ant Data")
@onready var navigation_agent_2d : NavigationAgent2D = $NavigationAgent2D
@onready var visibility_scanner : Area2D = $VisibilityScanner
@onready var grabbing_scanner : Area2D = $GrabbingScanner

@export var max_health : float = 100
var health : float = 100

@export var patrol_radius : float = 25
@export var movement_speed : float = 10
@export var fighting_strength : float = 20

var initialized : bool = false

var player : Node2D
var player_base : Node2D

@export var flag : Vector2

var currency_value : int
# Called when the node enters the scene tree for the first time.
func _ready():
	health = max_health
	
	navigation_agent_2d.path_desired_distance = 10.0
	navigation_agent_2d.target_desired_distance = 10.0
	call_deferred("_ready_navmesh")
	
	player = get_tree().get_nodes_in_group("player").pop_front()
	player_base = get_tree().get_nodes_in_group("player_base").pop_front()
	brain_slayer_goop = get_tree().get_nodes_in_group("goop").pop_front()
	
	match OptionsController.difficulty:
		1:
			currency_value = 3
		2:
			currency_value = 2
		3:
			currency_value = 1

func _ready_navmesh():
	await get_tree().physics_frame
	initialized = true
	_receive_command_follow()

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
var former_parent : Node
func _task_forage_behaviour(delta):
	match forage_state:
		ForageState.APPROACH:
			if navigation_agent_2d.is_navigation_finished() and global_position.distance_to(flag) < 512:
				idle_marker = flag
				forage_state = ForageState.SURVEY
			elif navigation_agent_2d.is_navigation_finished() and global_position.distance_to(flag) >= 512:
				navigation_agent_2d.target_position = flag
		ForageState.SURVEY:
			if visible_currencies.size() > 0:
				target_currency = visible_currencies.pop_front() as Node2D
				navigation_agent_2d.target_position = target_currency.global_position
				forage_state = ForageState.GRAB
			else:
				_idle_behaviour(delta)
		ForageState.GRAB:
			_check_valid_list()
			if reachable_currencies.size() > 0:
				_grab_item(reachable_currencies.pop_front())
				navigation_agent_2d.target_position = player_base.global_position
				forage_state = ForageState.RETURN
		ForageState.RETURN:
			if global_position.distance_to(player_base.global_position) < 10 and grabbed_item_anchor.get_child_count() > 0:
				CurrencyCount.currency += currency_value
				player.updateCur()
				grabbed_item_anchor.get_child(0).queue_free()
				forage_state = ForageState.APPROACH

func _check_valid_list():
	if target_currency == null or !(target_currency as Area2D).monitorable or target_currency.get_parent().is_in_group("player"):
		forage_state = ForageState.SURVEY

@onready var grabbed_item_anchor = $GrabbedItemAnchor
func _grab_item(item : Node2D):
	former_parent = get_parent()
	visible_currencies.erase(item)
	item.global_position = grabbed_item_anchor.global_position
	item.reparent(grabbed_item_anchor)
	(item as Area2D).monitorable = false

func _drop_item():
	if grabbed_item_anchor.get_child_count() > 0:
		var item = grabbed_item_anchor.get_child(0)
		item.reparent(former_parent)
		(item as Area2D).monitorable = true
		target_currency = null
		forage_state = ForageState.APPROACH

var target_enemy : Area2D
@onready var brain_slayer_goop
func _fight_behaviour(delta : float):
	match fight_state:
		FightState.SEEK:
			if visible_enemies.size() > 0:
				target_enemy = visible_enemies[0]
				navigation_agent_2d.target_position = target_enemy.global_position
				fight_state = FightState.HIT
			else:
				_idle_behaviour(delta)
		FightState.HIT:
			if target_enemy == null or !visible_enemies.has(target_enemy):
				fight_state = FightState.SEEK
				return
			else:
				if reachable_enemies.size() > 0:
					_attack_goop(reachable_enemies, fighting_strength)
				else:
					navigation_agent_2d.target_position = target_enemy.global_position

var attack_buffer : bool = false
func _attack_goop(target_enemy, fighting_strength):
	if attack_buffer : return
	
	brain_slayer_goop._damage_goop(target_enemy, fighting_strength)
	_take_returning_damage()
	
	attack_buffer = true
	await get_tree().create_timer(1).timeout
	attack_buffer = false

func _take_returning_damage():
	health -= brain_slayer_goop.tile_damage
	if health <= 0:
		queue_free()

# set this up via group call with a signal from the player 
func _receive_command_follow():
	behaviour_state = BehaviourState.FOLLOW_PLAYER
	_drop_item()

func _receive_command_forage():
	behaviour_state = BehaviourState.TASK
	task_state = TaskType.FORAGE
	forage_state = ForageState.APPROACH
	flag = player.global_position

func _receive_command_fight():
	behaviour_state = BehaviourState.FIGHT
	fight_state = FightState.SEEK
	flag = player.global_position
	idle_state = IdleState.PAUSE
	idle_marker = flag

var visible_currencies : Array[Node2D]
var visible_enemies : Array[Area2D]
func _entity_seen(area):
	if area.is_in_group("Grab") and !area.get_parent().is_in_group("player"):
		visible_currencies.append(area)
	if area.is_in_group("goop_body"):
		visible_enemies.append(area)

func entity_lost_sight(area):
	if area.is_in_group("Grab"):
		visible_currencies.erase(area)
	if area.is_in_group("goop_body"):
		visible_enemies.erase(area)


var reachable_currencies : Array[Node2D]
var reachable_enemies : Array[Area2D]
func entity_entered_range(area):
	if area.is_in_group("Grab") and !area.get_parent().is_in_group("player"):
		reachable_currencies.append(area)
	if area.is_in_group("goop_body"):
		reachable_enemies.append(area)

func entity_exited_range(area):
	if area.is_in_group("Grab"):
		reachable_currencies.erase(area)
	if area.is_in_group("goop_body"):
		reachable_enemies.erase(area)

var movement_delta : float
var before_velocity : Vector2
func _physics_process(delta):
	if navigation_agent_2d.is_navigation_finished() or !initialized:
		return
	if behaviour_state == BehaviourState.FOLLOW_PLAYER:
		navigation_agent_2d.path_desired_distance = 30.0
		navigation_agent_2d.target_desired_distance = 30.0
	else:
		navigation_agent_2d.path_desired_distance = 10.0
		navigation_agent_2d.target_desired_distance = 10.0
	
	movement_delta = delta
	var next_position = navigation_agent_2d.get_next_path_position()
	var velocity : Vector2 = (global_position.direction_to(next_position)) * delta * movement_speed
	#global_position += velocity
	if navigation_agent_2d.avoidance_enabled:
		before_velocity = velocity
		navigation_agent_2d.velocity = (velocity)
	else:
		_compute_pathfinding(velocity)
	
	if velocity.x > 0:
		flip_h = false
		grabbed_item_anchor.position.x = abs(grabbed_item_anchor.position.x)
	elif velocity.x < 0:
		flip_h = true
		grabbed_item_anchor.position.x = -abs(grabbed_item_anchor.position.x)

func _compute_pathfinding(safe_velocity):
	if navigation_agent_2d.is_navigation_finished() or !initialized:
		return
	
	var avoidance_velocity : Vector2 = safe_velocity - before_velocity
	var velocity = Vector2.ZERO
	#if before_velocity.distance_to(Vector2.ZERO) > 0.1:
	velocity = before_velocity + (avoidance_velocity * movement_delta * 2)
	
	global_position += velocity
