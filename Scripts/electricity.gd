class_name ElectricityChain
extends Node2D

const TIME_BETWEEN_POINTS := 0.1

@export var target_group_name: String = "target"
@export var max_connections: int = 25
@export var min_distance_between_targets: float = 150.0
@export var start_target: Node2D

@onready var line_2d: Line2D = $Line2D

var current_target: Node2D 
var current_targets: Array[Node2D]

var target_to_targets: Dictionary[Node2D, Array]

var min_distance_between_targets_sq: float

func _ready() -> void:
	if start_target:
		start(start_target)

func get_next_target(targets: Array[Node]) -> Node2D:
	if not current_target or not is_instance_valid(current_target):
		return
	
	if not target_to_targets.has(current_target):
		target_to_targets[current_target] = []
	
	var closest_target: Node2D
	var closest_target_distance_sq := INF
	
	for target in targets:
		if not is_instance_valid(target):
			continue
		if target == current_target or target in target_to_targets[current_target]:
			continue
		
		var distance_to_target_sq = current_target.global_position.distance_squared_to(target.global_position)
		if distance_to_target_sq < closest_target_distance_sq and distance_to_target_sq < min_distance_between_targets_sq:
			closest_target = target
			closest_target_distance_sq = distance_to_target_sq
	
	
	if closest_target:
		current_targets.append(closest_target)
		
		target_to_targets[current_target].append(closest_target)
		
		if not target_to_targets.has(closest_target):
			target_to_targets[closest_target] = [current_target]
		else:
			target_to_targets[closest_target].append(current_target)
			
		current_target = closest_target
		
	return closest_target

func start(starting_target: Node2D):
	min_distance_between_targets_sq = min_distance_between_targets * min_distance_between_targets
	
	current_targets.clear()
	target_to_targets.clear()
	
	current_targets.append(starting_target)
	current_target = starting_target
	
	var targets := get_tree().get_nodes_in_group(target_group_name)
	
	for i in range(max_connections):
		var next_target := get_next_target(targets)
		if next_target:
			line_2d.add_point(next_target.global_position)
			
			# TODO: move a hitboxcomponent to this point and force check for hurtboxes
			
			await get_tree().create_timer(TIME_BETWEEN_POINTS).timeout
		else:
			break
		
	while len(line_2d.points) > 0:
		line_2d.remove_point(0)
		await get_tree().create_timer(TIME_BETWEEN_POINTS).timeout
