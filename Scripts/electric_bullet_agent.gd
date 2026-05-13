extends Node

var bullet: Bullet

var electricity_chain_scene: PackedScene = preload("uid://cc74sjccipfo7")
var electric_hit_effect_scene: PackedScene = preload("uid://c12qa23obhfma")

func _ready() -> void:
	bullet = get_parent()
	if is_multiplayer_authority():
		bullet.hit_hurtbox.connect(_on_hit_hurtbox)

func _on_hit_hurtbox(hurtbox_component: HurtboxComponent):
	if not is_instance_valid(bullet):
		return
	
	spawn_electric_hit_effects.rpc(bullet.global_position)
	spawn_electricity_chain.rpc(hurtbox_component.global_position, bullet.source_peer_id)

@rpc("authority", "call_local", "reliable")
func spawn_electricity_chain(start_target_position: Vector2, source_peer_id: int):
	var electricity_chain = electricity_chain_scene.instantiate() as ElectricityChain
	electricity_chain.target_group_name = "enemy"
	electricity_chain.start_target_position = start_target_position
	electricity_chain.source_peer_id = source_peer_id
	get_tree().current_scene.add_child(electricity_chain, true)

@rpc("authority", "call_local", "unreliable")
func spawn_electric_hit_effects(spawn_position: Vector2):
	var electric_hit_effect = electric_hit_effect_scene.instantiate()
	electric_hit_effect.global_position = spawn_position
	
	get_tree().current_scene.add_child(electric_hit_effect, true)
