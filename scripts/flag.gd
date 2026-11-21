extends Area2D

signal level_completed

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		$CollisionShape2D.set_deferred("disabled", true)
		SignalBus.camera_shake_requested.emit(0.25)
		_player_reached(body)
		
		$AnimatedSprite2D.play("flag_up")
		$ActivatedSound.play()
		
		await $AnimatedSprite2D.animation_finished
		if $ActivatedSound.playing:
			await $ActivatedSound.finished
		
		$AnimatedSprite2D.play("flag_idle")
		
		#Send signal to main
		level_completed.emit()

func _player_reached(body: CharacterBody2D):
	if body.has_method("checkpoint_reached"):
		body.checkpoint_reached()
