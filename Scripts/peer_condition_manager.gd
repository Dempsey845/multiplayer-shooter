class_name PeerConditionManager
extends Node

enum PeerCondition
{
	HasUnlockedGun
}

var peer_id_to_peer_conditions: Dictionary[int, Array] # peer_id: Array[PeerCondition]

static var instance: PeerConditionManager

func _ready() -> void:
	instance = self

func add_peer_condition(peer_id: int, peer_condition: PeerCondition):
	if not is_multiplayer_authority():
		return
	
	if not peer_id_to_peer_conditions.has(peer_id):
		peer_id_to_peer_conditions[peer_id] = []
		
	var conditions: Array = peer_id_to_peer_conditions[peer_id]
	
	if conditions.has(peer_condition):
		return
		
	peer_id_to_peer_conditions[peer_id].append(peer_condition)

func does_peer_have_condition(peer_id: int, peer_condition: PeerCondition) -> bool:
	if not peer_id_to_peer_conditions.has(peer_id):
		return false
		
	return peer_id_to_peer_conditions[peer_id].has(peer_condition)
