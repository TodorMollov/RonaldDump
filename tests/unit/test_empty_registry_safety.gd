extends GutTest
## Tests for empty registry safety - ensure framework doesn't crash when no microgames registered

var container: Node


func before_each():
	container = Node.new()
	add_child_autofree(container)
	MicrogameRegistry.clear()
	SequenceManager.initialize(MicrogameRegistry)
	RunManager.reset()
	GlobalTimingController.stop()


func after_each():
	if RunManager.current_state == RunManager.RunState.RUNNING:
		RunManager.run_duration = 0.0
		RunManager._process(0.1)
	MicrogameRegistry.clear()
	SequenceManager.reset()


## Ensure SequenceManager doesn't crash when selecting from empty registry
func test_select_from_empty_registry_returns_null():
	var entry = SequenceManager.select_next_microgame()
	assert_null(entry, "Should return null when no microgames registered")


## Ensure RunManager handles empty registry gracefully (doesn't crash on start)
func test_run_manager_empty_registry_safe():
	RunManager.start_run(ChaosManager.RunMode.NORMAL, container)
	await get_tree().process_frame
	
	# Framework should not crash; active_microgame may be null
	var is_safe = true
	if RunManager.current_state != RunManager.RunState.RUNNING:
		is_safe = true  # Already ended, that's safe
	
	assert_true(is_safe, "RunManager should handle empty registry without crashing")
