extends CharacterBody2D

enum State { NORMAL, SHELL_IDLE, SHELL_MOVING }

@export var SPEED: float = 70.0
@export var SHELL_SPEED: float = 600.0
var direction: int = -1
var current_state: State = State.NORMAL
var is_waiting: bool = false
var is_dead: bool = false
var kick_cooldown: float = 0.0

func _ready() -> void:
	# EdgeChecker position
	if direction == 1:
		$EdgeChecker.position.x = abs($EdgeChecker.position.x)
	else:
		$EdgeChecker.position.x = -abs($EdgeChecker.position.x)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# Decrease kick cooldown timer
	if kick_cooldown > 0:
		kick_cooldown -= delta
	
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	
	# Update velocity & animation
	match current_state:
		State.NORMAL:
			_process_normal_state()
		State.SHELL_IDLE:
			velocity.x = 0
			_process_shell_idle_state()
		State.SHELL_MOVING:
			velocity.x = direction * SHELL_SPEED
	
	move_and_slide()
	
	# Continuously check HitBox overlaps
	_check_hit_box_overlaps()
	
	# Handle wall bounce
	if current_state == State.SHELL_MOVING:
		if is_on_wall():
			# If hits player
			var hit_player_as_wall: bool = false
			for i in get_slide_collision_count():
				var collision = get_slide_collision(i)
				var collider = collision.get_collider()
				if collider and collider.is_in_group("player"):
					hit_player_as_wall = true
					if kick_cooldown <= 0 and collider.has_method("die"):
						collider.die()
					break
			
			# Only bounce off actual terrain
			if not hit_player_as_wall:
				$WallHitSound.play()
				direction *= -1
				velocity.x = direction * SHELL_SPEED
				global_position.x += direction * 2.0
				$AnimatedSprite2D.play("shell_wall_hit")
		elif $AnimatedSprite2D.animation != "shell_wall_hit" or not $AnimatedSprite2D.is_playing():
			$AnimatedSprite2D.play("shell_idle")

func _check_hit_box_overlaps() -> void:
	if is_dead:
		return
		
	for body in $HitBox.get_overlapping_bodies():
		if body.is_in_group("player"):
			if current_state == State.NORMAL:
				if body.has_method("die"):
					body.die()
			elif current_state == State.SHELL_MOVING and kick_cooldown <= 0:
				if body.has_method("die"):
					body.die()

func _process_normal_state() -> void:
	if is_waiting:
		velocity.x = 0
		$AnimatedSprite2D.play("idle")
		return
	
	velocity.x = direction * SPEED
	$AnimatedSprite2D.play("run")
	$AnimatedSprite2D.flip_h = (direction == 1)
	
	$EdgeChecker.force_raycast_update()
	if is_on_wall() or not $EdgeChecker.is_colliding():
		is_waiting = true
		velocity.x = 0
		$WaitTimer.start()

func _process_shell_idle_state() -> void:
	if $AnimatedSprite2D.animation == "hit" and $AnimatedSprite2D.is_playing():
		return
	
	if $AnimatedSprite2D.animation != "shell_idle":
		$AnimatedSprite2D.play("shell_idle")

func _on_wait_timer_timeout() -> void:
	if current_state == State.NORMAL and is_waiting:
		direction *= -1
		$EdgeChecker.position.x *= -1
		is_waiting = false

func _on_hurt_box_body_entered(body: Node2D) -> void:
	if is_dead or not body.is_in_group("player"):
		return
	
	match current_state:
		State.NORMAL:
			if body.has_method("player_launch"):
				body.player_launch()
				$DeathSound.play()
			
			current_state = State.SHELL_IDLE
			is_waiting = false
			$WaitTimer.stop()
			$AnimatedSprite2D.play("hit")
	
		State.SHELL_IDLE, State.SHELL_MOVING:
			if body.has_method("player_launch"):
				body.player_launch()
				$DeathSound.play()
			_die()

func _on_hit_box_body_entered(body: Node2D) -> void:
	if is_dead:
		return
	
	if body.is_in_group("player"):
		if current_state == State.SHELL_IDLE:
			var kick_dir: int = 0
			
			if "velocity" in body and body.velocity.x != 0:
				kick_dir = 1 if body.velocity.x > 0 else -1
			elif body.has_node("AnimatedSprite2D"):
				var player_anim = body.get_node("AnimatedSprite2D")
				kick_dir = -1 if player_anim.flip_h else 1
			
			if kick_dir == 0:
				kick_dir = 1 if global_position.x > body.global_position.x else -1
			
			direction = kick_dir
			current_state = State.SHELL_MOVING
			
			# Prevent instant death on kick
			kick_cooldown = 0.25
			global_position.x += direction * 4.0
			$AnimatedSprite2D.play("shell_idle")
			
		elif current_state == State.NORMAL or (current_state == State.SHELL_MOVING and kick_cooldown <= 0):
			if body.has_method("die"):
				body.die()

	elif current_state == State.SHELL_MOVING and body != self:
		if body.is_in_group("enemies") or body.has_method("_on_hurt_box_body_entered"):
			if body.has_method("_on_hurt_box_body_entered"):
				body._on_hurt_box_body_entered(self)
			elif body.has_method("queue_free"):
				body.queue_free()

func _die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	
	if typeof(SignalBus) != TYPE_NIL and SignalBus.has_signal("camera_shake_requested"):
		SignalBus.camera_shake_requested.emit(0.25)
		
	if has_node("DeathSound"):
		$DeathSound.play()

	$AnimatedSprite2D.play("shell_top_hit")
	$HurtBox.set_deferred("monitoring", false)
	$HitBox.set_deferred("monitoring", false)
	$CollisionShape2D.set_deferred("disabled", true)

	await $AnimatedSprite2D.animation_finished
	queue_free()
