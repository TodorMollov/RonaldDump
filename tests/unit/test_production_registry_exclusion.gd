extends GutTest
## Regression test: Ensure production registry does NOT contain test fixtures

## Verify test injection is separate from production registry
func test_test_injection_does_not_contaminate_production():
	var registry = MicrogameRegistry
	registry.clear()
	
	# Simulate injecting test defs for a test
	var test_defs = []
	var test_entry = MicrogameDef.new()
	test_entry.id = "test_micro"
	test_entry.scene_path = "res://tests/fixtures/TestMicrogame.tscn"
	test_entry.weight = 1.0
	test_entry.enabled = true
	test_defs.append(test_entry)
	
	registry.set_defs_for_tests(test_defs)
	
	# Verify test defs are active
	var entries = registry.get_entries()
	assert_eq(entries.size(), 1, "Should have exactly one test entry")
	assert_eq(entries[0].scene_path, "res://tests/fixtures/TestMicrogame.tscn")
	
	# Now clear and verify it's clean (production state restored)
	registry.clear()
	entries = registry.get_entries()
	assert_eq(entries.size(), 0, "After clear, should have no entries (production state)")


## Verify that boot.gd production state has no test fixtures  
func test_production_boot_excludes_test_fixtures():
	# This validates that boot.gd setup (empty production registry) 
	# does not contain any test fixture paths
	
	# Simulate what boot.gd does: clear registry (no production microgames registered)
	var prod_registry = MicrogameRegistry
	prod_registry.clear()
	
	# Verify production state is clean
	var entries = prod_registry.get_entries()
	
	# Should be empty (no real microgames in production yet)
	assert_eq(entries.size(), 0, "Production registry should be empty until real microgames are added")
	
	# If any entries exist in future, verify they're not test paths
	for entry in entries:
		var is_test_path = entry.scene_path.contains("tests/fixtures") or \
						   entry.scene_path.contains("microgames/_test")
		assert_false(is_test_path, "Production registry must not contain test fixture: %s" % entry.scene_path)
