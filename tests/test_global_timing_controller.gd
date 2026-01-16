extends GutTest
## Tests for GlobalTimingController - phase timing and transitions

var timing_controller: Node


func before_each():
	timing_controller = GlobalTimingController
	timing_controller.stop()


func after_each():
	timing_controller.stop()


func test_timing_controller_exists():
	assert_not_null(timing_controller, "GlobalTimingController should exist")


func test_phase_enum():
	assert_true(GlobalTimingController.Phase.NONE >= 0)
	assert_true(GlobalTimingController.Phase.INSTRUCTION >= 0)
	assert_true(GlobalTimingController.Phase.ACTIVE >= 0)
	assert_true(GlobalTimingController.Phase.RESOLVE >= 0)


func test_phase_durations():
	assert_eq(GlobalTimingController.INSTRUCTION_DURATION, 0.6, "Instruction duration should be 0.6s")
	assert_eq(GlobalTimingController.ACTIVE_DURATION, 4.0, "Active duration should be 4.0s")
	assert_eq(GlobalTimingController.RESOLVE_DURATION, 0.4, "Resolve duration should be 0.4s")


func test_initial_state():
	assert_eq(timing_controller.current_phase, GlobalTimingController.Phase.NONE, "Initial phase should be NONE")
	assert_false(timing_controller.phase_running, "Phase should not be running initially")


func test_start_instruction():
	timing_controller.start_instruction()
	assert_eq(timing_controller.current_phase, GlobalTimingController.Phase.INSTRUCTION)
	assert_true(timing_controller.phase_running)
	assert_true(timing_controller.is_instruction_phase())


func test_start_active():
	timing_controller.start_active()
	assert_eq(timing_controller.current_phase, GlobalTimingController.Phase.ACTIVE)
	assert_true(timing_controller.phase_running)
	assert_true(timing_controller.is_active_phase())


func test_start_resolve():
	timing_controller.start_resolve()
	assert_eq(timing_controller.current_phase, GlobalTimingController.Phase.RESOLVE)
	assert_true(timing_controller.phase_running)
	assert_true(timing_controller.is_resolve_phase())


func test_stop():
	timing_controller.start_active()
	timing_controller.stop()
	assert_eq(timing_controller.current_phase, GlobalTimingController.Phase.NONE)
	assert_false(timing_controller.phase_running)


func test_phase_progress():
	timing_controller.start_active()
	timing_controller.phase_timer = 2.0
	var progress = timing_controller.get_phase_progress()
	assert_almost_eq(progress, 0.5, 0.01, "Progress should be 50% at 2.0s of 4.0s")


func test_phase_time_remaining():
	timing_controller.start_active()
	timing_controller.phase_timer = 1.0
	var remaining = timing_controller.get_phase_time_remaining()
	assert_almost_eq(remaining, 3.0, 0.01, "Remaining should be 3.0s")


func test_force_resolve_immediate():
	timing_controller.start_active()
	
	var phase_completed = false
	timing_controller.phase_complete.connect(func(phase): phase_completed = true)
	
	timing_controller.force_resolve_immediate()
	
	assert_true(phase_completed, "Phase should be completed immediately")
