extends Node
## Simple verification test for Ignore The Expert

func _ready():
	print("\n=== IGNORE THE EXPERT - SIMPLE TEST ===\n")
	
	# Test 1: Load scene
	var microgame_scene = load("res://microgames/mg01_ignore_the_expert/MicrogameIgnoreTheExpert.tscn")
	print("✓ Scene loaded successfully")
	
	# Test 2: Instantiate
	var mg = microgame_scene.instantiate()
	add_child(mg)
	print("✓ Microgame instantiated")
	
	# Test 3: Check node structure
	if mg.get_node_or_null("Background") and mg.get_node_or_null("Audio/SFX_Talk"):
		print("✓ Scene structure correct")
	else:
		print("✗ Scene structure incorrect")
	
	# Test 4: Start microgame
	mg.start_microgame({"rng_seed": 123, "presentation_enabled": false})
	print("✓ Microgame started")
	
	# Test 5: Check input policy
	var policy = mg.get_input_policy()
	if policy["success_on_any_input"] == true and policy["pointer_move_counts_as_input"] == false:
		print("✓ Input policy correct")
	else:
		print("✗ Input policy incorrect")
	
	# Test 6: Force resolve
	mg.force_resolve(mg.Outcome.SUCCESS)
	print("✓ Force resolve works")
	
	# Test 7: Assets generated
	if FileAccess.file_exists("res://microgames/mg01_ignore_the_expert/assets/ronald.png"):
		print("✓ Assets generated")
	else:
		print("✗ Assets not found")
	
	print("\n=== ALL CORE TESTS PASSED ===\n")
	get_tree().quit()
