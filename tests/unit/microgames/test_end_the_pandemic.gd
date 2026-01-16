extends GutTest
## GUT tests for the End The Pandemic microgame (Microgame 02)

var microgame_scene = preload("res://microgames/mg02_end_the_pandemic/MicrogameEndThePandemic.tscn")
var mg: Node = null
var resolved_count := 0
var last_outcome: bool = false
var has_outcome := false

func before_each():
	mg = microgame_scene.instantiate()
	add_child_autofree(mg)
	mg.resolved.connect(_on_resolved)
	resolved_count = 0
	last_outcome = false
	has_outcome = false

func _on_resolved(outcome: bool) -> void:
	resolved_count += 1
	last_outcome = outcome
	has_outcome = true

func tick(seconds: float, step: float = 0.05) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		mg._process(step)
		elapsed += step

func test_success_on_inaction():
	mg.on_activate()
	mg.start_microgame({
		"presentation_enabled": false,
		"total_wait_duration_sec": 3.0,
		"rng_seed": 1
	})

	tick(3.2)

	assert_eq(resolved_count, 1, "Success should occur after timer expires")
	assert_true(has_outcome, "Outcome should be recorded")
	assert_true(last_outcome, "Outcome should be success when doing nothing")

func test_failure_on_key_press():
	mg.on_activate()
	mg.start_microgame({
		"presentation_enabled": false,
		"total_wait_duration_sec": 3.2
	})

	tick(0.25)
	mg.on_input([InputRouter.Action.ANY])

	assert_eq(resolved_count, 1, "Key press should trigger failure instantly")
	assert_true(has_outcome, "Outcome should be recorded")
	assert_false(last_outcome, "Failure outcome should be false")

func test_failure_on_mouse_click():
	mg.on_activate()
	mg.start_microgame({
		"presentation_enabled": false,
		"total_wait_duration_sec": 3.2
	})

	tick(0.25)
	mg.on_input([InputRouter.Action.POINTER_PRIMARY])

	assert_eq(resolved_count, 1, "Mouse click should resolve failure")
	assert_true(has_outcome, "Outcome should be recorded")
	assert_false(last_outcome, "Mouse click should fail the microgame")

func test_mouse_motion_ignored():
	mg.on_activate()
	mg.start_microgame({
		"presentation_enabled": false,
		"total_wait_duration_sec": 3.1
	})

	tick(0.1)
	mg.on_input([InputRouter.Action.POINTER_POS])

	assert_eq(resolved_count, 0, "Mouse move should not trigger resolve")

	tick(3.2)
	assert_eq(resolved_count, 1, "Inaction should still succeed after motion")
	assert_true(has_outcome, "Outcome should be recorded")
	assert_true(last_outcome, "Outcome should still be success")

func test_single_resolution_and_input_ignored_after():
	mg.on_activate()
	mg.start_microgame({
		"presentation_enabled": false,
		"total_wait_duration_sec": 3.2
	})

	tick(0.25)
	mg.on_input([InputRouter.Action.ANY])
	assert_eq(resolved_count, 1, "Should resolve immediately after first actionable input")

	mg.on_input([InputRouter.Action.CONFIRM])
	mg.on_input([InputRouter.Action.POINTER_PRIMARY])
	assert_eq(resolved_count, 1, "Further inputs should not emit resolved again")

func test_force_resolve_respected():
	mg.on_activate()
	mg.start_microgame({
		"presentation_enabled": false
	})

	mg.force_resolve(mg.Result.SUCCESS)
	assert_eq(resolved_count, 1, "Force resolve should emit once")
	assert_true(has_outcome, "Outcome should be recorded")
	assert_true(last_outcome, "Forced success should emit true outcome")

	mg.on_input([InputRouter.Action.ANY])
	tick(0.1)
	assert_eq(resolved_count, 1, "Post-resolve input should be ignored")
