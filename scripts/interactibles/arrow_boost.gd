extends Area2D

var launch_force: float = 1000.0
var disable_control_time: float = 0.2

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Get direction based on the arrow's rotation
		var launch_direction: Vector2 = Vector2.UP.rotated(global_rotation)
		
		body.launch(launch_direction * launch_force, disable_control_time)
		
		SignalBus.camera_shake_requested.emit(0.25)
		$AnimatedSprite2D.play("hit")
		await $AnimatedSprite2D.animation_finished
		
		queue_free()
