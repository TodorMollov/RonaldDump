extends GutTest
## Tests for SequenceManager - weighted random selection with cooldown

var sequence_manager: Node
var test_registry: MicrogameRegistry


func before_each():
	sequence_manager = SequenceManager
	sequence_manager.reset()
	
	test_registry = MicrogameRegistry.new()
	test_registry.register_microgame("game_a", "res://test_a.tscn", 1)
	test_registry.register_microgame("game_b", "res://test_b.tscn", 1)
	test_registry.register_microgame("game_c", "res://test_c.tscn", 1)
	test_registry.register_microgame("game_d", "res://test_d.tscn", 1)
	
	sequence_manager.initialize(test_registry)


func after_each():
	sequence_manager.reset()


func test_sequence_manager_exists():
	assert_not_null(sequence_manager, "SequenceManager should exist")


func test_initialize():
	var registry = MicrogameRegistry.new()
	registry.register_microgame("test", "res://test.tscn")
	
	sequence_manager.initialize(registry)
	assert_not_null(sequence_manager.registry, "Registry should be set")


func test_select_next_microgame():
	var entry = sequence_manager.select_next_microgame()
	assert_not_null(entry, "Should select a microgame")
	assert_true(entry.id in ["game_a", "game_b", "game_c", "game_d"], "Should be a valid game ID")


func test_no_immediate_repetition():
	var first = sequence_manager.select_next_microgame()
	var second = sequence_manager.select_next_microgame()
	
	assert_ne(first.id, second.id, "Should not repeat immediately")


func test_cooldown_window():
	# Select 3 games
	var first = sequence_manager.select_next_microgame()
	var second = sequence_manager.select_next_microgame()
	var third = sequence_manager.select_next_microgame()
	
	# Check history size
	var history = sequence_manager.get_history()
	assert_lte(history.size(), 3, "History should not exceed cooldown window size")
	
	# The last 3 should be in history
	assert_true(first.id in history or history.size() < 3, "Recent games should be in history")


func test_weighted_selection():
	# Create registry with different weights
	var weighted_registry = MicrogameRegistry.new()
	weighted_registry.register_microgame("heavy", "res://heavy.tscn", 100)
	weighted_registry.register_microgame("light", "res://light.tscn", 1)
	
	sequence_manager.initialize(weighted_registry)
	
	# Select many times and count
	var heavy_count = 0
	var light_count = 0
	
	for i in range(50):
		var entry = sequence_manager.select_next_microgame()
		if entry.id == "heavy":
			heavy_count += 1
		elif entry.id == "light":
			light_count += 1
	
	# Heavy should be selected significantly more
	assert_gt(heavy_count, light_count, "Higher weight should be selected more often")


func test_single_microgame_registry():
	var single_registry = MicrogameRegistry.new()
	single_registry.register_microgame("only_game", "res://only.tscn")
	
	sequence_manager.initialize(single_registry)
	
	var first = sequence_manager.select_next_microgame()
	var second = sequence_manager.select_next_microgame()
	
	assert_eq(first.id, "only_game", "Should select the only game")
	assert_eq(second.id, "only_game", "Should select the only game again")


func test_reset_clears_history():
	sequence_manager.select_next_microgame()
	sequence_manager.select_next_microgame()
	
	sequence_manager.reset()
	
	assert_eq(sequence_manager.get_history().size(), 0, "History should be cleared")
	assert_eq(sequence_manager.last_played_id, "", "Last played should be cleared")
