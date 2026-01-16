extends GutTest
## Tests for MicrogameBase and MicrogameRegistry

var test_microgame: MicrogameBase


func before_each():
	# Create a simple test microgame
	test_microgame = MicrogameBase.new()
	add_child_autofree(test_microgame)


func test_microgame_base_exists():
	assert_not_null(test_microgame, "MicrogameBase should instantiate")


func test_result_enum():
	assert_true(MicrogameBase.Result.NONE >= 0)
	assert_true(MicrogameBase.Result.SUCCESS >= 0)
	assert_true(MicrogameBase.Result.FAILURE >= 0)


func test_initial_state():
	assert_eq(test_microgame.microgame_result, MicrogameBase.Result.NONE)
	assert_false(test_microgame.is_active)
	assert_false(test_microgame.is_resolved())


func test_on_activate():
	test_microgame.on_activate()
	assert_true(test_microgame.is_active)
	assert_eq(test_microgame.microgame_result, MicrogameBase.Result.NONE)


func test_on_deactivate():
	test_microgame.on_activate()
	test_microgame.on_deactivate()
	assert_false(test_microgame.is_active)


func test_resolve_success():
	var resolved_success = false
	test_microgame.resolved.connect(func(success): resolved_success = success)
	
	test_microgame.resolve_success()
	
	assert_true(test_microgame.is_resolved())
	assert_eq(test_microgame.get_result(), MicrogameBase.Result.SUCCESS)
	assert_true(resolved_success, "Should emit resolved signal with true")


func test_resolve_failure():
	var resolved_success = true
	test_microgame.resolved.connect(func(success): resolved_success = success)
	
	test_microgame.resolve_failure()
	
	assert_true(test_microgame.is_resolved())
	assert_eq(test_microgame.get_result(), MicrogameBase.Result.FAILURE)
	assert_false(resolved_success, "Should emit resolved signal with false")


func test_cannot_resolve_twice():
	test_microgame.resolve_success()
	test_microgame.resolve_failure()
	
	# Should still be SUCCESS (first resolve wins)
	assert_eq(test_microgame.get_result(), MicrogameBase.Result.SUCCESS)


func test_get_instruction_text():
	var text = test_microgame.get_instruction_text()
	assert_not_null(text, "Should return instruction text")


## MicrogameRegistry tests

func test_registry_creation():
	var registry = MicrogameRegistry.new()
	assert_not_null(registry)
	assert_eq(registry.entries.size(), 0)


func test_register_microgame():
	var registry = MicrogameRegistry.new()
	registry.register_microgame("test_id", "res://test.tscn", 5, "Test Game")
	
	assert_eq(registry.entries.size(), 1)
	var entry = registry.entries[0]
	assert_eq(entry.id, "test_id")
	assert_eq(entry.scene_path, "res://test.tscn")
	assert_eq(entry.weight, 5)
	assert_eq(entry.display_name, "Test Game")


func test_get_entry_by_id():
	var registry = MicrogameRegistry.new()
	registry.register_microgame("game_a", "res://a.tscn")
	registry.register_microgame("game_b", "res://b.tscn")
	
	var entry = registry.get_entry_by_id("game_b")
	assert_not_null(entry)
	assert_eq(entry.id, "game_b")


func test_get_entry_by_id_not_found():
	var registry = MicrogameRegistry.new()
	registry.register_microgame("game_a", "res://a.tscn")
	
	var entry = registry.get_entry_by_id("nonexistent")
	assert_null(entry)


func test_get_total_weight():
	var registry = MicrogameRegistry.new()
	registry.register_microgame("a", "res://a.tscn", 10)
	registry.register_microgame("b", "res://b.tscn", 20)
	registry.register_microgame("c", "res://c.tscn", 15)
	
	assert_eq(registry.get_total_weight(), 45)


func test_registry_clear():
	var registry = MicrogameRegistry.new()
	registry.register_microgame("a", "res://a.tscn")
	registry.clear()
	
	assert_eq(registry.entries.size(), 0)
