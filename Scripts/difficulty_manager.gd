class_name DifficultyManager
extends Node

const BASE_ENEMY_MAX_HEALTH: int = 3
const ROUNDS_PER_ENEMY_MAX_HEALTH_INCREMENT: int = 2

@export var enemy_manager: EnemyManager

func _ready() -> void:
	if is_multiplayer_authority():
		enemy_manager.round_changed.connect(_on_round_changed)
		
func _on_round_changed(round_number: int):
	var max_health_increment = floori(round_number / float(ROUNDS_PER_ENEMY_MAX_HEALTH_INCREMENT))
	enemy_manager.enemy_max_health = BASE_ENEMY_MAX_HEALTH + max_health_increment
