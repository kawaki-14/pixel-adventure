@tool
extends StaticBody2D

# Wind velocity vector in local space
@export var wind_velocity: Vector2 = Vector2(0, -250):
	set(value):
		_remove_wind_from_all_bodies()
		wind_velocity = value
		_update_wind_particles()
		_apply_wind_to_all_bodies()

# Wind area dimensions
@export var wind_size: Vector2 = Vector2(32, 128):
	set(value):
		wind_size = value
		_update_wind_shape()
		_update_wind_particles()

@export var initial_wait_time: float = 0.0

# Active state of the fan
@export var is_on: bool = false:
	set(value):
		var state_changed = (is_on != value)
		is_on = value
		_update_fan_visuals_and_physics(state_changed)

var bodies_in_area: Array[Node2D] = []

func _ready() -> void:
	_update_wind_shape()
	_update_wind_particles()
	
	if Engine.is_editor_hint():
		_set_particles_emitting(true)
		return
		
	# Apply initial state at runtime
	_update_fan_visuals_and_physics(true)
	
	if initial_wait_time > 0:
		await get_tree().create_timer(initial_wait_time).timeout
	
	is_on = true
	$Timer.start()

func get_global_wind_velocity() -> Vector2:
	return wind_velocity.rotated(global_rotation)

func _update_wind_shape() -> void:
	if not is_inside_tree():
		return
	
	var shape_node = get_node_or_null("WindArea/CollisionShape2D")
	if shape_node:
		if not shape_node.shape or not shape_node.shape.resource_local_to_scene:
			shape_node.shape = RectangleShape2D.new()
			shape_node.shape.resource_local_to_scene = true
		
		if shape_node.shape is RectangleShape2D:
			shape_node.shape.size = wind_size
			shape_node.position = Vector2(0, -wind_size.y / 2.0)

# Synchronize particle properties dynamically with wind_size and wind_velocity
func _update_wind_particles() -> void:
	if not is_inside_tree():
		return
		
	var particles = get_node_or_null("WindArea/GPUParticles2D") as GPUParticles2D
	if not particles:
		return
		
	var mat = particles.process_material as ParticleProcessMaterial
	if not mat:
		return
		
	# Update emission box width
	mat.emission_box_extents = Vector3(wind_size.x / 2.0, 1.0, 0.0)
	
	# Dynamic visibility rect to avoid viewport culling
	particles.visibility_rect = Rect2(Vector2(-wind_size.x / 2.0, -wind_size.y), wind_size)
	
	var speed = wind_velocity.length()
	if speed > 0:
		mat.initial_velocity_min = speed
		mat.initial_velocity_max = speed
		
		# Calculate lifetime based on height
		particles.lifetime = wind_size.y / speed
		
		# Scale particle amount based on area density
		var default_area: float = 32.0 * 128.0
		var current_area: float = wind_size.x * wind_size.y
		particles.amount = max(10, int(30.0 * (current_area / default_area)))
		
		# Set movement direction in local space
		var dir_normalized = wind_velocity.normalized()
		mat.direction = Vector3(dir_normalized.x, dir_normalized.y, 0.0)

func _set_particles_emitting(emitting_state: bool) -> void:
	var particles = get_node_or_null("WindArea/GPUParticles2D") as GPUParticles2D
	if particles:
		particles.emitting = emitting_state

func _update_fan_visuals_and_physics(state_changed: bool) -> void:
	if not is_inside_tree():
		return
		
	if Engine.is_editor_hint():
		_set_particles_emitting(true)
		return
	
	# Sync particle emission with fan state
	_set_particles_emitting(is_on)
	
	# Update animation and physics velocities
	var anim = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if is_on:
		if anim and anim.sprite_frames and anim.sprite_frames.has_animation("on"):
			anim.play("on")
		if state_changed:
			_apply_wind_to_all_bodies()
	else:
		if anim and anim.sprite_frames and anim.sprite_frames.has_animation("off"):
			anim.play("off")
		if state_changed:
			_remove_wind_from_all_bodies()

func _apply_wind_to_all_bodies() -> void:
	if not is_on:
		return
	var global_wind = get_global_wind_velocity()
	for body in bodies_in_area:
		if "manipulated_velocity" in body:
			body.manipulated_velocity += global_wind

func _remove_wind_from_all_bodies() -> void:
	var global_wind = get_global_wind_velocity()
	for body in bodies_in_area:
		if "manipulated_velocity" in body:
			body.manipulated_velocity -= global_wind

func _on_wind_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not bodies_in_area.has(body):
		bodies_in_area.append(body)
		if is_on and "manipulated_velocity" in body:
			body.manipulated_velocity += get_global_wind_velocity()

func _on_wind_area_body_exited(body: Node2D) -> void:
	if bodies_in_area.has(body):
		bodies_in_area.erase(body)
		if is_on and "manipulated_velocity" in body:
			body.manipulated_velocity -= get_global_wind_velocity()

func _on_timer_timeout() -> void:
	is_on = !is_on
