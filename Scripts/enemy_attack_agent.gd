class_name EnemyAttackAgent
extends Node

@export var enemy: Enemy

func get_attack_distance() -> float:
	match enemy.enemy_resource.attack_type:
		Enemy.AttackType.ChargeAndDash:
			return 150.0
		Enemy.AttackType.ChargeAndShoot:
			return 250.0
			
	return 50.0

func enter_state_attack():
	if is_multiplayer_authority():
		match enemy.enemy_resource.attack_type:
			Enemy.AttackType.ChargeAndDash:
				enemy.velocity = enemy.global_position.direction_to(enemy.target_position) * enemy.DASH_ATTACK_SPEED
			Enemy.AttackType.ChargeAndShoot:
				enemy.enemy_sprite.scale = Vector2.ONE
				enemy.attack_timer.start()

func enter_state_charge_attack():
	match enemy.enemy_resource.attack_type:
		Enemy.AttackType.ChargeAndDash:
			enemy.animation_player.play("start_charge")
		Enemy.AttackType.ChargeAndShoot:
			enemy.animation_player.play("start_shoot_charge")

func state_attack():
	match enemy.enemy_resource.attack_type:
		Enemy.AttackType.ChargeAndDash:
			enemy.velocity = enemy.velocity.lerp(Vector2.ZERO, 1.0 - exp(-3 * get_process_delta_time()))
			if enemy.velocity.length() < 25:
				enemy.state_machine.change_state(enemy.state_normal)
		Enemy.AttackType.ChargeAndShoot:
			enemy.flip()
			if enemy.attack_timer.is_stopped():
				enemy.emit_attack_shot()
				enemy.attack_timer.start()

func leave_state_attack():
	match enemy.enemy_resource.attack_type:
		Enemy.AttackType.ChargeAndShoot:
			enemy.enemy_sprite.frame = enemy.enemy_resource.start_frame
