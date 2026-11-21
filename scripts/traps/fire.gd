extends StaticBody2D

var fire_duration = 2.0
var fire_delay = 0.15
var is_active = false

func _ready() -> void:
	# Disable hitbox
	$HitBox/HitboxCollision.set_deferred("disabled", true)

func _on_hurt_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_active:
		is_active = true
		
		$Start.play()
		
		$AnimatedSprite2D.play("hit")
		await $AnimatedSprite2D.animation_finished
		await get_tree().create_timer(fire_delay).timeout
		
		$AnimatedSprite2D.play("on")
		$HitBox/HitboxCollision.set_deferred("disabled", false)
		await get_tree().create_timer(fire_duration).timeout
		
		$AnimatedSprite2D.play("off")
		$HitBox/HitboxCollision.set_deferred("disabled", true)
		is_active = false

func _on_hit_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.die()
