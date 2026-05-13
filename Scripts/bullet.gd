class_name Bullet
extends Node2D

signal hit_hurtbox(hurtbox_component: HurtboxComponent)

@export var speed: int = 600

@onready var life_timer: Timer = $LifeTimer
@onready var hitbox_component: HitboxComponent = $HitboxComponent

var move_direction: Vector2
var source_peer_id: int
var damage: int = 1

func _ready() -> void:
	hitbox_component.damage = damage
	hitbox_component.source_peer_id = source_peer_id
	hitbox_component.hit_hurtbox.connect(_on_hit_hurtbox)
	life_timer.timeout.connect(_on_life_timer_timeout)

func _process(delta: float) -> void:
	global_position += move_direction * speed * delta

func start(direction: Vector2):
	move_direction = direction
	rotation = direction.angle()

func register_collision():
	hitbox_component.is_hit_handled = true
	queue_free()

func _on_life_timer_timeout():
	# The server should only queue multiplayer objects (since MultiplayerSpawner handles despawns)
	if is_multiplayer_authority():
		queue_free()

func _on_hit_hurtbox(hurtbox_component: HurtboxComponent):
	hit_hurtbox.emit(hurtbox_component)
	register_collision()
