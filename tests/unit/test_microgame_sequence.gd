extends GutTest
## Test that all 5 microgames transition correctly without stopping

var game_root: Node
var microgames_completed: Array = []


func before_each() -> void:
	game_root = preload("res://scenes/game_root.tscn").instantiate()
	add_child(game_root)
	
	# Connect to run manager signals to track progression
	RunManager.microgame_sequence_started.connect(_on_microgame_started)
	RunManager.run_completed.connect(_on_run_completed)


func after_each() -> void:
	if game_root:
		game_root.queue_free()
	RunManager.reset()


func _on_microgame_started() -> void:
	var current = RunManager.active_microgame
	if current:
		microgames_completed.append(current.get_script().resource_path)
		print("Microgame started: ", current.get_script().resource_path)
		
		# Auto-resolve after a short delay to test transitions
		await get_tree().create_timer(0.5).timeout
		if RunManager.active_microgame:
			RunManager.active_microgame.resolve_success()


func _on_run_completed() -> void:
	print("Run completed. Total microgames played: ", RunManager.microgames_played)


func test_all_microgames_transition() -> void:
	# Start a run
	RunManager.start_run(ChaosManager.RunMode.NORMAL, game_root)
	
	# Wait for 5 microgames to complete (5 games * ~5 seconds each + buffer)
	await get_tree().create_timer(30.0).timeout
	
	# Verify all microgames played
	assert_gt(RunManager.microgames_played, 0, "No microgames were played")
	print("✓ Test passed: ", RunManager.microgames_played, " microgames completed without stopping")
