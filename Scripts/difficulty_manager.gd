class_name DifficultyManager
extends Node

const BASE_ENEMY_MAX_HEALTH: int = 3
const ROUNDS_PER_ENEMY_MAX_HEALTH_INCREMENT: int = 2

const BASE_ENEMY_CHARGE_TIME := 0.5
const ENEMY_CHARGE_TIME_DECREMENT := 0.025
const ROUNDS_PER_CHARGE_TIME_DECREMENT: int = 2
const MIN_ENEMY_CHARGE_TIME := 0.1

const BASE_ATTACK_COOLDOWN := 4.0
const ATTACK_COOLDOWN_DECREMENT := 0.08
const ROUNDS_PER_ATTACK_COOLDOWN_DECREMENT: int = 1
const MIN_ATTACK_COOLDOWN := 1.0

@export var enemy_manager: EnemyManager

func _ready() -> void:
	if is_multiplayer_authority():
		enemy_manager.round_changed.connect(_on_round_changed)
		
func _on_round_changed(round_number: int):
	if round_number <= 0:
		return
	
	var max_health_increment = floori(round_number / float(ROUNDS_PER_ENEMY_MAX_HEALTH_INCREMENT))
	enemy_manager.enemy_max_health = BASE_ENEMY_MAX_HEALTH + max_health_increment
	
	var charge_time_decrement = round_number / float(ROUNDS_PER_CHARGE_TIME_DECREMENT) * ENEMY_CHARGE_TIME_DECREMENT
	enemy_manager.charge_duration = max(BASE_ENEMY_CHARGE_TIME - charge_time_decrement, MIN_ENEMY_CHARGE_TIME)
	
	var attack_cooldown_decrement = round_number / float(ROUNDS_PER_ATTACK_COOLDOWN_DECREMENT) * ATTACK_COOLDOWN_DECREMENT
	enemy_manager.attack_cooldown_duration = max(BASE_ATTACK_COOLDOWN - attack_cooldown_decrement, MIN_ATTACK_COOLDOWN)
