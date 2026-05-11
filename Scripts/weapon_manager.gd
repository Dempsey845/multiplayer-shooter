class_name WeaponManager
extends Node

enum Weapon
{
	Hand,
	Banana,
	Gun
}

@export var player: Player
@export var player_input_synchronizer_component: PlayerInputSynchronizerComponent

@onready var weapon_root: Node2D = %WeaponRoot
@onready var hand_hitbox_component: HitboxComponent = %HandHitboxComponent
@onready var weapon_animation_player: AnimationPlayer = %WeaponAnimationPlayer
@onready var barrel_position: Marker2D = %BarrelPosition
@onready var hand_point: Marker2D = %HandPoint
@onready var hand_sprite: Sprite2D = %HandSprite
@onready var gun_sprite: Sprite2D = %GunSprite
@onready var banana_sprite: Sprite2D = %BananaSprite
@onready var banana_visuals: Node2D = %BananaVisuals

@onready var fire_rate_timer: Timer = %FireRateTimer
@onready var throw_banana_timer: Timer = $ThrowBananaTimer
@onready var gun_stream_player: AudioStreamPlayer = %GunStreamPlayer
@onready var punch_stream_player: AudioStreamPlayer = %PunchStreamPlayer
@onready var punch_cooldown_timer: Timer = %PunchCooldownTimer

var bullet_scene: PackedScene = preload("uid://drkduhc11ouid")
var muzzle_flash_scene: PackedScene = preload("uid://b6xpqkeu8aqs8")
var banana_scene: PackedScene = preload("uid://ddnk0hlort2s1")

const BASE_FIRE_RATE: float = 0.25
const BASE_BULLET_DAMAGE: int = 1

var can_punch := true
var _current_weapon: Weapon
var current_weapon: Weapon:
	get():
		return _current_weapon
	set(value):
		_change_weapon(value)

var start_weapon := Weapon.Banana

func _ready() -> void:
	hand_hitbox_component.monitorable = false
	
	set_source_peer_id.call_deferred()
	
	current_weapon = start_weapon
	
	player_input_synchronizer_component.set_aim_room(weapon_root)
	
func set_source_peer_id():
	if is_multiplayer_authority():
		hand_hitbox_component.source_peer_id = player_input_synchronizer_component.get_multiplayer_authority()

func _process(_delta: float) -> void:
	update_aim_position()
	
	if is_multiplayer_authority():
		if player_input_synchronizer_component.is_attack_pressed:
			attack()
			
		if not can_punch and player_input_synchronizer_component.is_attack_released:
			can_punch = true

func update_aim_position():
	var aim_vector = player_input_synchronizer_component.aim_vector
	var aim_position = weapon_root.global_position + aim_vector
	
	weapon_root.look_at(aim_position)

func _change_weapon(new_weapon: Weapon):
	var previous_weapon = current_weapon
	_current_weapon = new_weapon
	
	match previous_weapon:
		Weapon.Hand:
			hand_sprite.visible = false
		Weapon.Banana:
			banana_visuals.visible = false
		Weapon.Gun:
			gun_sprite.visible = false
		
	match new_weapon:
		Weapon.Hand:
			hand_sprite.visible = true
		Weapon.Banana:
			banana_visuals.visible = true
		Weapon.Gun:
			gun_sprite.visible = true

func try_punch():
	if not punch_cooldown_timer.is_stopped() or not can_punch:
		return
	
	hand_hitbox_component.damage = get_damage()
	
	can_punch = false
	
	hand_hitbox_component.monitorable = true
	hand_hitbox_component.global_position = hand_point.global_position
	
	hand_hitbox_component.check_area_for_hurtbox()
	play_punch_effects.rpc()
	
	punch_cooldown_timer.start()
	
	await weapon_animation_player.animation_finished
	hand_hitbox_component.monitorable = false

func try_throw_banana():
	if not throw_banana_timer.is_stopped():
		return
	
	var banana = banana_scene.instantiate() as Bullet
	banana.damage = get_damage()
	banana.source_peer_id = player_input_synchronizer_component.get_multiplayer_authority()
	banana.global_position = barrel_position.global_position
	banana.start(player_input_synchronizer_component.aim_vector)
	player.get_parent().add_child(banana, true)
	
	throw_banana_timer.start()
	
	play_throw_banana_effects.rpc()
	

func get_fire_rate() -> float:
	var fire_rate_count := UpgradeManager.get_peer_upgrade_count(
		player_input_synchronizer_component.get_multiplayer_authority(),
		"fire_rate"
	)
	
	const MIN_FIRE_RATE := 0.05
	return max(BASE_FIRE_RATE * (1 - (.1 * fire_rate_count)), MIN_FIRE_RATE)
	
func get_damage() -> int:
	var damage_count := UpgradeManager.get_peer_upgrade_count(
		player_input_synchronizer_component.get_multiplayer_authority(),
		"damage"
	)
	
	return BASE_BULLET_DAMAGE + damage_count

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

@rpc("authority", "call_local", "unreliable")
func play_throw_banana_effects():
	if weapon_animation_player.is_playing():
		weapon_animation_player.stop()
	weapon_animation_player.play("attack")
	
	var tween := create_tween()

	tween.tween_property(
		banana_sprite,
		"scale",
		Vector2.ZERO,
		0.2,
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	tween.tween_property(
		banana_sprite,
		"scale",
		Vector2.ONE,
		0.8
	).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


@rpc("authority", "call_local", "unreliable")
func play_punch_effects():
	if weapon_animation_player.is_playing():
		weapon_animation_player.stop()
	weapon_animation_player.play("attack")
	
	if player_input_synchronizer_component.is_multiplayer_authority():
		GameCamera.shake(0.5)
	
	punch_stream_player.play()


func attack():
	match current_weapon:
		Weapon.Hand:
			try_punch()
		Weapon.Banana:
			try_throw_banana()
		Weapon.Gun:
			try_fire()
