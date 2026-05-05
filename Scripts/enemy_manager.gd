class_name EnemyManager extends Node

signal round_changed(round_number: int)
signal round_completed
signal game_completed

const ROUND_BASE_TIME := 10
const ROUND_GROWTH := 5

const BASE_ENEMY_SPAWN_TIME := 2.0
const ENEMY_SPAWN_TIME_GROWTH := -0.15

const MAX_ROUNDS: int = 50

static var instance: EnemyManager

@export var enemy_scene: PackedScene
@export var enemy_spawn_root: Node
@export var spawn_rect: ReferenceRect
@export var upgrade_manager: UpgradeManager
@export var enemy_resources: Array[EnemyResource]

@onready var spawn_interval_timer: Timer = $SpawnIntervalTimer
@onready var round_timer: Timer = $RoundTimer

var enemy_max_health: int = 3
var charge_duration: float = 0.5
var attack_cooldown_duration: float = 4.0

var _round_count: int
var round_count: int:
	get:
		return _round_count 
	set(value):
		_round_count = value
		round_changed.emit(_round_count)
		
var spawned_enemies: int

func _ready() -> void:
	spawn_interval_timer.timeout.connect(_on_spawn_interval_timer_timeout)
	round_timer.timeout.connect(_on_round_timer_timeout)
	
	upgrade_manager.upgrades_completed.connect(_on_upgrades_completed)
	
	GameEvents.enemy_died.connect(_on_enemy_died)
	
	instance = self
	
func start():
	if is_multiplayer_authority():
		begin_round()
	
func synchronize(to_peer_id: int = -1):
	if not is_multiplayer_authority():
		return
	
	var data = {
		"round_timer_is_running": not round_timer.is_stopped(),
		"round_timer_time_left": round_timer.time_left,
		"round_count": round_count
	}
	
	if to_peer_id > -1 and to_peer_id != 1:
		# Send the synchronized data a client who joins mid round
		# Only sends it to that specific peer
		_synchronize.rpc_id(to_peer_id, data)
	else:
		# Send the synchronized data to all clients (e.g. on new round)
		_synchronize.rpc(data)
	
@rpc("authority", "call_remote", "reliable")
func _synchronize(data: Dictionary):
	var wait_time: float = data["round_timer_time_left"] 
	if wait_time > 0:
		round_timer.wait_time = wait_time
	if data["round_timer_is_running"]:
		round_timer.start()
	round_count = data["round_count"]
	
func get_round_time_remainding() -> float:
	return round_timer.time_left
	
func begin_round():
	round_count += 1
	round_timer.wait_time = ROUND_BASE_TIME + ((round_count - 1) * ROUND_GROWTH)
	round_timer.start()
	
	spawn_interval_timer.wait_time = BASE_ENEMY_SPAWN_TIME + ((round_count -1) * ENEMY_SPAWN_TIME_GROWTH)
	spawn_interval_timer.start()
	
	synchronize()
	
func check_round_completed():
	if not round_timer.is_stopped():
		return
		
	if spawned_enemies == 0:
		if round_count == MAX_ROUNDS:
			complete_game()
		else:
			round_completed.emit()
	
func complete_game():
	await get_tree().create_timer(2.0).timeout
	game_completed.emit()
	
func get_random_spawn_position() -> Vector2:
	var x = randf_range(0.0, spawn_rect.size.x)
	var y = randf_range(0.0, spawn_rect.size.y)
	
	return spawn_rect.global_position + Vector2(x, y)
	
func spawn_enemy():
	var enemy = enemy_scene.instantiate() as Enemy
	enemy.global_position = get_random_spawn_position()
	enemy.charge_duration = charge_duration
	enemy.attack_cooldown_duration = attack_cooldown_duration
	enemy_spawn_root.add_child(enemy, true)
	
	enemy.health_component.set_max_health(enemy_max_health)
	
	var enemy_resource = enemy_resources.pick_random()
	enemy.resource_id = enemy_resource.id
	
	spawned_enemies += 1
	
func get_enemy_resource_by_id(id: String) -> EnemyResource:
	return enemy_resources[enemy_resources.find_custom(func(resource):
		return resource.id == id
	)]
	
func _on_spawn_interval_timer_timeout():
	if is_multiplayer_authority():
		spawn_enemy()
		spawn_interval_timer.start()

func _on_round_timer_timeout():
	if is_multiplayer_authority():
		spawn_interval_timer.stop()
		check_round_completed()

func _on_enemy_died():
	spawned_enemies -= 1
	check_round_completed()

func _on_upgrades_completed():
	begin_round()
