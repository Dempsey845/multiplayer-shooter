class_name Enemy
extends CharacterBody2D

signal attack_shot

const DASH_ATTACK_SPEED := 400.0

enum AttackType {
	ChargeAndDash,
	ChargeAndShoot
}

@export var attack_count: int = 3
@export var attack_agent: EnemyAttackAgent

@onready var enemy_sprite: Sprite2D = %EnemySprite

@onready var target_timer: Timer = $TargetTimer
@onready var health_component: HealthComponent = $HealthComponent
@onready var visuals: Node2D = $Visuals

@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer
@onready var charge_attack_timer: Timer = $ChargeAttackTimer
@onready var hitbox_collision_shape: CollisionShape2D = %HitboxCollisionShape
@onready var alert_sprite: Sprite2D = $AlertSprite
@onready var attack_timer: Timer = $AttackTimer

@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var hit_stream_player: AudioStreamPlayer = $HitStreamPlayer

var enemy_resource: EnemyResource

var impact_particles_scene: PackedScene = preload("uid://dp5cvajlkl4uc")
var ground_particles_scene: PackedScene = preload("uid://clql2p3h4o5np")

var target_position: Vector2
var speed: float = 40.0
var state_machine: CallableStateMachine = CallableStateMachine.new()
var default_collision_mask: int
var default_collision_layer: int
var alert_tween: Tween
var current_attack_count: int

var current_state: String:
	get:
		return state_machine.current_state
	set(value):
		state_machine.change_state(Callable.create(self, value))

func _notification(what: int) -> void:
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		state_machine.add_states(state_spawn, enter_state_spawn, Callable())
		state_machine.add_states(state_normal, enter_state_normal, leave_state_normal)
		state_machine.add_states(state_charge_attack, enter_state_charge_attack, leave_state_charge_attack)
		state_machine.add_states(state_attack, enter_state_attack, leave_state_attack)

func _ready() -> void:
	default_collision_mask = collision_mask
	default_collision_layer = collision_layer
	hitbox_collision_shape.disabled = true
	
	alert_sprite.scale = Vector2.ZERO
	
	enemy_sprite.texture = enemy_resource.enemy_texture
	enemy_sprite.hframes = enemy_resource.h_frame_count
	enemy_sprite.frame = enemy_resource.start_frame

	if is_multiplayer_authority():
		health_component.died.connect(_on_died)
		state_machine.set_initial_state(state_spawn)
		hurtbox_component.hit.connect(_on_hurtbox_hit)
		attack_timer.timeout.connect(_on_attack_timer_timeout)
	
func _process(_delta: float) -> void:
	state_machine.update()
	if is_multiplayer_authority():
		move_and_slide()
	
func enter_state_spawn():
	var tween := create_tween()
	tween.tween_property(visuals, "scale", Vector2.ONE, .4)\
		.from(Vector2.ZERO)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_BACK)
		
	tween.finished.connect(func(): 
		state_machine.change_state(state_normal)
	)
	
func state_spawn():
	pass
	
func enter_state_normal():
	animation_player.play("run")
	if is_multiplayer_authority():
		acquire_target()
		target_timer.start()
	
func state_normal():
	if is_multiplayer_authority():
		velocity = global_position.direction_to(target_position) * speed
		
		if target_timer.is_stopped():
			acquire_target()
			target_timer.start()
		
		var distance_to_target = global_position.distance_to(target_position) 
		var can_attack := attack_cooldown_timer.is_stopped() or distance_to_target < 16
		if can_attack and distance_to_target < attack_agent.get_attack_distance():
			state_machine.change_state(state_charge_attack)
		
	flip()
	
func leave_state_normal():
	animation_player.play("RESET")
	
func enter_state_charge_attack():
	if is_multiplayer_authority():
		acquire_target()
		charge_attack_timer.start()
		
	attack_agent.enter_state_charge_attack()
		
	if alert_tween != null and alert_tween.is_valid():
		alert_tween.kill()
		
	alert_tween = create_tween()
	alert_tween.tween_property(alert_sprite, "scale", Vector2.ONE, .2)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TransitionType.TRANS_BACK)

func state_charge_attack():
	if is_multiplayer_authority():
		velocity = velocity.lerp(Vector2.ZERO, 1.0 - exp(-15 * get_process_delta_time()))
		if charge_attack_timer.is_stopped():
			state_machine.change_state(state_attack)
	
	flip()
	
func leave_state_charge_attack():
	if alert_tween != null and alert_tween.is_valid():
		alert_tween.kill()
		
	alert_tween = create_tween()
	alert_tween.tween_property(alert_sprite, "scale", Vector2.ZERO, .2)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TransitionType.TRANS_BACK)
	
func enter_state_attack():
	if is_multiplayer_authority():
		collision_mask = 1 << 0
		collision_layer = 0
		hitbox_collision_shape.disabled = false
		
		attack_agent.enter_state_attack()

func state_attack():
	if is_multiplayer_authority():
		attack_agent.state_attack()
	
func leave_state_attack():
	if is_multiplayer_authority():
		collision_mask = default_collision_mask
		collision_layer = default_collision_layer
		hitbox_collision_shape.disabled = true
		attack_cooldown_timer.start()
	
	attack_agent.leave_state_attack()
	
func flip():
	visuals.scale = Vector2.ONE if global_position.x < target_position.x\
		else Vector2(-1, 1)
		
func get_direction_to_target() -> Vector2:
	acquire_target()
	return global_position.direction_to(target_position)
	
func acquire_target():
	var players = get_tree().get_nodes_in_group("player")
	var nearest_player: Player = null
	var nearest_squared_distance: float
	
	for player in players:
		if nearest_player == null:
			nearest_player = player
			nearest_squared_distance = nearest_player.global_position.distance_squared_to(global_position)
			continue
		
		var player_squared_distance: float = player.global_position.distance_squared_to(global_position)
		if player_squared_distance < nearest_squared_distance:
			nearest_squared_distance = player_squared_distance
			nearest_player = player
		
	if nearest_player != null:
		target_position = nearest_player.global_position
	
@rpc("authority", "call_local")
func spawn_hit_effects():
	hit_stream_player.play()
	var hit_particles: Node2D = impact_particles_scene.instantiate()
	hit_particles.global_position = hurtbox_component.global_position
	get_parent().add_child(hit_particles)

@rpc("authority", "call_local")
func spawn_death_particles():
	var death_particles: Node2D = ground_particles_scene.instantiate()
	
	var background_node: Node = Main.background_mask
	if not is_instance_valid(background_node):
		background_node = get_parent()
	
	background_node.add_child(death_particles)
	death_particles.global_position = global_position
	
func update_sprite_frame(frame: int):
	enemy_sprite.frame = frame
	
func emit_attack_shot():
	attack_shot.emit()
	
func _on_died():
	spawn_death_particles.rpc()
	GameEvents.emit_enemy_died()
	queue_free()

func _on_hurtbox_hit():
	spawn_hit_effects.rpc()

func _on_attack_timer_timeout():
	current_attack_count += 1
	if current_attack_count > attack_count:
		state_machine.change_state(state_normal)
		current_attack_count = 0
	
