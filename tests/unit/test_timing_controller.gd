extends GutTest
## Tests for GlobalTimingController phase timing

var timing: Node
var completed: Array = []


func before_each():
	timing = GlobalTimingController
	timing.stop()
	completed.clear()
	if not timing.phase_complete.is_connected(_on_phase_complete):
		timing.phase_complete.connect(_on_phase_complete)


func _on_phase_complete(phase: int) -> void:
	completed.append(phase)


func test_instruction_phase_completes():
	timing.start_instruction()
	timing._process(GlobalTimingController.INSTRUCTION_DURATION + 0.01)
	assert_true(completed.has(GlobalTimingController.Phase.INSTRUCTION))


func test_active_phase_completes():
	timing.start_active()
	timing._process(GlobalTimingController.ACTIVE_DURATION + 0.01)
	assert_true(completed.has(GlobalTimingController.Phase.ACTIVE))


func test_force_resolve_immediate_transitions():
	timing.start_active()
	timing.force_resolve_immediate()
	assert_eq(timing.current_phase, GlobalTimingController.Phase.RESOLVE)
