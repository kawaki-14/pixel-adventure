extends CharacterBody2D

signal player_died

const SPEED = 300.0
const ACCELERATION = 3750.0
const JUMP_VELOCITY = -850.0
var jumps_left = 0
var launch_timer: float = 0.0
var manipulated_velocity: Vector2
var is_killed = false
var was_on_floor = true
var reached_checkpoint = false
var is_launched = false


func _physics_process(delta: float) -> void:
	# Handle dead
	if is_killed:
		velocity.x = 0
		velocity.y = 0
		$RunDustParticles.emitting = false
		move_and_slide()
		return
	
	# Handle checkpoint
	if reached_checkpoint:
		velocity.x = 0
		$RunDustParticles.emitting = false
		move_and_slide()
		return
	
	# Handle launch by arrows
	if is_launched:
		launch_timer -= delta
		if launch_timer <= 0:
			is_launched = false
		move_and_slide()
		return
	
	# On floor animation
	if velocity.x != 0 and is_on_floor(): 
		$AnimatedSprite2D.play("run")
	else: $AnimatedSprite2D.play("idle")
	
	# Add the gravity and jump animations
	if not is_on_floor():
		velocity += get_gravity() * delta
		# When in fans' area, disable gravity
		if manipulated_velocity.y:
			velocity.y = 0
		
		if velocity.y > 0:
			$AnimatedSprite2D.play("fall")
		elif jumps_left == 1:
			$AnimatedSprite2D.play("jump")
		elif jumps_left == 0:
			$AnimatedSprite2D.play("double_jump")
	else:
		jumps_left = 2
	
	# Handle landing dust particles 
	if is_on_floor() and not was_on_floor:
		$LandingDustParticlesL.restart()
		$LandingDustParticlesR.restart()
	was_on_floor = is_on_floor()
	
	# Handle jump and jump dust particles
	if Input.is_action_just_pressed("jump"):
		if jumps_left == 2:
			jumps_left -= 1
			velocity.y = JUMP_VELOCITY
			$JumpDustParticles.restart()
			$JumpSound.play()
		elif jumps_left == 1:
			jumps_left -= 1
			velocity.y = JUMP_VELOCITY * 0.75
			$JumpDustParticles.restart()
			$JumpSound.play()
	
	# Get the input direction and handle the movement/deceleration
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	# Handle dust particals when running
	$RunDustParticles.emitting = is_on_floor() and velocity.x != 0
	
	# Facing animation & Particles flipping
	if direction == 1:
		$AnimatedSprite2D.flip_h = false
		$RunDustParticles.position.x = -8
		$RunDustParticles.scale.x = 1
		$JumpDustParticles.scale.x = 1
	elif direction == -1: 
		$AnimatedSprite2D.flip_h = true
		$RunDustParticles.position.x = 8
		$RunDustParticles.scale.x = -1
		$JumpDustParticles.scale.x = -1
	
	# Handle velocity when in fans' area
	velocity += manipulated_velocity
	
	move_and_slide()

func die() -> void:
	if is_killed: return
	is_killed = true
	
	SignalBus.camera_shake_requested.emit(0.5)
	
	$AnimatedSprite2D.play("hit")
	$DeathSound.play()
	
	$CollisionShape2D.set_deferred("disabled", true)
	
	await $AnimatedSprite2D.animation_finished
	if $DeathSound.playing:
		await $DeathSound.finished
	
	player_died.emit()
	
	queue_free()

func _on_animated_sprite_2d_animation_finished() -> void:
	pass # Replace with function body.

func player_launch():
	velocity.y = -850.0
	$JumpDustParticles.restart()

func checkpoint_reached():
	reached_checkpoint = true
	$AnimatedSprite2D.play("disappearing")
	await $AnimatedSprite2D.animation_finished
	
	queue_free()

func trampoline_launch():
	velocity.y = -850.0 * 1.75
	$JumpDustParticles.restart()
	$JumpSound.play()

func launch(impulse: Vector2, duration: float) -> void:
	velocity = impulse
	is_launched = true
	launch_timer = duration
	$JumpSound.play()
