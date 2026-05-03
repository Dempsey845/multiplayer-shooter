extends Node

const BASE_HEALTH_REGEN_RATE: float = 5.0
const UPGRADE_RATE_INCRASE_AMOUNT: float = 0.1
const MIN_REGEN_RATE: float = 0.5

@export var health_component: HealthComponent
@export var player_input_synchronizer_component: PlayerInputSynchronizerComponent

@onready var timer: Timer = $Timer

func _ready() -> void:
	if is_multiplayer_authority():
		timer.timeout.connect(_on_timer_timeout)
		health_component.damaged.connect(_on_health_damaged)
	
	timer.start()

func get_regen_rate() -> float:
	var player_peer_id = player_input_synchronizer_component.get_multiplayer_authority()
	
	var rate_upgrade_count := UpgradeManager.get_peer_upgrade_count(player_peer_id, "health_regen_rate")
	
	var regen_rate = BASE_HEALTH_REGEN_RATE *\
		(1 - (UPGRADE_RATE_INCRASE_AMOUNT * rate_upgrade_count))

	regen_rate = max(regen_rate, MIN_REGEN_RATE)
	
	return regen_rate

func regen_health():
	if health_component.current_health >= health_component.max_health:
		timer.start()
	
	health_component.heal(1)
	timer.start()
	
func _on_timer_timeout():
	timer.wait_time = get_regen_rate()
	regen_health()
	
func _on_health_damaged():
	timer.start()
