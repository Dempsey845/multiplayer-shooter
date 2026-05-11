class_name PlayerInputSynchronizerComponent
extends MultiplayerSynchronizer

var aim_root: Node2D

var movement_vector := Vector2.ZERO
var aim_vector := Vector2.RIGHT
var is_attack_pressed: bool
var is_attack_released: bool = true

func _process(_delta: float) -> void:
	if is_multiplayer_authority():
		gather_input()
	
func set_aim_room(new_aim_root: Node2D):
	aim_root = new_aim_root
	
func gather_input():
	if not aim_root:
		return
	
	movement_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	aim_vector = aim_root.global_position.direction_to(aim_root.get_global_mouse_position())
	is_attack_pressed = Input.is_action_pressed("attack")
	is_attack_released = not is_attack_pressed
