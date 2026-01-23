extends Node
## Test microgame loading from registry (simulates framework behavior)

func _ready():
	print("\n=== REGISTRY INTEGRATION TEST ===\n")
	
	# Simulate what boot.gd does
	var registry = MicrogameRegistry.new()
	registry.register_microgame(
		"ignore_the_expert",
		"res://microgames/mg01_ignore_the_expert/MicrogameIgnoreTheExpert.tscn",
		2,
		"Ignore The Expert"
	)
	
	print("✓ Registry created")
	
	# Get the entry
	var entry = registry.get_entry_by_id("ignore_the_expert")
	if entry:
		print("✓ Entry found: " + entry.display_name)
		print("  Scene path: " + entry.scene_path)
		print("  Weight: " + str(entry.weight))
	else:
		print("✗ Entry not found!")
		get_tree().quit()
		return
	
	# Load the scene
	var scene = load(entry.scene_path)
	if scene:
		print("✓ Scene loaded from registry path")
	else:
		print("✗ Failed to load scene")
		get_tree().quit()
		return
	
	# Instantiate and test
	var mg = scene.instantiate()
	add_child(mg)
	print("✓ Microgame instantiated from registry")
	
	# Start it
	mg.start_microgame({"rng_seed": 999, "presentation_enabled": false})
	print("✓ Microgame started successfully")
	
	# Verify it can be resolved
	var resolved = false
	mg.resolved.connect(func(outcome):
		resolved = true
		var outcome_str = "SUCCESS" if outcome == 0 else "FAIL"
		print("✓ Microgame resolved: " + outcome_str)
		print("\n=== REGISTRY INTEGRATION: ALL TESTS PASSED ===\n")
	)
	
	mg.force_resolve(0)
	
	await get_tree().create_timer(0.1).timeout
	
	get_tree().quit()
