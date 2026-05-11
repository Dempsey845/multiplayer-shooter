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
	
	if peer_id_to_enemies_killed[peer_id] > 5:
		unlock_gun_for(peer_id)

func unlock_gun_for(peer_id: int):
	if not is_multiplayer_authority():
		return
	
	PeerConditionManager.instance.add_peer_condition(peer_id, PeerConditionManager.PeerCondition.HasUnlockedGun)

	var players = get_tree().get_nodes_in_group("player")
	
	var player_to_unlock: Player
	
	for player: Player in players:
		if player.name == str(peer_id):
			player_to_unlock = player
			
	player_to_unlock.unlock_gun()

func _on_enemy_died_by(peer_id: int):
	if peer_id <= 0:
		return
		
	add_peer_kill(peer_id)
