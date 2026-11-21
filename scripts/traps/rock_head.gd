extends CharacterBody2D

@export var speed: float = 500.0
@export var direction: Vector2 = Vector2.UP

var hit_left_direction: Vector2 = Vector2.RIGHT
var hit_right_direction: Vector2 = Vector2.LEFT
var hit_top_direction: Vector2 = Vector2.DOWN
var hit_bottom_direction: Vector2 = Vector2.UP

var is_waiting: bool = false

func _physics_process(delta: float) -> void:
	if is_waiting:
		velocity = Vector2.ZERO
		return
	
	velocity = direction * speed
	move_and_slide()
	
	if get_slide_collision_count() > 0:
		var collision = get_slide_collision(0)
		var normal = collision.get_normal()
		
		if normal.x < -0.7: # Hits RIGHT wall
			direction = hit_right_direction
			_start_hit_sequence("right_hit")
		elif normal.x > 0.7: # Hits LEFT wall
			direction = hit_left_direction
			_start_hit_sequence("left_hit")
		elif normal.y < -0.7: # Hits BOTTOM wall
			direction = hit_bottom_direction
			_start_hit_sequence("bottom_hit")
		elif normal.y > 0.7: # Hits TOP wall
			direction = hit_top_direction
			_start_hit_sequence("top_hit")

func _start_hit_sequence(hit_animation: String):
	is_waiting = true
	velocity = Vector2.ZERO
	SignalBus.camera_shake_requested.emit(0.2)
	
	$HitSound.play()
	
	$AnimatedSprite2D.play(hit_animation)
	await $AnimatedSprite2D.animation_finished
	
	$AnimatedSprite2D.play("blink")
	$WaitTimer.start()

func _on_wait_timer_timeout() -> void:
	$AnimatedSprite2D.play("default")
	is_waiting = false

func _on_hit_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.die()
