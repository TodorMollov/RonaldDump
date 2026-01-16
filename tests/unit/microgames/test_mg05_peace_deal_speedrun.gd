extends GutTest
## GUT tests for Microgame 05 - Peace Deal Speedrun

var scene = preload("res://microgames/mg05_peace_deal_speedrun/Microgame05_PeaceDealSpeedrun.tscn")
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

func start_active(duration: float = 3.5):
	mg.start_microgame({ "intro_sec": 0.0, "duration_sec": duration })
	mg.on_active_start()
	tick(0.02)

func test_input_policy():
	mg.on_activate()
	var policy = mg.get_input_policy()
	assert_false(policy.success_on_any_input)
	assert_false(policy.fail_on_any_input)
	assert_false(policy.pointer_move_counts_as_input)
	assert_true(policy.allowed_actions.has(InputRouter.Action.CONFIRM))
	assert_true(policy.allowed_actions.has(InputRouter.Action.POINTER_PRIMARY))

func test_success_emits_once():
	mg.on_activate()
	start_active(3.5)
	var required = mg._get_required_presses_for_tests()
	for i in range(required):
		mg.on_input([InputRouter.Action.CONFIRM])
		tick(0.09)
	assert_eq(resolved_count, 1, "Should resolve once")
	assert_true(has_outcome)
	assert_true(last_outcome, "Should be SUCCESS")
	mg.on_input([InputRouter.Action.CONFIRM])
	assert_eq(resolved_count, 1, "Should not emit again")

func test_timeout_fails():
	mg.on_activate()
	start_active(0.2)
	tick(0.3)
	assert_eq(resolved_count, 1)
	assert_false(last_outcome, "Timeout should be FAIL")

func test_ignores_non_confirm():
	mg.on_activate()
	start_active(3.5)
	mg.on_input([InputRouter.Action.MOVE_LEFT])
	mg.on_input([InputRouter.Action.POINTER_POS])
	tick(0.2)
	assert_eq(mg._get_press_count_for_tests(), 0, "Non-confirm should not increment")
	assert_eq(resolved_count, 0)

func test_rate_limit():
	mg.on_activate()
	start_active(3.5)
	mg.on_input([InputRouter.Action.CONFIRM])
	mg.on_input([InputRouter.Action.CONFIRM])
	mg.on_input([InputRouter.Action.CONFIRM])
	assert_eq(mg._get_press_count_for_tests(), 1, "Rate limit should block rapid presses")
	tick(0.09)
	mg.on_input([InputRouter.Action.CONFIRM])
	assert_eq(mg._get_press_count_for_tests(), 2)

func test_force_resolve():
	mg.on_activate()
	start_active(3.5)
	mg.force_resolve(mg.Result.FAILURE)
	assert_eq(resolved_count, 1, "Force resolve should emit once")
	mg.on_input([InputRouter.Action.CONFIRM])
	assert_eq(resolved_count, 1)

func test_keyboard_ui_accept_counts():
	mg.on_activate()
	start_active(3.5)
	Input.action_press("ui_accept")
	tick(0.05)
	Input.action_release("ui_accept")
	assert_eq(mg._get_press_count_for_tests(), 1, "ui_accept should count as confirm")
