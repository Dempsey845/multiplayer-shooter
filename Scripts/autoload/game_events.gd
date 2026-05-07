extends Node

signal enemy_died
signal enemy_died_by(peer_id: int)

func emit_enemy_died():
	enemy_died.emit()

func emit_enemy_died_by(peer_id: int):
	enemy_died_by.emit(peer_id)
