extends GutTest
## Tests for framework-level microgame duration specification

func test_duration_constants():
	assert_eq(GlobalTimingController.MICROGAME_DURATION_MIN, 3.5, "Min should be 3.5s")
	assert_eq(GlobalTimingController.MICROGAME_DURATION_MAX, 4.5, "Max should be 4.5s")
	assert_eq(GlobalTimingController.MICROGAME_DURATION_HARD_CAP, 5.0, "Hard cap should be 5.0s")
	assert_eq(GlobalTimingController.MICROGAME_DURATION_TARGET, 4.0, "Target should be 4.0s")


func test_get_random_microgame_duration():
	# Test multiple times to ensure it stays in range
	for i in range(20):
		var duration = GlobalTimingController.get_random_microgame_duration()
		assert_true(duration >= 3.5, "Duration should be >= 3.5s, got: %.2f" % duration)
		assert_true(duration <= 5.0, "Duration should be <= 5.0s (hard cap), got: %.2f" % duration)


func test_get_target_microgame_duration():
	var duration = GlobalTimingController.get_target_microgame_duration()
	assert_eq(duration, 4.0, "Target duration should be 4.0s")


func test_get_microgame_duration_with_seed():
	# Same seed should produce same duration
	var duration1 = GlobalTimingController.get_microgame_duration_with_seed(12345)
	var duration2 = GlobalTimingController.get_microgame_duration_with_seed(12345)
	
	assert_almost_eq(duration1, duration2, 0.001, "Same seed should produce same duration")
	assert_true(duration1 >= 3.5, "Duration should be >= 3.5s")
	assert_true(duration1 <= 5.0, "Duration should be <= 5.0s")


func test_validate_microgame_duration():
	assert_true(GlobalTimingController.validate_microgame_duration(3.5), "3.5s should be valid")
	assert_true(GlobalTimingController.validate_microgame_duration(4.0), "4.0s should be valid")
	assert_true(GlobalTimingController.validate_microgame_duration(4.5), "4.5s should be valid")
	assert_true(GlobalTimingController.validate_microgame_duration(5.0), "5.0s should be valid (hard cap)")
	
	assert_false(GlobalTimingController.validate_microgame_duration(3.4), "3.4s should be invalid")
	assert_false(GlobalTimingController.validate_microgame_duration(5.1), "5.1s should be invalid")
	assert_false(GlobalTimingController.validate_microgame_duration(2.0), "2.0s should be invalid")
	assert_false(GlobalTimingController.validate_microgame_duration(10.0), "10.0s should be invalid")


func test_microgame_base_duration_helpers():
	# Create a test microgame
	var scene = load("res://microgames/_test/test_any_input.tscn")
	var mg = scene.instantiate()
	add_child_autofree(mg)
	
	# Test framework duration getter
	var duration = mg.get_framework_duration()
	assert_true(duration >= 3.5, "Framework duration should be >= 3.5s")
	assert_true(duration <= 5.0, "Framework duration should be <= 5.0s")
	
	# Test target duration getter
	var target = mg.get_target_duration()
	assert_eq(target, 4.0, "Target duration should be 4.0s")


func test_duration_distribution():
	# Test that durations are reasonably distributed
	var durations = []
	for i in range(50):
		var duration = GlobalTimingController.get_random_microgame_duration()
		durations.append(duration)
	
	# Calculate average
	var sum = 0.0
	for d in durations:
		sum += d
	var avg = sum / durations.size()
	
	# Average should be close to 4.0
	assert_true(avg >= 3.8 and avg <= 4.2, "Average of 50 samples should be near 4.0, got: %.2f" % avg)
	
	# Check min/max
	var min_val = durations.min()
	var max_val = durations.max()
	
	assert_true(min_val >= 3.5, "Min should be >= 3.5s")
	assert_true(max_val <= 5.0, "Max should be <= 5.0s (hard cap)")
