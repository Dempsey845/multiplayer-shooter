class_name PlayerManager
extends Node

var peer_id_to_enemies_killed: Dictionary[int, int]

func _ready() -> void:
	GameEvents.enemy_died_by.connect(_on_enemy_died_by)

func add_peer_kill(peer_id: int):
	if not is_multiplayer_authority():
		return
		
	if not peer_id_to_enemies_killed.has(peer_id):
		peer_id_to_enemies_killed[peer_id] = 0

	peer_id_to_enemies_killed[peer_id] += 1

func _on_enemy_died_by(peer_id: int):
	if peer_id <= 0:
		return
		
	add_peer_kill(peer_id)
