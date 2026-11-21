extends Area2D

signal collected

func _ready() -> void:
	# Randomize each collectibles' speed
	$AnimatedSprite2D.speed_scale = randf_range(0.9, 1.0)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Send signal to main
		collected.emit()
		
		# Play sound & animations then delete
		$AnimatedSprite2D.play("collected")
		$CollisionShape2D.set_deferred("disabled", true)
		$CollectedSound.play()
		await $AnimatedSprite2D.animation_finished
		if $CollectedSound.playing:
			await $CollectedSound.finished
		
		queue_free()
