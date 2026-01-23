extends GutTest
## Tests for SequenceManager cooldown and weights

var registry = null


func before_each():
	registry = MicrogameRegistry
	registry.clear()
	registry.register_microgame("a", "res://tests/fixtures/TestMicrogame.tscn", 1.0, true)
	registry.register_microgame("b", "res://tests/fixtures/TestMicrogame.tscn", 1.0, true)
	registry.register_microgame("c", "res://tests/fixtures/TestMicrogame.tscn", 1.0, true)
	registry.register_microgame("d", "res://tests/fixtures/TestMicrogame.tscn", 1.0, true)
	SequenceManager.initialize(registry)


func after_each():
	registry.clear()
	SequenceManager.reset()


func test_cooldown_excludes_recent_history():
	SequenceManager.recent_history = ["a", "b", "c"]
	var entry = SequenceManager.select_next_microgame()
	assert_eq(entry.id, "d", "Should pick the only non-recent entry")


func test_all_recent_fallback():
	SequenceManager.recent_history = ["a", "b", "c", "d"]
	var entry = SequenceManager.select_next_microgame()
	assert_not_null(entry, "Should fall back to any enabled entry")


func test_zero_weight_is_skipped():
	registry.clear()
	registry.register_microgame("zero", "res://tests/fixtures/TestMicrogame.tscn", 0.0, true)
	registry.register_microgame("one", "res://tests/fixtures/TestMicrogame.tscn", 1.0, true)
	SequenceManager.initialize(registry)
	SequenceManager.recent_history = []
	var entry = SequenceManager.select_next_microgame()
	assert_eq(entry.id, "one", "Zero-weight entries should be skipped")
