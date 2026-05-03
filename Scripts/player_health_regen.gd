extends Node

@export var health_component: HealthComponent

@onready var timer: Timer = $Timer

func _ready() -> void:
	if is_multiplayer_authority():
		timer.timeout.connect(_on_timer_timeout)
		health_component.damaged.connect(_on_health_damaged)
	
	timer.start()

func regen_health():
	if health_component.current_health >= health_component.max_health:
		timer.start()
	
	health_component.heal(1)
	
func _on_timer_timeout():
	regen_health()
	
func _on_health_damaged():
	timer.start()
