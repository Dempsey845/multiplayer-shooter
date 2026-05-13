extends Node

var bullet: Bullet

var electricity_chain_scene: PackedScene = preload("uid://cc74sjccipfo7")
var electric_hit_effect_scene: PackedScene = preload("uid://c12qa23obhfma")

func _ready() -> void:
	bullet = get_parent()
	
	bullet.hit_hurtbox.connect(_on_hit_hurtbox)

func _on_hit_hurtbox(hurtbox_component: HurtboxComponent):
	if not is_instance_valid(bullet):
		return
	
	var electricity_chain = electricity_chain_scene.instantiate() as ElectricityChain
	electricity_chain.target_group_name = "enemy"
	electricity_chain.start_target = hurtbox_component
	electricity_chain.source_peer_id = bullet.source_peer_id
	
	var electric_hit_effect = electric_hit_effect_scene.instantiate()
	electric_hit_effect.global_position = bullet.global_position
	
	get_tree().current_scene.add_child(electric_hit_effect)
	get_tree().current_scene.add_child(electricity_chain)
