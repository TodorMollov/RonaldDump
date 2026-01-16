extends Node
## Test the MicrogameBase adapter for Ignore The Expert

func _ready():
	print("\n=== ADAPTER TEST ===\n")
	
	# Test 1: Load adapter scene
	var scene = load("res://microgames/mg01_ignore_the_expert/MicrogameIgnoreTheExpertAdapter.tscn")
	if scene:
		print("✓ Adapter scene loaded")
	else:
		print("✗ Failed to load adapter scene")
		get_tree().quit()
		return
	
	# Test 2: Instantiate
	var mg = scene.instantiate()
	add_child(mg)
	print("✓ Adapter instantiated")
	
	# Test 3: Check it's a MicrogameBase
	if mg is MicrogameBase:
		print("✓ Adapter is MicrogameBase")
	else:
		print("✗ Adapter is not MicrogameBase")
		get_tree().quit()
		return
	
	# Test 4: Check instruction text
	var instruction = mg.get_instruction_text()
	print("✓ Instruction text: " + instruction)
	
	# Test 5: Check input policy
	var policy = mg.get_input_policy()
	if policy:
		print("✓ Input policy exists")
	else:
		print("✗ Input policy is null")
	
	# Test 6: Connect resolved signal
	var resolved = false
	var success = false
	mg.resolved.connect(func(s):
		resolved = true
		success = s
		print("✓ Resolved signal emitted: " + ("SUCCESS" if s else "FAILURE"))
	)
	
	# Test 7: Activate
	mg.on_activate()
	print("✓ on_activate() called")
	
	await get_tree().create_timer(0.1).timeout
	
	# Test 8: Start active phase
	mg.on_active_start()
	print("✓ on_active_start() called")
	
	# Test 9: Send input (should trigger success)
	await get_tree().create_timer(0.5).timeout
	var actions = [InputRouter.Action.CONFIRM]
	mg.on_input(actions)
	
	# Wait for resolution
	await get_tree().create_timer(0.2).timeout
	
	if not resolved:
		# Force end to trigger resolution
		mg.on_active_end()
		await get_tree().create_timer(0.1).timeout
	
	# Test 10: Check result
	if mg.is_resolved():
		print("✓ Microgame resolved")
		print("  Result: " + str(mg.get_result()))
	else:
		print("✗ Microgame not resolved")
	
	# Test 11: Deactivate
	mg.on_deactivate()
	print("✓ on_deactivate() called")
	
	print("\n=== ADAPTER TEST COMPLETE ===\n")
	get_tree().quit()
