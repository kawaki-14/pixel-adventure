extends AnimatableBody2D

var is_falling = false
@onready var initial_pos = position

func _process(delta: float) -> void:
	if is_falling:
		$CollisionShape2D.set_deferred("disabled", true)
		position += get_gravity() * delta

func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_falling:
		$AnimatedSprite2D.play("off")
		$Timer.start()
		_shake_entire_platform()

func _shake_entire_platform() -> void:
	var tween = create_tween()
	var shake_intensity = 2.0
	var shake_speed = 0.04
	
	var loops = int($Timer.wait_time / (shake_speed * 2))
	
	for i in range(loops):
		# Shakes the platform in both axes
		var offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		tween.tween_property(self, "position", initial_pos + offset, shake_speed)
		tween.tween_property(self, "position", initial_pos, shake_speed)

func _on_timer_timeout() -> void:
	is_falling = true
	$Pop.play()
	position = initial_pos
