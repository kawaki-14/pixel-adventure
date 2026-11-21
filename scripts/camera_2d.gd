extends Camera2D

# Max shake in pixels at full trauma
var max_shake = 24.0
# How fast the trauma falls back to 0
var trauma_decay = 2.0

# 0 = still, 1 = full shake; Hits add trauma, decay each frames
var trauma = 0.0

func _ready() -> void:
	SignalBus.camera_shake_requested.connect(_add_trauma)

func _process(delta: float) -> void:
	# Fade the shake out over time
	trauma = maxf(trauma - trauma_decay * delta, 0.0)
	if trauma == 0.0:
		offset = Vector2.ZERO
		return
	var random_offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
	offset = random_offset * trauma * max_shake

func _add_trauma(amount: float):
	if amount <= 0.0:
		return
	# Stack trauma so rapid hits shake harder but never past full shake
	trauma = clampf(trauma + amount, 0.0, 1.0)
