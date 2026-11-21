@tool
extends Node2D

signal player_died

enum TrapMode { PENDULUM, ROTATE_FULL }

@export_category("Trap Settings")
@export var mode: TrapMode = TrapMode.PENDULUM

@export_group("Chain & Length")
@export var chain_length: float = 120.0:
	set(value):
		chain_length = max(0.0, value)
		_update_chain_length()

@export_group("Pendulum Mode")
@export var max_angle_degrees: float = 60.0
@export var swing_speed: float = 2.0

@export_group("Rotate Full Mode")
@export var rotate_speed: float = 180.0

@export_group("Offset")
@export var start_delay: float = 0.0

var _time: float = 0.0

func _ready() -> void:
	_time = start_delay
	_update_chain_length()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
		
	_time += delta
	
	match mode:
		TrapMode.PENDULUM:
			rotation_degrees = sin(_time * swing_speed) * max_angle_degrees
		TrapMode.ROTATE_FULL:
			rotation_degrees += rotate_speed * delta

func _update_chain_length() -> void:
	if not is_instance_valid($Chain) or not is_instance_valid($Hitbox):
		return
	
	$Chain.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	$Chain.region_enabled = true
	
	if $Chain.texture:
		var tex_width: float = $Chain.texture.get_width()
		$Chain.region_rect = Rect2(0, 0, tex_width, chain_length)
		$Chain.offset = Vector2(-tex_width / 2.0, 0)
	
	$Hitbox.position = Vector2(0, chain_length)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_died.emit()
		body.die()
