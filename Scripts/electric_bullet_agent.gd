extends Node

var bullet: Bullet

var electricity_chain_scene: PackedScene = preload("uid://cc74sjccipfo7")

func _ready() -> void:
	if is_multiplayer_authority():
		bullet = get_parent()
		bullet.hit_hurtbox.connect(_on_hit_hurtbox)

func _on_hit_hurtbox(hurtbox_component: HurtboxComponent):
	if hurtbox_component.health_component.current_health > 0:
		var electricity_chain = electricity_chain_scene.instantiate()
		electricity_chain.target_group_name = "enemy"
		electricity_chain.start_target = hurtbox_component
		get_tree().current_scene.add_child(electricity_chain)
