extends Weapon

@onready var punch_stream_player: AudioStreamPlayer = %PunchStreamPlayer
@onready var punch_cooldown_timer: Timer = %PunchCooldownTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hand_hitbox_component: HitboxComponent = %HandHitboxComponent
@onready var hand_point: Marker2D = %HandPoint
@onready var hand_sprite: Sprite2D = %HandSprite

var can_punch: bool = true

func _ready() -> void:
	hand_hitbox_component.monitorable = false
	set_source_peer_id.call_deferred()

func set_source_peer_id():
	if is_multiplayer_authority():
		hand_hitbox_component.source_peer_id = player_input_synchronizer_component.get_multiplayer_authority()

func _process(_delta: float) -> void:
	if is_multiplayer_authority():
		if not can_punch and player_input_synchronizer_component.is_attack_released:
			can_punch = true

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

@rpc("authority", "call_local", "unreliable")
func play_punch_effects():
	if weapon_animation_player.is_playing():
		weapon_animation_player.stop()
	weapon_animation_player.play("attack")
	
	if animation_player.is_playing():
		animation_player.stop()
	animation_player.play("punch")
	
	if player_input_synchronizer_component.is_multiplayer_authority():
		GameCamera.shake(0.5)
	
	punch_stream_player.play()

func attack():
	super()
	try_punch()
