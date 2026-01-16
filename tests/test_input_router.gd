extends GutTest
## Tests for InputRouter - canonical actions, policies, and dominance rules

var input_router: Node


func before_each():
	input_router = InputRouter


func after_each():
	input_router.flush_input()
	input_router.set_ui_mode()


func test_input_router_exists():
	assert_not_null(input_router, "InputRouter should exist as autoload")


func test_canonical_action_enum():
	assert_true(InputRouter.Action.MOVE_LEFT >= 0)
	assert_true(InputRouter.Action.MOVE_RIGHT >= 0)
	assert_true(InputRouter.Action.CONFIRM >= 0)
	assert_true(InputRouter.Action.ANY >= 0)
	assert_true(InputRouter.Action.CANCEL >= 0)
	assert_true(InputRouter.Action.POINTER_PRIMARY >= 0)
	assert_true(InputRouter.Action.POINTER_POS >= 0)


func test_input_policy_creation_any_input():
	var policy = InputRouter.create_any_input_policy()
	assert_true(policy.success_on_any_input, "Any-input policy should have success_on_any_input=true")
	assert_false(policy.fail_on_any_input, "Any-input policy should have fail_on_any_input=false")
	assert_false(policy.pointer_move_counts_as_input, "Any-input policy should not count pointer move")


func test_input_policy_creation_zero_input():
	var policy = InputRouter.create_zero_input_policy()
	assert_false(policy.success_on_any_input, "Zero-input policy should have success_on_any_input=false")
	assert_true(policy.fail_on_any_input, "Zero-input policy should have fail_on_any_input=true")
	assert_false(policy.pointer_move_counts_as_input, "Zero-input policy should not count pointer move")


func test_input_policy_creation_directional():
	var policy = InputRouter.create_directional_policy()
	assert_true(InputRouter.Action.MOVE_LEFT in policy.allowed_actions, "Directional policy should allow MOVE_LEFT")
	assert_true(InputRouter.Action.MOVE_RIGHT in policy.allowed_actions, "Directional policy should allow MOVE_RIGHT")
	assert_true(InputRouter.Action.CONFIRM in policy.allowed_actions, "Directional policy should allow CONFIRM")


func test_gameplay_mode_disables_input_initially():
	input_router.set_gameplay_mode()
	assert_false(input_router.input_enabled, "Input should be disabled after set_gameplay_mode")


func test_enable_input():
	input_router.enable_input()
	assert_true(input_router.input_enabled, "Input should be enabled")


func test_disable_input():
	input_router.enable_input()
	input_router.disable_input()
	assert_false(input_router.input_enabled, "Input should be disabled")


func test_flush_input_creates_dead_zone():
	input_router.flush_input()
	assert_eq(input_router.dead_zone_frames, 1, "Flush should create 1-frame dead zone")


func test_consume_first_input():
	input_router.first_input_consumed = false
	input_router.consume_first_input()
	assert_true(input_router.first_input_consumed, "First input should be marked as consumed")


func test_ui_mode_enables_input():
	input_router.set_ui_mode()
	assert_true(input_router.input_enabled, "UI mode should enable input")
	assert_eq(input_router.current_mode, InputRouter.Mode.UI_MODE, "Should be in UI mode")


func test_has_action_helper():
	var actions: Array[InputRouter.Action] = [InputRouter.Action.CONFIRM, InputRouter.Action.MOVE_LEFT]
	assert_true(input_router.has_action(actions, InputRouter.Action.CONFIRM), "Should find CONFIRM")
	assert_true(input_router.has_action(actions, InputRouter.Action.MOVE_LEFT), "Should find MOVE_LEFT")
	assert_false(input_router.has_action(actions, InputRouter.Action.MOVE_RIGHT), "Should not find MOVE_RIGHT")


func test_input_policy_blocked_actions():
	var policy = InputRouter.InputPolicy.new()
	policy.blocked_actions = [InputRouter.Action.MOVE_LEFT]
	
	input_router.set_input_policy(policy)
	input_router.set_gameplay_mode()
	
	# Simulate actions
	var actions = [InputRouter.Action.MOVE_LEFT, InputRouter.Action.CONFIRM]
	var filtered = input_router._apply_policy(actions)
	
	assert_false(InputRouter.Action.MOVE_LEFT in filtered, "MOVE_LEFT should be blocked")
	assert_true(InputRouter.Action.CONFIRM in filtered, "CONFIRM should not be blocked")


func test_input_policy_allowed_actions():
	var policy = InputRouter.InputPolicy.new()
	policy.allowed_actions = [InputRouter.Action.CONFIRM]
	
	input_router.set_input_policy(policy)
	input_router.set_gameplay_mode()
	
	# Simulate actions
	var actions = [InputRouter.Action.MOVE_LEFT, InputRouter.Action.CONFIRM]
	var filtered = input_router._apply_policy(actions)
	
	assert_false(InputRouter.Action.MOVE_LEFT in filtered, "MOVE_LEFT should not be allowed")
	assert_true(InputRouter.Action.CONFIRM in filtered, "CONFIRM should be allowed")


func test_ui_mode_filter():
	input_router.set_ui_mode()
	
	var actions = [InputRouter.Action.CONFIRM, InputRouter.Action.ANY, InputRouter.Action.MOVE_LEFT]
	var filtered = input_router._apply_ui_mode_filter(actions)
	
	# In UI mode, CONFIRM/ANY/POINTER_PRIMARY should normalize to CONFIRM
	assert_true(InputRouter.Action.CONFIRM in filtered, "CONFIRM should pass through")
	# MOVE_LEFT should be filtered out in UI mode
	assert_false(InputRouter.Action.MOVE_LEFT in filtered, "MOVE_LEFT should not pass in UI mode")
