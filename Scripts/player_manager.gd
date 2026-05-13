class_name PlayerManager
extends Node

var peer_id_to_enemies_killed: Dictionary[int, int]

var peer_id_to_weapons_unlocked: Dictionary[int, Array]
var weapon_type_to_peer_conditions: Dictionary[Weapon.Type, Array] =\
	{
		Weapon.Type.Banana: [],
		Weapon.Type.Gun: [PeerConditionManager.PeerCondition.HasUnlockedGun]
	}

func _ready() -> void:
	GameEvents.enemy_died_by.connect(_on_enemy_died_by)

func add_peer_kill(peer_id: int):
	if not is_multiplayer_authority():
		return
		
	if not peer_id_to_enemies_killed.has(peer_id):
		peer_id_to_enemies_killed[peer_id] = 0

	peer_id_to_enemies_killed[peer_id] += 1
	
	print("Player kill count: %s" % peer_id_to_enemies_killed[peer_id])
	
	if peer_id_to_enemies_killed[peer_id] >= 20:
		unlock_weapon_for(peer_id, Weapon.Type.Banana)
	if peer_id_to_enemies_killed[peer_id] >= 30:
		unlock_weapon_for(peer_id, Weapon.Type.Gun)

func has_peer_unlocked_weapon(peer_id: int, weapon_type: Weapon.Type) -> bool:
	if not peer_id_to_weapons_unlocked.has(peer_id):
		peer_id_to_weapons_unlocked[peer_id] = []
		return false
		
	return peer_id_to_weapons_unlocked[peer_id].has(weapon_type)

func unlock_weapon_for(peer_id: int, weapon_type: Weapon.Type):
	if not is_multiplayer_authority():
		return
	
	if has_peer_unlocked_weapon(peer_id, weapon_type):
		return
	
	for condition: PeerConditionManager.PeerCondition in weapon_type_to_peer_conditions[weapon_type]:
		PeerConditionManager.instance.add_peer_condition(peer_id, condition)
	
	var players = get_tree().get_nodes_in_group("player")
	var player_to_unlock: Player
	
	for player: Player in players:
		if player.name == str(peer_id):
			player_to_unlock = player
	
	if is_instance_valid(player_to_unlock):
		player_to_unlock.unlock_weapon(weapon_type)

func _on_enemy_died_by(peer_id: int):
	if peer_id <= 0:
		return
		
	add_peer_kill(peer_id)
