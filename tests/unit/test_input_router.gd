extends GutTest
## Tests for InputRouter - canonical actions, policies, and dominance rules

var input_router: Node


func before_each():
	input_router = InputRouter
	input_router.flush_input()
	input_router.set_ui_mode()


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
	assert_true(policy.success_on_any_input)
	assert_false(policy.fail_on_any_input)
	assert_false(policy.pointer_move_counts_as_input)


func test_input_policy_creation_zero_input():
	var policy = InputRouter.create_zero_input_policy()
	assert_false(policy.success_on_any_input)
	assert_true(policy.fail_on_any_input)
	assert_false(policy.pointer_move_counts_as_input)


func test_input_policy_creation_directional():
	var policy = InputRouter.create_directional_policy()
	assert_true(InputRouter.Action.MOVE_LEFT in policy.allowed_actions)
	assert_true(InputRouter.Action.MOVE_RIGHT in policy.allowed_actions)
	assert_true(InputRouter.Action.CONFIRM in policy.allowed_actions)


func test_flush_input_creates_dead_zone():
	input_router.flush_input()
	assert_eq(input_router.dead_zone_frames, 1)


func test_ui_mode_filter():
	input_router.set_ui_mode()
	var actions = [InputRouter.Action.CONFIRM, InputRouter.Action.ANY, InputRouter.Action.MOVE_LEFT]
	var filtered = input_router._apply_ui_mode_filter(actions)
	assert_true(InputRouter.Action.CONFIRM in filtered)
	assert_false(InputRouter.Action.MOVE_LEFT in filtered)


func test_mouse_motion_not_actionable_by_default():
	input_router.set_gameplay_mode()
	input_router.enable_input()
	input_router._frame_actions.clear()
	input_router._any_actionable_input = false
	var motion = InputEventMouseMotion.new()
	input_router._collect_input(motion)
	assert_false(input_router._any_actionable_input)


func test_mouse_motion_actionable_when_enabled():
	var policy = InputRouter.InputPolicy.new()
	policy.pointer_move_counts_as_input = true
	input_router.set_input_policy(policy)
	input_router.set_gameplay_mode()
	input_router.enable_input()
	input_router._frame_actions.clear()
	input_router._any_actionable_input = false
	var motion = InputEventMouseMotion.new()
	input_router._collect_input(motion)
	assert_true(input_router._any_actionable_input)


func test_joypad_motion_is_ignored():
	input_router.set_gameplay_mode()
	input_router.enable_input()
	input_router._frame_actions.clear()
	input_router._any_actionable_input = false
	var motion = InputEventJoypadMotion.new()
	motion.axis = JOY_AXIS_LEFT_X
	motion.axis_value = 1.0
	input_router._collect_input(motion)
	assert_false(input_router._any_actionable_input)
