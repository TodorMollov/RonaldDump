extends Node
## Test to verify microgame duration meets specifications

func _ready():
	print("\n=== DURATION SPECIFICATION TEST ===\n")
	print("Spec: 3.5-4.5s randomized, target avg ~4.0s, hard cap 5.0s\n")
	
	# Test 1: Load adapter
	var scene = load("res://microgames/mg01_ignore_the_expert/MicrogameIgnoreTheExpertAdapter.tscn")
	var mg = scene.instantiate()
	add_child(mg)
	print("✓ Adapter loaded")
	
	# Test multiple instantiations to check duration randomization
	var durations = []
	for i in range(10):
		var test_scene = load("res://microgames/mg01_ignore_the_expert/MicrogameIgnoreTheExpert.tscn")
		var test_mg = test_scene.instantiate()
		add_child(test_mg)
		
		# Start with default params (should randomize duration)
		test_mg.start_microgame({
			"rng_seed": randi(),
			"presentation_enabled": false
		})
		
		var duration = test_mg._get_total_duration_for_tests()
		durations.append(duration)
		
		test_mg.queue_free()
	
	# Calculate statistics
	var min_duration = durations.min()
	var max_duration = durations.max()
	var avg_duration = 0.0
	for d in durations:
		avg_duration += d
	avg_duration /= durations.size()
	
	print("\nDuration Statistics from 10 runs:")
	print("  Min: %.2fs" % min_duration)
	print("  Max: %.2fs" % max_duration)
	print("  Avg: %.2fs" % avg_duration)
	
	# Validate against spec
	var all_valid = true
	
	if min_duration < 3.5:
		print("✗ FAIL: Min duration %.2fs is below 3.5s" % min_duration)
		all_valid = false
	else:
		print("✓ Min duration >= 3.5s")
	
	if max_duration > 5.0:
		print("✗ FAIL: Max duration %.2fs exceeds hard cap of 5.0s" % max_duration)
		all_valid = false
	else:
		print("✓ Max duration <= 5.0s (hard cap)")
	
	if max_duration > 4.5:
		print("⚠ WARNING: Max duration %.2fs exceeds target range of 4.5s" % max_duration)
	else:
		print("✓ Max duration <= 4.5s (target range)")
	
	if avg_duration < 3.8 or avg_duration > 4.2:
		print("⚠ WARNING: Avg duration %.2fs is outside ideal range (3.8-4.2s)" % avg_duration)
	else:
		print("✓ Avg duration ~4.0s (target)")
	
	if all_valid:
		print("\n=== DURATION TEST PASSED ===\n")
	else:
		print("\n=== DURATION TEST FAILED ===\n")
	
	get_tree().quit()
