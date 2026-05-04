extends Node

@export var enemy: Enemy

@onready var fire_point: Marker2D = $FirePoint

var enemy_projectile_scene := preload("uid://c4mlnoajfb8qe")

func _ready() -> void:
	if is_multiplayer_authority():
		enemy.attack_shot.connect(_on_attack_shot)
	
func shoot_projectile_at_target():
	var enemy_projectile = enemy_projectile_scene.instantiate() as Bullet
	enemy_projectile.global_position = fire_point.global_position
	
	var direction := enemy.get_direction_to_target()
	var spread_angle = randf_range(-0.2, 0.2) 
	direction = direction.rotated(spread_angle)
	
	enemy_projectile.start(direction)
	enemy.get_parent().add_child(enemy_projectile, true)
	
func _on_attack_shot():
	shoot_projectile_at_target()
