extends Node2D

@onready var fade: ColorRect = $HUD/Fade

const path_begin = "res://scenes/levels/level"
var current_level_root: Node = null
var level: int = 6
var score: int = 0

func _ready() -> void:
	#$BGM.play()
	fade.modulate.a = 1.0
	current_level_root = get_node("LevelRoot")
	await _load_level(level, true)
	

# Level management

func _load_level(level_number, first_load: bool) -> void:
	# Fade out
	if not first_load:
		await _fade(1.0)
	
	# Delete the current level
	if current_level_root:
		current_level_root.queue_free()
	
	# Change level
	var level_path = "res://scenes/levels/level%s.tscn" % level_number
	if ResourceLoader.exists(level_path):
		current_level_root = load(level_path).instantiate()
		add_child(current_level_root)
		current_level_root.name = "LevelRoot"
		_setup_level(current_level_root)
	else:
		print("Cannot find level path")
	
	# Fade in
	await _fade(0.0)

func _setup_level(level_root: Node) -> void:
	# Connect Flag
	var flag = level_root.get_node_or_null("Flag")
	if flag and flag.has_signal("level_completed"):
		flag.level_completed.connect(_on_flag_entered)
	
	# Connect Collectibles
	var collectibles = level_root.get_node_or_null("Collectibles")
	if collectibles:
		for collectible in collectibles.get_children():
			if collectible.has_signal("collected"):
				collectible.collected.connect(_increase_score)
	
	# Connect Player
	var player = level_root.get_node_or_null("Player")
	if player and player.has_signal("player_died"):
		player.player_died.connect(_on_player_died)

# Signal handlers
func _on_flag_entered() -> void:
	level += 1
	score = 0
	
	print("Level " + str(level))
	await _load_level(level, false)

func _increase_score() -> void:
	score += 1
	print(score)

func _on_player_died() -> void:
	score = 0
	await get_tree().create_timer(1.5).timeout
	await _load_level(level, false)

# Transition handlers
func _fade(to_progress: float) -> void:
	if not fade.material or not fade.material is ShaderMaterial:
		return

	var tween := create_tween()
	var mat = fade.material as ShaderMaterial
	
	tween.tween_property(mat, "shader_parameter/progress", to_progress, 0.75).set_trans(Tween.TRANS_SINE)
	await tween.finished
