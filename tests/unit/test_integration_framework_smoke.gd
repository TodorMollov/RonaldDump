extends GutTest
## Integration smoke test for framework run loop

var container: Node
var registry
var completed := false


func before_each():
	container = Node.new()
	add_child_autofree(container)
	registry = MicrogameRegistry
	registry.clear()
	registry.register_microgame("test_microgame", "res://tests/fixtures/TestMicrogame.tscn", 1.0, true)
	SequenceManager.initialize(registry)
	RunManager.reset()
	GlobalTimingController.stop()
	completed = false
	if not RunManager.run_completed.is_connected(_on_run_completed):
		RunManager.run_completed.connect(_on_run_completed)


func after_each():
	if RunManager.current_state == RunManager.RunState.RUNNING:
		RunManager.run_duration = 0.0
		RunManager._process(0.1)
	registry.clear()
	SequenceManager.reset()


func _on_run_completed() -> void:
	completed = true


func test_run_smoke_flow():
	RunManager.start_run(ChaosManager.RunMode.NORMAL, container)
	await get_tree().process_frame
	
	# Configure microgame to resolve on input
	if RunManager.active_microgame and RunManager.active_microgame.has_method("set_resolve_on_input"):
		RunManager.active_microgame.set_resolve_on_input(true)
	
	# Complete instruction phase
	GlobalTimingController._process(GlobalTimingController.INSTRUCTION_DURATION + 0.01)
	await get_tree().process_frame
	
	# Send input during active
	var event = InputEventKey.new()
	event.pressed = true
	event.echo = false
	event.keycode = KEY_A
	InputRouter._input(event)
	InputRouter._process(0.01)
	
	# Complete active and resolve phases
	GlobalTimingController._process(GlobalTimingController.ACTIVE_DURATION + 0.01)
	await get_tree().process_frame
	GlobalTimingController._process(GlobalTimingController.RESOLVE_DURATION + 0.01)
	await get_tree().process_frame
	
	# Force end run
	RunManager.run_duration = 0.0
	RunManager._process(0.1)
	assert_true(completed)
