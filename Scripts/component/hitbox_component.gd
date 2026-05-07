class_name HitboxComponent
extends Area2D

signal hit_hurtbox(hurtbox_component: HurtboxComponent)

var damage: int = 1
var source_peer_id: int
var is_hit_handled: bool

func register_hurtbox_hit(hurtbox_component: HurtboxComponent):
	hit_hurtbox.emit(hurtbox_component)

func check_area_for_hurtbox():
	var overlapping_areas := get_overlapping_areas()
	if overlapping_areas.size() > 0:
		for area in overlapping_areas:
			if area is HurtboxComponent:
				area._on_area_entered(self)
