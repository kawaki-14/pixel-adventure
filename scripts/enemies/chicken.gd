extends "res://scripts/enemies/enemies_base.gd"

@export var max_sight_distance: float = 500.0
@export var chase_speed: float = 350.0

@onready var vision_ray: RayCast2D = $PlayerDetector

var player: Node2D = null
var is_chasing: bool = false

func _ready() -> void:
	SPEED = 0.0
	_find_player()
	
	# Exclude self and child CollisionObject2D nodes (Area2D/HurtBox/HitBox)
	if vision_ray:
		vision_ray.add_exception(self)
		for child in get_children():
			if child is CollisionObject2D:
				vision_ray.add_exception(child)

func _find_player() -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	# Stop patrolling
	is_waiting = false
	if has_node("WaitTimer"):
		$WaitTimer.stop()
		
	super._physics_process(delta)

func _custom_physics_process(_delta: float) -> void:
	_find_player()
	if not is_instance_valid(player):
		SPEED = 0.0
		return
		
	_check_line_of_sight()
	
	if is_chasing:
		SPEED = chase_speed
		if player.global_position.x > global_position.x:
			direction = 1
		else:
			direction = -1
	else:
		SPEED = 0.0

func _check_line_of_sight() -> void:
	var to_player = player.global_position - global_position
	var distance = to_player.length()
	
	if distance > max_sight_distance:
		is_chasing = false
		return
		
	vision_ray.target_position = vision_ray.to_local(player.global_position)
	vision_ray.force_raycast_update()
	
	if vision_ray.is_colliding():
		var collider = vision_ray.get_collider()
		
		if _is_player_node(collider):
			if not is_chasing and $AttackSound:
				$AttackSound.play()
			is_chasing = true
		else:
			is_chasing = false
	else:
		is_chasing = false

# Helper function to trace player hierarchy
func _is_player_node(node: Node) -> bool:
	if not node:
		return false
	if node == player or node.is_in_group("player"):
		return true
	if node.owner and (node.owner == player or node.owner.is_in_group("player")):
		return true
	if node.get_parent() and (node.get_parent() == player or node.get_parent().is_in_group("player")):
		return true
	return false
