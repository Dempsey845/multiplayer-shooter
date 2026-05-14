class_name WeaponManager
extends Node

@export var player: Player
@export var player_input_synchronizer_component: PlayerInputSynchronizerComponent

@onready var weapon_root: Node2D = %WeaponRoot
@onready var weapon_animation_player: AnimationPlayer = %WeaponAnimationPlayer
@onready var weapon_animation_root: Node2D = $WeaponRoot/WeaponAnimationRoot

var _current_weapon_type: Weapon.Type
var current_weapon_type: Weapon.Type:
	get():
		return _current_weapon_type
	set(value):
		_change_weapon(value)

var start_weapon_type := Weapon.Type.Hand

@onready var weapons: Dictionary[Weapon.Type, Weapon] =\
	{
		Weapon.Type.Hand: %PunchHand,
		Weapon.Type.Banana: %BananaThrow,
		Weapon.Type.Gun: %Gun,
		Weapon.Type.ElectricGun: %ElectricGun,
	}

func _ready() -> void:
	player_input_synchronizer_component.set_aim_room(weapon_root)
	
	for type in weapons:
		weapons[type].visible = false
		weapons[type].setup\
		(
			type,
			player_input_synchronizer_component, 
			player, 
			weapon_animation_player
		)
		
	current_weapon_type = start_weapon_type
	
func _process(_delta: float) -> void:
	update_aim_position()
	
	if is_multiplayer_authority():
		if player_input_synchronizer_component.is_attack_pressed:
			attack()

func update_aim_position():
	var aim_vector = player_input_synchronizer_component.aim_vector
	var aim_position = weapon_root.global_position + aim_vector
	
	weapon_root.look_at(aim_position)

func _change_weapon(new_weapon_type: Weapon.Type):
	weapons[current_weapon_type].visible = false
	weapons[new_weapon_type].visible = true
	_current_weapon_type = new_weapon_type

func attack():
	weapons[current_weapon_type].attack()
