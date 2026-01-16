extends GutTest
## GUT tests for Ignore The Expert microgame

var microgame_scene = preload("res://microgames/mg01_ignore_the_expert/MicrogameIgnoreTheExpert.tscn")
var mg = null

# Track resolved signal
var resolved_count = 0
var last_outcome = -1


func before_each():
	mg = microgame_scene.instantiate()
	add_child_autofree(mg)
	
	# Connect signal
	mg.resolved.connect(_on_resolved)
	
	# Reset tracking
	resolved_count = 0
	last_outcome = -1


func _on_resolved(outcome: int):
	resolved_count += 1
	last_outcome = outcome


## Helper: Advance time by ticking process
func tick(seconds: float, step: float = 0.016):
	var elapsed = 0.0
	while elapsed < seconds:
		mg._process(step)
		elapsed += step


## Test 1: Input policy matches spec
func test_input_policy():
	var policy = mg.get_input_policy()
	
	assert_true(policy.has("success_on_any_input"), "Policy should have success_on_any_input")
	assert_true(policy["success_on_any_input"], "success_on_any_input should be true")
	
	assert_true(policy.has("pointer_move_counts_as_input"), "Policy should have pointer_move_counts_as_input")
	assert_false(policy["pointer_move_counts_as_input"], "pointer_move_counts_as_input should be false")


## Test 2: Input during INTRO is ignored
func test_input_during_intro_ignored():
	mg.start_microgame({ "rng_seed": 123, "presentation_enabled": false })
	
	# Send input during INTRO (before 0.3s)
	tick(0.1)
	assert_eq(mg._get_state_for_tests(), mg.State.INTRO, "Should be in INTRO")
	
	var key_event = InputEventKey.new()
	key_event.pressed = true
	key_event.keycode = KEY_SPACE
	mg._input(key_event)
	
	assert_eq(resolved_count, 0, "Should not resolve during INTRO")
	
	# Advance past INTRO into ADVICE_ACTIVE
	tick(0.25)  # Total 0.35s, past 0.3s threshold
	assert_eq(mg._get_state_for_tests(), mg.State.ADVICE_ACTIVE, "Should be in ADVICE_ACTIVE")
	
	# Now send input and it should resolve
	var key_event2 = InputEventKey.new()
	key_event2.pressed = true
	key_event2.keycode = KEY_ENTER
	mg._input(key_event2)
	
	assert_eq(resolved_count, 1, "Should resolve once in ADVICE_ACTIVE")
	assert_eq(last_outcome, mg.Outcome.SUCCESS, "Should be SUCCESS")


## Test 3: Mouse motion is ignored
func test_mouse_motion_ignored():
	mg.start_microgame({ "rng_seed": 456, "presentation_enabled": false })
	
	# Advance to ADVICE_ACTIVE
	tick(0.35)
	assert_eq(mg._get_state_for_tests(), mg.State.ADVICE_ACTIVE)
	
	# Send mouse motion
	var motion_event = InputEventMouseMotion.new()
	motion_event.position = Vector2(100, 100)
	motion_event.relative = Vector2(10, 10)
	mg._input(motion_event)
	
	assert_eq(resolved_count, 0, "Mouse motion should not resolve")
	
	# Advance past deadline
	var deadline = mg._get_advice_deadline_for_tests()
	tick(deadline - mg._get_elapsed_for_tests() + 0.1)
	
	assert_eq(resolved_count, 1, "Should resolve with FAIL after deadline")
	assert_eq(last_outcome, mg.Outcome.FAIL, "Should be FAIL")


## Test 4: Success just before deadline
func test_success_before_deadline():
	mg.start_microgame({ "rng_seed": 789, "presentation_enabled": false })
	
	# Advance to ADVICE_ACTIVE
	tick(0.35)
	
	# Advance to just before deadline
	var deadline = mg._get_advice_deadline_for_tests()
	var remaining = maxf(deadline - mg._get_elapsed_for_tests() - 0.05, 0.0)
	tick(remaining, 0.01)
	
	assert_eq(resolved_count, 0, "Should not be resolved yet")
	
	# Send input
	var key_event = InputEventKey.new()
	key_event.pressed = true
	key_event.keycode = KEY_A
	mg._input(key_event)
	
	assert_eq(resolved_count, 1, "Should resolve once")
	assert_eq(last_outcome, mg.Outcome.SUCCESS, "Should be SUCCESS")
	
	# Send another input - should not trigger again
	var key_event2 = InputEventKey.new()
	key_event2.pressed = true
	key_event2.keycode = KEY_B
	mg._input(key_event2)
	
	assert_eq(resolved_count, 1, "Should still be resolved only once")


## Test 5: Fail at deadline without input
func test_fail_at_deadline():
	mg.start_microgame({ "rng_seed": 111, "presentation_enabled": false })
	
	# Advance to ADVICE_ACTIVE
	tick(0.35)
	
	# Advance to deadline + small epsilon
	var deadline = mg._get_advice_deadline_for_tests()
	tick(deadline - mg._get_elapsed_for_tests() + 0.05)
	
	assert_eq(resolved_count, 1, "Should resolve at deadline")
	assert_eq(last_outcome, mg.Outcome.FAIL, "Should be FAIL")


## Test 6: Overall timeout fail
func test_overall_timeout_fail():
	mg.start_microgame({ "rng_seed": 222, "total_duration_sec": 3.0, "presentation_enabled": false })
	
	# Advance to ADVICE_ACTIVE
	tick(0.35)
	
	# Advance to total duration without input
	var total_dur = mg._get_total_duration_for_tests()
	tick(total_dur - mg._get_elapsed_for_tests() + 0.1)
	
	assert_eq(resolved_count, 1, "Should resolve at overall timeout")
	assert_eq(last_outcome, mg.Outcome.FAIL, "Should be FAIL")


## Test 7: First input wins - further inputs ignored
func test_first_input_wins():
	mg.start_microgame({ "rng_seed": 333, "presentation_enabled": false })
	
	# Advance to ADVICE_ACTIVE
	tick(0.35)
	
	# Send first input (SUCCESS)
	var key_event1 = InputEventKey.new()
	key_event1.pressed = true
	key_event1.keycode = KEY_1
	mg._input(key_event1)
	
	assert_eq(resolved_count, 1, "Should resolve once")
	assert_eq(last_outcome, mg.Outcome.SUCCESS, "Should be SUCCESS")
	assert_eq(mg._get_state_for_tests(), mg.State.SUCCESS_RESOLVE, "Should be in SUCCESS_RESOLVE")
	
	# Send more inputs
	var key_event2 = InputEventKey.new()
	key_event2.pressed = true
	key_event2.keycode = KEY_2
	mg._input(key_event2)
	
	var mouse_event = InputEventMouseButton.new()
	mouse_event.pressed = true
	mouse_event.button_index = MOUSE_BUTTON_LEFT
	mg._input(mouse_event)
	
	assert_eq(resolved_count, 1, "Should still be resolved only once")
	assert_eq(last_outcome, mg.Outcome.SUCCESS, "Outcome should remain SUCCESS")


## Test 8: Mouse button click triggers success
func test_mouse_click_triggers_success():
	mg.start_microgame({ "rng_seed": 444, "presentation_enabled": false })
	
	# Advance to ADVICE_ACTIVE
	tick(0.35)
	
	# Send mouse click
	var mouse_event = InputEventMouseButton.new()
	mouse_event.pressed = true
	mouse_event.button_index = MOUSE_BUTTON_LEFT
	mg._input(mouse_event)
	
	assert_eq(resolved_count, 1, "Should resolve once")
	assert_eq(last_outcome, mg.Outcome.SUCCESS, "Should be SUCCESS")


## Test 9: Joypad button triggers success
func test_joypad_button_triggers_success():
	mg.start_microgame({ "rng_seed": 555, "presentation_enabled": false })
	
	# Advance to ADVICE_ACTIVE
	tick(0.35)
	
	# Send joypad button
	var joy_event = InputEventJoypadButton.new()
	joy_event.pressed = true
	joy_event.button_index = JOY_BUTTON_A
	mg._input(joy_event)
	
	assert_eq(resolved_count, 1, "Should resolve once")
	assert_eq(last_outcome, mg.Outcome.SUCCESS, "Should be SUCCESS")


## Test 10: Force resolve works
func test_force_resolve():
	mg.start_microgame({ "rng_seed": 666, "presentation_enabled": false })
	
	# Advance to ADVICE_ACTIVE
	tick(0.35)
	
	# Force resolve
	mg.force_resolve(mg.Outcome.FAIL)
	
	assert_eq(resolved_count, 1, "Should resolve once")
	assert_eq(last_outcome, mg.Outcome.FAIL, "Should be FAIL")
	
	# Try to force again - should not emit twice
	mg.force_resolve(mg.Outcome.SUCCESS)
	assert_eq(resolved_count, 1, "Should still be resolved only once")


## Test 11: Key echo is ignored
func test_key_echo_ignored():
	mg.start_microgame({ "rng_seed": 777, "presentation_enabled": false })
	
	# Advance to ADVICE_ACTIVE
	tick(0.35)
	
	# Send key echo event
	var key_event = InputEventKey.new()
	key_event.pressed = true
	key_event.echo = true  # This is an echo
	key_event.keycode = KEY_SPACE
	mg._input(key_event)
	
	assert_eq(resolved_count, 0, "Echo should be ignored")
	
	# Send real key press
	var key_event2 = InputEventKey.new()
	key_event2.pressed = true
	key_event2.echo = false
	key_event2.keycode = KEY_SPACE
	mg._input(key_event2)
	
	assert_eq(resolved_count, 1, "Real key press should resolve")
	assert_eq(last_outcome, mg.Outcome.SUCCESS, "Should be SUCCESS")


## Test 12: Deterministic timing with seed
func test_deterministic_timing():
	# Start with same seed twice
	mg.start_microgame({ "rng_seed": 12345, "presentation_enabled": false })
	var deadline1 = mg._get_advice_deadline_for_tests()
	var total1 = mg._get_total_duration_for_tests()
	
	mg.start_microgame({ "rng_seed": 12345, "presentation_enabled": false })
	var deadline2 = mg._get_advice_deadline_for_tests()
	var total2 = mg._get_total_duration_for_tests()
	
	assert_almost_eq(deadline1, deadline2, 0.001, "Deadline should be deterministic")
	assert_almost_eq(total1, total2, 0.001, "Total duration should be deterministic")
