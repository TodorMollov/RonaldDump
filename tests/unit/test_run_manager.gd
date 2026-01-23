extends GutTest
## Tests for RunManager lifecycle

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


func test_start_run_sets_duration():
	RunManager.start_run(ChaosManager.RunMode.NORMAL, container)
	assert_eq(RunManager.current_state, RunManager.RunState.RUNNING)
	assert_eq(RunManager.run_duration, RunManager.RUN_DURATION_NORMAL)


func test_end_run_marks_completed():
	RunManager.start_run(ChaosManager.RunMode.NORMAL, container)
	RunManager.run_duration = 0.0
	RunManager._process(0.1)
	assert_eq(RunManager.current_state, RunManager.RunState.COMPLETED)
	assert_true(completed)
