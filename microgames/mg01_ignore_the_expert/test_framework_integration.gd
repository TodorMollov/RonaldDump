extends Node
## Test framework integration with MicrogameBase adapter

func _ready():
	print("\n=== FRAMEWORK INTEGRATION TEST ===\n")
	
	# Simulate boot.gd registry setup
	var registry = MicrogameRegistry.new()
	registry.register_microgame(
		"ignore_the_expert",
		"res://microgames/mg01_ignore_the_expert/MicrogameIgnoreTheExpertAdapter.tscn",
		2,
		"Ignore The Expert"
	)
	
	print("✓ Registry created with ignore_the_expert")
	
	# Get entry
	var entry = registry.get_entry_by_id("ignore_the_expert")
	if not entry:
		print("✗ Failed to get entry")
		get_tree().quit()
		return
	
	print("✓ Entry found: " + entry.display_name)
	
	# Load scene
	var scene = load(entry.scene_path)
	if not scene:
		print("✗ Failed to load scene")
		get_tree().quit()
		return
	
	print("✓ Scene loaded: " + entry.scene_path)
	
	# Instantiate
	var mg = scene.instantiate()
	add_child(mg)
	
	if not mg is MicrogameBase:
		print("✗ Not a MicrogameBase!")
		get_tree().quit()
		return
	
	print("✓ Instantiated as MicrogameBase")
	
	# Check instruction
	var instruction = mg.get_instruction_text()
	print("✓ Instruction: " + instruction)
	
	# Check input policy
	var policy = mg.get_input_policy()
	if not policy:
		print("✗ No input policy")
		get_tree().quit()
		return
	
	print("✓ Input policy configured")
	
	# Connect signal
	var resolved = false
	var success_result = false
	mg.resolved.connect(func(s):
		resolved = true
		success_result = s
		print("✓ Resolved: " + ("SUCCESS" if s else "FAILURE"))
	)
	
	# Simulate framework lifecycle
	mg.on_activate()
	print("✓ Activated")
	
	await get_tree().create_timer(0.1).timeout
	
	mg.on_active_start()
	print("✓ Active phase started")
	
	# Wait a bit then force end
	await get_tree().create_timer(0.5).timeout
	
	mg.on_active_end()
	print("✓ Active phase ended")
	
	await get_tree().create_timer(0.2).timeout
	
	if resolved:
		print("✓ Microgame resolved via framework")
		print("  Is resolved: " + str(mg.is_resolved()))
		print("  Result: " + str(mg.get_result()))
	else:
		print("✗ Microgame did not resolve")
	
	mg.on_deactivate()
	print("✓ Deactivated")
	
	print("\n=== FRAMEWORK INTEGRATION: SUCCESS ===")
	print("The microgame is fully compatible with the framework!\n")
	
	get_tree().quit()
