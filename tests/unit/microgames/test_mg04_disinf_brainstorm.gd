extends GutTest
## GUT tests for Microgame 04 - Disinfectant Brainstorm

var scene = preload("res://microgames/mg04_disinfectant_brainstorm/Microgame04_DisinfBrainstorm.tscn")
var mg = null
var resolved_count := 0
var last_outcome := false
var has_outcome := false

func before_each():
	mg = scene.instantiate()
	add_child_autofree(mg)
	mg.resolved.connect(_on_resolved)
	resolved_count = 0
	last_outcome = false
	has_outcome = false

func _on_resolved(outcome: bool) -> void:
	resolved_count += 1
	last_outcome = outcome
	has_outcome = true

func tick(seconds: float, step: float = 0.016) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		mg._process(step)
		elapsed += step

func start_active():
	mg.start_microgame({ "intro_sec": 0.0, "duration_sec": 1.0 })
	mg.on_active_start()
	tick(0.02)

func test_input_policy():
	mg.on_activate()
	var policy = mg.get_input_policy()
	assert_false(policy.success_on_any_input, "success_on_any_input should be false")
	assert_false(policy.fail_on_any_input, "fail_on_any_input should be false")
	assert_false(policy.pointer_move_counts_as_input, "pointer_move_counts_as_input should be false")
	assert_eq(policy.allowed_actions.size(), 3, "allowed_actions should contain three actions")
	assert_true(policy.allowed_actions.has(InputRouter.Action.MOVE_LEFT))
	assert_true(policy.allowed_actions.has(InputRouter.Action.MOVE_RIGHT))
	assert_true(policy.allowed_actions.has(InputRouter.Action.CONFIRM))

func test_buttons_visible_and_clickable():
	mg.on_activate()
	start_active()
	await get_tree().process_frame
	await get_tree().process_frame
	var option_a = mg.get_node("UI/OptionsRow/OptionA") as Button
	var option_b = mg.get_node("UI/OptionsRow/OptionB") as Button
	assert_true(option_a.is_visible_in_tree(), "OptionA should be visible")
	assert_true(option_b.is_visible_in_tree(), "OptionB should be visible")
	assert_gt(option_a.size.x, 0.0, "OptionA should have width")
	option_b.emit_signal("pressed")
	assert_eq(resolved_count, 1, "Click should resolve once")
	assert_true(last_outcome, "Absurd choice should be SUCCESS")

func test_success_absurd_option_mouse():
	mg.on_activate()
	start_active()
	var option = mg.get_node("UI/OptionsRow/OptionB") as Button
	option.emit_signal("pressed")
	assert_eq(resolved_count, 1, "Should resolve once")
	assert_true(has_outcome, "Outcome should be recorded")
	assert_true(last_outcome, "Absurd choice should be SUCCESS")

func test_success_absurd_option_keyboard():
	mg.on_activate()
	start_active()
	mg.on_actions([InputRouter.Action.MOVE_RIGHT])
	mg.on_actions([InputRouter.Action.CONFIRM])
	assert_eq(resolved_count, 1, "Should resolve once")
	assert_true(last_outcome, "Absurd choice should be SUCCESS")

func test_fail_reasonable_option_mouse():
	mg.on_activate()
	start_active()
	var option = mg.get_node("UI/OptionsRow/OptionA") as Button
	option.emit_signal("pressed")
	assert_eq(resolved_count, 1, "Should resolve once")
	assert_false(last_outcome, "Reasonable choice should be FAIL")

func test_fail_reasonable_option_keyboard():
	mg.on_activate()
	start_active()
	mg.on_actions([InputRouter.Action.CONFIRM])
	assert_eq(resolved_count, 1, "Should resolve once")
	assert_false(last_outcome, "Default choice should be FAIL")

func test_timeout_fails():
	mg.on_activate()
	mg.start_microgame({ "intro_sec": 0.0, "duration_sec": 0.1 })
	mg.on_active_start()
	tick(0.2)
	assert_eq(resolved_count, 1, "Timeout should resolve once")
	assert_false(last_outcome, "Timeout should be FAIL")

func test_mouse_motion_does_not_resolve():
	mg.on_activate()
	start_active()
	mg.on_actions([InputRouter.Action.POINTER_POS])
	tick(0.1)
	assert_eq(resolved_count, 0, "Pointer motion should not resolve")

func test_left_right_cycles_selection():
	mg.on_activate()
	start_active()
	assert_eq(mg._get_selected_index_for_tests(), 0)
	mg.on_actions([InputRouter.Action.MOVE_RIGHT])
	assert_eq(mg._get_selected_index_for_tests(), 1)
	mg.on_actions([InputRouter.Action.MOVE_RIGHT])
	assert_eq(mg._get_selected_index_for_tests(), 2)
	mg.on_actions([InputRouter.Action.MOVE_RIGHT])
	assert_eq(mg._get_selected_index_for_tests(), 0)
	mg.on_actions([InputRouter.Action.MOVE_LEFT])
	assert_eq(mg._get_selected_index_for_tests(), 2)

func test_resolve_once_on_spam():
	mg.on_activate()
	start_active()
	mg.on_actions([InputRouter.Action.MOVE_RIGHT])
	mg.on_actions([InputRouter.Action.CONFIRM])
	mg.on_actions([InputRouter.Action.CONFIRM])
	var option = mg.get_node("UI/OptionsRow/OptionB") as Button
	option.emit_signal("pressed")
	assert_eq(resolved_count, 1, "Resolved should emit once")

func test_force_resolve_blocks_input():
	mg.on_activate()
	start_active()
	mg.force_resolve(mg.Result.FAILURE)
	assert_eq(resolved_count, 1, "Force resolve should emit once")
	mg.on_actions([InputRouter.Action.MOVE_RIGHT])
	mg.on_actions([InputRouter.Action.CONFIRM])
	assert_eq(resolved_count, 1, "Post-force input should be ignored")
