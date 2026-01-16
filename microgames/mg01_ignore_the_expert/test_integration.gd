extends Node
## Integration test - Verify microgame works with all features

@onready var microgame = $MicrogameIgnoreTheExpert

var test_results = []

func _ready():
	print("\n============================================================")
	print("IGNORE THE EXPERT - INTEGRATION TEST")
	print("============================================================\n")
	
	# Run tests
	await test_basic_instantiation()
	await test_presentation_disabled()
	await test_presentation_enabled()
	await test_deterministic_seeding()
	await test_input_during_active()
	
	# Print results
	print("\n============================================================")
	print("TEST RESULTS")
	print("============================================================")
	var passed = 0
	var failed = 0
	for result in test_results:
		if result.passed:
			print("PASS: " + result.name)
			passed += 1
		else:
			print("FAIL: " + result.name + " - " + result.reason)
			failed += 1
	
	print("\nPassed: %d / %d" % [passed, passed + failed])
	print("============================================================\n")
	
	get_tree().quit()


func add_result(name: String, passed: bool, reason: String = ""):
	test_results.append({"name": name, "passed": passed, "reason": reason})


func test_basic_instantiation():
	print("Test: Basic Instantiation")
	if microgame:
		add_result("Basic Instantiation", true)
	else:
		add_result("Basic Instantiation", false, "Microgame not instantiated")


func test_presentation_disabled():
	print("Test: Presentation Disabled Mode")
	microgame.start_microgame({
		"rng_seed": 111,
		"presentation_enabled": false,
		"total_duration_sec": 3.0
	})
	
	var resolved = false
	var outcome = -1
	
	microgame.resolved.connect(func(o): 
		resolved = true
		outcome = o
	)
	
	await get_tree().create_timer(3.5).timeout
	
	if resolved and outcome == microgame.Outcome.FAIL:
		add_result("Presentation Disabled - Timeout FAIL", true)
	else:
		add_result("Presentation Disabled - Timeout FAIL", false, "Did not resolve to FAIL")


func test_presentation_enabled():
	print("Test: Presentation Enabled Mode")
	microgame.start_microgame({
		"rng_seed": 222,
		"presentation_enabled": true,
		"total_duration_sec": 3.0
	})
	
	await get_tree().create_timer(0.5).timeout
	add_result("Presentation Enabled Mode", true)


func test_deterministic_seeding():
	print("Test: Deterministic Seeding")
	
	# Start with same seed twice
	microgame.start_microgame({"rng_seed": 12345, "presentation_enabled": false})
	var deadline1 = microgame._get_advice_deadline_for_tests()
	var total1 = microgame._get_total_duration_for_tests()
	
	await get_tree().create_timer(0.1).timeout
	
	microgame.start_microgame({"rng_seed": 12345, "presentation_enabled": false})
	var deadline2 = microgame._get_advice_deadline_for_tests()
	var total2 = microgame._get_total_duration_for_tests()
	
	if abs(deadline1 - deadline2) < 0.001 and abs(total1 - total2) < 0.001:
		add_result("Deterministic Seeding", true)
	else:
		add_result("Deterministic Seeding", false, "Timings not deterministic")


func test_input_during_active():
	print("Test: Input During Active Phase")
	microgame.start_microgame({
		"rng_seed": 333,
		"presentation_enabled": false,
		"total_duration_sec": 5.0
	})
	
	var resolved = false
	var outcome = -1
	
	microgame.resolved.connect(func(o):
		resolved = true
		outcome = o
	)
	
	# Wait for ADVICE_ACTIVE
	await get_tree().create_timer(0.5).timeout
	
	# Simulate key press
	var key_event = InputEventKey.new()
	key_event.pressed = true
	key_event.keycode = KEY_SPACE
	microgame._unhandled_input(key_event)
	
	await get_tree().create_timer(0.1).timeout
	
	if resolved and outcome == microgame.Outcome.SUCCESS:
		add_result("Input During Active - SUCCESS", true)
	else:
		add_result("Input During Active - SUCCESS", false, "Did not resolve to SUCCESS")
