class_name HealthComponent
extends Node

signal died
signal died_by(peer_id: int)
signal damaged
signal health_changed(current_health: int, max_health: int)

@export var max_health: int = 1

var _current_health: int
var current_health: int:
	get:
		return _current_health
	set(value):
		_current_health = value
		health_changed.emit(_current_health, max_health)

func _ready() -> void:
	current_health = max_health

func damage(amount: int, hit_by: int = -1):
	current_health = clamp(current_health - amount, 0, max_health)
	damaged.emit()
	if current_health == 0:
		died.emit()
		if hit_by > 0:
			died_by.emit(hit_by)

func heal(amount: int):
	current_health = clamp(current_health + amount, 0, max_health)

func set_max_health(new_max_health: int):
	max_health = new_max_health
	current_health = max_health
