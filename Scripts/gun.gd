extends Weapon

const BASE_FIRE_RATE: float = 0.25

@onready var fire_rate_timer: Timer = %FireRateTimer
@onready var gun_stream_player: AudioStreamPlayer = %GunStreamPlayer
@onready var barrel_position: Marker2D = %BarrelPosition

var bullet_scene: PackedScene = preload("uid://drkduhc11ouid")
var muzzle_flash_scene: PackedScene = preload("uid://b6xpqkeu8aqs8")

func try_fire():
	if not fire_rate_timer.is_stopped():
		return
	
	var bullet = bullet_scene.instantiate() as Bullet
	bullet.damage = get_damage()
	bullet.source_peer_id = player_input_synchronizer_component.get_multiplayer_authority()
	bullet.global_position = barrel_position.global_position
	bullet.start(player_input_synchronizer_component.aim_vector)
	player.get_parent().add_child(bullet, true)
	
	fire_rate_timer.wait_time = get_fire_rate()
	fire_rate_timer.start()
	
	play_fire_effects.rpc()

func get_fire_rate() -> float:
	var fire_rate_count := UpgradeManager.get_peer_upgrade_count(
		player_input_synchronizer_component.get_multiplayer_authority(),
		"fire_rate"
	)
	
	const MIN_FIRE_RATE := 0.05
	return max(BASE_FIRE_RATE * (1 - (.1 * fire_rate_count)), MIN_FIRE_RATE)
	
	
@rpc("authority", "call_local", "unreliable")
func play_fire_effects():
	if weapon_animation_player.is_playing():
		weapon_animation_player.stop()
	weapon_animation_player.play("attack")
	
	var muzzle_flash: Node2D = muzzle_flash_scene.instantiate()
	muzzle_flash.global_position = barrel_position.global_position
	muzzle_flash.rotation = barrel_position.global_rotation
	player.get_parent().add_child(muzzle_flash)
	
	if player_input_synchronizer_component.is_multiplayer_authority():
		GameCamera.shake(1.0)
	
	gun_stream_player.play()

func attack():
	super()
	try_fire()
