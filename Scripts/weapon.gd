class_name Weapon
extends Node2D

const BASE_DAMAGE: int = 1

enum Type
{
	Hand,
	Banana,
	Gun
}

var weapon_type: Type
var player_input_synchronizer_component: PlayerInputSynchronizerComponent
var player: Player
var weapon_animation_player: AnimationPlayer

var has_setup: bool

func setup(type: Type,
	plr_input_synchronizer_component: PlayerInputSynchronizerComponent,
	plr: Player,
	animation_player: AnimationPlayer
):
	weapon_type = type
	player_input_synchronizer_component = plr_input_synchronizer_component
	player = plr
	weapon_animation_player = animation_player
	
	has_setup = true

func attack():
	if not has_setup:
		push_error("Trying to attack with a weapon that has not setup()!")

func get_damage() -> int:
	var damage_count := UpgradeManager.get_peer_upgrade_count(
		player_input_synchronizer_component.get_multiplayer_authority(),
		"damage"
	)
	
	return BASE_DAMAGE + damage_count
