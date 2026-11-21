extends StaticBody2D

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		SignalBus.camera_shake_requested.emit(0.25)
		$AnimatedSprite2D.play("on")
		body.trampoline_launch()
