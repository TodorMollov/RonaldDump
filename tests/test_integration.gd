extends GutTest
## Integration tests - end-to-end flow validation

var game_root: Node
var microgame_container: Node


func before_each():
	# Set up minimal environment
	InputRouter.set_ui_mode()
	GlobalTimingController.stop()
	ChaosManager.reset()
	RunManager.reset()


func after_each():
	if game_root:
		game_root.queue_free()
		game_root = null
	
	InputRouter.set_ui_mode()
	GlobalTimingController.stop()
	ChaosManager.reset()
	RunManager.reset()


func test_managers_exist():
	assert_not_null(InputRouter, "InputRouter should exist")
	assert_not_null(GlobalTimingController, "GlobalTimingController should exist")
	assert_not_null(ChaosManager, "ChaosManager should exist")
	assert_not_null(SequenceManager, "SequenceManager should exist")
	assert_not_null(RunManager, "RunManager should exist")


func test_registry_initialization():
	var registry = MicrogameRegistry.new()
	registry.register_microgame("test", "res://microgames/_test/test_any_input.tscn")
	
	SequenceManager.initialize(registry)
	
	var entry = SequenceManager.select_next_microgame()
	assert_not_null(entry, "Should select a microgame")


func test_timing_phase_transitions():
	var instruction_phase_started = false
	var instruction_phase_completed = false
	var active_phase_started = false
	
	GlobalTimingController.phase_changed.connect(func(phase):
		if phase == GlobalTimingController.Phase.INSTRUCTION:
			instruction_phase_started = true
		elif phase == GlobalTimingController.Phase.ACTIVE:
			active_phase_started = true
	)
	
	GlobalTimingController.phase_complete.connect(func(phase):
		if phase == GlobalTimingController.Phase.INSTRUCTION:
			instruction_phase_completed = true
	)
	
	GlobalTimingController.start_instruction()
	assert_true(instruction_phase_started, "Instruction phase should start")
	
	# Wait for instruction to complete
	await wait_seconds(0.7)
	
	assert_true(instruction_phase_completed, "Instruction phase should complete")


func test_chaos_increases_with_microgames():
	ChaosManager.reset(ChaosManager.RunMode.NORMAL)
	
	var initial_chaos = ChaosManager.get_chaos_level()
	
	ChaosManager.increment_chaos()
	ChaosManager.increment_chaos()
	ChaosManager.increment_chaos()
	
	var final_chaos = ChaosManager.get_chaos_level()
	
	assert_gt(final_chaos, initial_chaos, "Chaos should increase")
	assert_eq(ChaosManager.microgames_completed, 3, "Should count 3 microgames")


func test_input_router_policy_enforcement():
	# Test zero-input policy
	var zero_policy = InputRouter.create_zero_input_policy()
	assert_true(zero_policy.fail_on_any_input, "Zero-input policy should fail on any input")
	
	# Test any-input policy
	var any_policy = InputRouter.create_any_input_policy()
	assert_true(any_policy.success_on_any_input, "Any-input policy should succeed on any input")
	
	# Test directional policy
	var dir_policy = InputRouter.create_directional_policy()
	assert_gt(dir_policy.allowed_actions.size(), 0, "Directional policy should have allowed actions")


func test_input_flush_and_dead_zone():
	InputRouter.enable_input()
	assert_true(InputRouter.input_enabled)
	
	InputRouter.flush_input()
	
	assert_eq(InputRouter.dead_zone_frames, 1, "Should create 1-frame dead zone")
	assert_false(InputRouter.first_input_consumed, "First input flag should be reset")


func test_first_input_dominance():
	InputRouter.first_input_consumed = false
	
	# Simulate first input
	InputRouter.consume_first_input()
	
	assert_true(InputRouter.first_input_consumed, "First input should be marked as consumed")
	
	# Further inputs should be ignored until reset
	# (This would be validated in actual gameplay with input events)


func test_run_manager_state_transitions():
	assert_eq(RunManager.current_state, RunManager.RunState.IDLE, "Should start in IDLE state")
	assert_false(RunManager.is_running())


func test_sequence_no_buffering():
	# Create a simple registry
	var registry = MicrogameRegistry.new()
	registry.register_microgame("game1", "res://microgames/_test/test_any_input.tscn")
	registry.register_microgame("game2", "res://microgames/_test/test_zero_input.tscn")
	
	SequenceManager.initialize(registry)
	
	var first = SequenceManager.select_next_microgame()
	var second = SequenceManager.select_next_microgame()
	
	# No immediate repetition
	assert_ne(first.id, second.id, "Should not repeat immediately")


func test_chaos_mode_multipliers():
	# Normal mode
	ChaosManager.reset(ChaosManager.RunMode.NORMAL)
	ChaosManager.increment_chaos()
	var normal_chaos = ChaosManager.current_chaos
	
	# Unhinged mode
	ChaosManager.reset(ChaosManager.RunMode.UNHINGED)
	ChaosManager.increment_chaos()
	var unhinged_chaos = ChaosManager.current_chaos
	
	assert_gt(unhinged_chaos, normal_chaos, "Unhinged should have higher chaos growth")


func test_input_router_modes():
	InputRouter.set_gameplay_mode()
	assert_eq(InputRouter.current_mode, InputRouter.Mode.GAMEPLAY)
	
	InputRouter.set_ui_mode()
	assert_eq(InputRouter.current_mode, InputRouter.Mode.UI_MODE)
	assert_true(InputRouter.input_enabled, "UI mode should enable input")
