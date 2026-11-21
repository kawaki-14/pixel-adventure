extends CharacterBody2D

@export var SPEED = 200.0
@export var JUMP_VELOCITY = -700.0
@export var direction = -1
var is_waiting = false
var is_hurt = false
var is_attacking = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if is_hurt:
		velocity.x = 0
		move_and_slide()
		return
	
	if is_waiting:
		velocity.x = 0
		$AnimatedSprite2D.play("idle")
		move_and_slide()
		return
	
	# Sprite facing direction
	if direction == -1:
		$AnimatedSprite2D.flip_h = false
	elif direction == 1:
		$AnimatedSprite2D.flip_h = true
	
	_custom_physics_process(delta)
	if is_attacking:
		velocity.x = 0
		move_and_slide()
		return
	
	# Handle Moving and Animation
	velocity.x = direction * SPEED
	if velocity.x != 0 and is_hurt == false:
		$AnimatedSprite2D.play("run")
	elif velocity.x == 0 and is_hurt == false:
		$AnimatedSprite2D.play("idle")
	
	move_and_slide()
	
	# Check if hit wall or near edge
	$EdgeChecker.force_raycast_update()
	if is_on_wall() or not $EdgeChecker.is_colliding():
		is_waiting = true
		$WaitTimer.start()


# Virtual Hook: Mặc định ở script cha không làm gì cả
# Quái con muốn làm thêm cơ chế gì thì ghi đè (override) hàm này
func _custom_physics_process(_delta: float) -> void:
	pass


# When hit wall/near edge, waits for 1.5s then redirect
func _on_wait_timer_timeout() -> void:
	direction *= -1
	$EdgeChecker.position.x *= -1
	is_waiting = false

# Handle hurt
func _on_hurt_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_hurt = true
		SignalBus.camera_shake_requested.emit(0.25)
		
		$AnimatedSprite2D.play("hit")
		$DeathSound.play()
		
		body.player_launch()
		
		$HurtBox.set_deferred("monitoring", false)
		$HitBox.set_deferred("monitoring", false)
		
		await $AnimatedSprite2D.animation_finished
		queue_free()

# Handle hit
func _on_hit_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.die()
