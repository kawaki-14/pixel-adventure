extends "res://scripts/enemies/enemies_base.gd"

@export var shoot_interval: float = 0.2

@onready var projectile: PackedScene = preload("res://scenes/enemies/trunk_projectile.tscn")
@onready var shoot_timer: float = shoot_interval 
var is_shooting: bool = false 

func _custom_physics_process(delta: float) -> void:
	# Flip PlayerDetector and Muzzle
	if direction == -1:
		$PlayerDetector.target_position.x = -abs($PlayerDetector.target_position.x)
		$Muzzle.position.x = -abs($Muzzle.position.x)
	elif direction == 1:
		$PlayerDetector.target_position.x = abs($PlayerDetector.target_position.x)
		$Muzzle.position.x = abs($Muzzle.position.x)
	
	if is_hurt or is_waiting or is_shooting:
		is_attacking = true 
		return
	
	$PlayerDetector.force_raycast_update()
	
	if $PlayerDetector.is_colliding():
		var collider = $PlayerDetector.get_collider()
		if collider and collider.is_in_group("player"):
			is_attacking = true 
			$AnimatedSprite2D.play("idle")
			
			shoot_timer += delta
			if shoot_timer >= shoot_interval:
				shoot_timer = 0.0
				shoot()
			return 
			
	is_attacking = false
	shoot_timer = shoot_interval 

func shoot() -> void:
	if projectile == null:
		return
		
	is_shooting = true
	
	$AnimatedSprite2D.play("attack")
	await $AnimatedSprite2D.animation_finished
	
	$AttackSound.play()
	
	if is_hurt:
		is_shooting = false
		return

	var bullet = projectile.instantiate()
	
	bullet.global_position = $Muzzle.global_position
	bullet.direction = Vector2(direction, 0)
	
	get_tree().current_scene.add_child(bullet)
	
	is_shooting = false
