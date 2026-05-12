extends Weapon

@onready var throw_banana_timer: Timer = $ThrowBananaTimer
@onready var banana_position: Marker2D = %BananaPosition
@onready var banana_visuals: Node2D = %BananaVisuals
@onready var banana_sprite: Sprite2D = %BananaSprite

var banana_scene: PackedScene = preload("uid://ddnk0hlort2s1")

func try_throw_banana():
	if not throw_banana_timer.is_stopped():
		return
	
	var banana = banana_scene.instantiate() as Bullet
	banana.damage = get_damage()
	banana.source_peer_id = player_input_synchronizer_component.get_multiplayer_authority()
	banana.global_position = banana_position.global_position
	banana.start(player_input_synchronizer_component.aim_vector)
	player.get_parent().add_child(banana, true)
	
	throw_banana_timer.start()
	
	play_throw_banana_effects.rpc()
	
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

func attack():
	super()
	try_throw_banana()
