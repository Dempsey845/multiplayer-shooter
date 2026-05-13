class_name ElectricityChain
extends Node2D

@export var target_group_name: String = "target"
@export var max_connections: int = 25
@export var min_distance_between_targets: float = 70.0

@onready var line_2d: Line2D = $Line2D
@onready var point_creation_timer: Timer = $PointCreationTimer
@onready var point_removal_timer: Timer = $PointRemovalTimer
@onready var hitbox_component: HitboxComponent = $HitboxComponent

var current_target: Node2D 
var targets: Array[Node]
var target_to_targets: Dictionary[Node2D, Array]
var min_distance_between_targets_sq: float
var source_peer_id: int
var electric_hit_effect_scene: PackedScene = preload("uid://c12qa23obhfma")
var start_target_position: Vector2

func _ready() -> void:
	point_creation_timer.timeout.connect(_on_creation_timer_timeout)
	point_removal_timer.timeout.connect(_on_removal_timer_timeout)
	
	if is_multiplayer_authority():
		hitbox_component.hit_hurtbox.connect(_on_hit_hurtbox)
	
	targets = get_tree().get_nodes_in_group(target_group_name)
	start(get_closest_target(false))
	
	hitbox_component.source_peer_id = source_peer_id

func get_closest_target(comprehensive: bool = true) -> Node2D:
	var closest_target: Node2D = null
	var closest_target_distance_sq := INF
	
	for target in targets:
		if not is_instance_valid(target):
			continue
			
		if comprehensive:
			if target == current_target or target in target_to_targets[current_target]:
				continue
		
		if closest_target:
			var distance_to_target_sq = closest_target.global_position.distance_squared_to(target.global_position)
			
			if distance_to_target_sq < closest_target_distance_sq and distance_to_target_sq < min_distance_between_targets_sq:
				closest_target = target
				closest_target_distance_sq = distance_to_target_sq
		else:
			closest_target = target
			
	return closest_target

func get_next_target() -> Node2D:
	if not current_target or not is_instance_valid(current_target):
		return
	
	if not target_to_targets.has(current_target):
		target_to_targets[current_target] = []
	
	var closest_target := get_closest_target()
	
	if closest_target:
		target_to_targets[current_target].append(closest_target)
		
		if not target_to_targets.has(closest_target):
			target_to_targets[closest_target] = [current_target]
		else:
			target_to_targets[closest_target].append(current_target)
			
		current_target = closest_target
		
	return closest_target

func start(starting_target: Node2D):
	min_distance_between_targets_sq = min_distance_between_targets * min_distance_between_targets
	
	target_to_targets.clear()
	current_target = starting_target
	
	line_2d.clear_points()
	line_2d.add_point(starting_target.global_position)
	
	try_create_point_at_next_target()
	point_creation_timer.start()

func try_create_point_at_next_target():
	if line_2d.get_point_count() >= max_connections:
		point_creation_timer.stop()
		return
	
	var next_target := get_next_target()
	if next_target:
		line_2d.add_point(next_target.global_position)
		
		hitbox_component.global_position = next_target.global_position
		hitbox_component.check_area_for_hurtbox()
	else:
		point_creation_timer.stop()
		point_removal_timer.start()

func _on_creation_timer_timeout():
	try_create_point_at_next_target()
	
func _on_removal_timer_timeout():
	if line_2d.get_point_count() == 0:
		point_removal_timer.stop()
		queue_free.call_deferred()
	else:
		line_2d.remove_point(0)

func _on_hit_hurtbox(hurtbox_component: HurtboxComponent):
	spawn_electric_hit_effects.rpc(hurtbox_component.global_position)

@rpc("authority", "call_local", "unreliable")
func spawn_electric_hit_effects(spawn_position: Vector2):
	var electric_hit_effect = electric_hit_effect_scene.instantiate()
	electric_hit_effect.global_position = spawn_position
	get_parent().add_child(electric_hit_effect, true)
