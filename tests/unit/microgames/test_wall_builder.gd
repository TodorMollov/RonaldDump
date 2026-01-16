extends GutTest
## GUT tests for Wall Builder microgame

var wall_scene = preload("res://microgames/mg03_wall_builder/WallBuilder.tscn")
var mg = null
var resolved_count := 0
var last_outcome := false
var has_outcome := false

func before_each():
	mg = wall_scene.instantiate()
	add_child_autofree(mg)
	mg.resolved.connect(_on_resolved)
	resolved_count = 0
	last_outcome = false
	has_outcome = false

func _on_resolved(outcome: bool) -> void:
	resolved_count += 1
	last_outcome = outcome
	has_outcome = true

func test_input_policy():
	mg.on_activate()
	var policy = mg.get_input_policy()
	assert_not_null(policy, "Input policy should be set")
	assert_false(policy.success_on_any_input, "success_on_any_input should be false")
	assert_false(policy.fail_on_any_input, "fail_on_any_input should be false")
	assert_false(policy.pointer_move_counts_as_input, "pointer_move_counts_as_input should be false")
	assert_true(policy.allowed_actions.has(InputRouter.Action.MOVE_LEFT), "Policy allows MOVE_LEFT")
	assert_true(policy.allowed_actions.has(InputRouter.Action.MOVE_RIGHT), "Policy allows MOVE_RIGHT")
	assert_true(policy.allowed_actions.has(InputRouter.Action.CONFIRM), "Policy allows CONFIRM")
	assert_eq(policy.allowed_actions.size(), 3, "Policy should allow exactly three actions")

func test_success_after_two_full_rows():
	mg.on_activate()
	mg.on_active_start()
	mg.start_microgame({ "presentation_enabled": false, "rng_seed": 1 })
	
	var bottom_row = mg.ROWS - 1
	for c in range(mg.COLS):
		if c != 1:
			mg._set_cell_for_tests(bottom_row, c, true)
	
	mg._force_active_for_tests(bottom_row, 1)
	mg._lock_active_for_tests()
	
	assert_eq(resolved_count, 1, "Should resolve exactly once after two rows")
	assert_true(has_outcome, "Outcome should be recorded")
	assert_true(last_outcome, "Outcome should be SUCCESS")
	
	for c in range(mg.COLS):
		assert_true(mg._get_cell_for_tests(bottom_row, c), "Bottom row should remain filled")

func test_non_bottom_row_does_not_trigger_success():
	mg.on_activate()
	mg.on_active_start()
	mg.start_microgame({ "presentation_enabled": false })
	
	var target_row = mg.ROWS - 2
	for c in range(mg.COLS):
		if c != 0:
			mg._set_cell_for_tests(target_row, c, true)
	
	mg._force_active_for_tests(target_row, 0)
	mg._lock_active_for_tests()
	
	assert_eq(resolved_count, 0, "Non-bottom row completion should not resolve")

func test_overflow_triggers_failure():
	mg.on_activate()
	mg.on_active_start()
	mg.start_microgame({ "presentation_enabled": false })
	
	mg._set_cell_for_tests(0, int(mg.COLS / 2), true)
	mg._clear_active_for_tests()
	mg._force_spawn_for_tests(int(mg.COLS / 2))
	
	assert_eq(resolved_count, 1, "Overflow should resolve failure once")
	assert_true(has_outcome, "Outcome should be recorded")
	assert_false(last_outcome, "Outcome should be FAILURE")

func test_input_ignored_after_deactivate_or_resolve():
	mg.on_activate()
	mg.on_active_start()
	mg.start_microgame({ "presentation_enabled": false })
	
	var start_col = mg._get_active_col_for_tests()
	mg.force_resolve(mg.Result.SUCCESS)
	mg.on_input([InputRouter.Action.MOVE_RIGHT])
	assert_eq(resolved_count, 1, "Resolve should only emit once")
	assert_eq(mg._get_active_col_for_tests(), start_col, "Input after resolve should be ignored")
	
	mg.on_deactivate()
	mg.on_input([InputRouter.Action.MOVE_LEFT])
	assert_eq(mg._get_active_col_for_tests(), start_col, "Input after deactivate should be ignored")
