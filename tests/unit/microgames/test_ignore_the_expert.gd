extends GutTest

const MG_PATH := "res://microgames/mg01_ignore_the_expert/MicrogameIgnoreTheExpert.tscn"
const MicrogameBase := preload("res://framework/microgame_base.gd")

var microgame: Node = null


func before_each() -> void:
	microgame = load(MG_PATH).instantiate()
	add_child(microgame)
	await wait_frames(1)


func after_each() -> void:
	if microgame:
		microgame.queue_free()
		await wait_frames(1)
	microgame = null


func test_input_policy_matches_spec():
	var policy = microgame.get_input_policy()
	assert_true(policy.success_on_any_input, "Any input should succeed")
	assert_false(policy.pointer_move_counts_as_input, "Pointer move must not count as input")


func test_intro_ignores_input():
	microgame._init_microgame({"presentation_enabled": false})
	microgame._running = true
	microgame.current_state = microgame.State.INTRO
	microgame._handle_player_input()
	assert_eq(microgame.microgame_result, MicrogameBase.Result.NONE, "Intro should not resolve")


func test_mouse_motion_never_counts_as_input():
	microgame._init_microgame({"presentation_enabled": false})
	microgame._running = true
	microgame.current_state = microgame.State.ADVICE_ACTIVE
	var motion := InputEventMouseMotion.new()
	microgame._unhandled_input(motion)
	assert_eq(microgame.microgame_result, MicrogameBase.Result.NONE, "Mouse move must not resolve")


func test_success_when_input_before_deadline():
	microgame._init_microgame({"presentation_enabled": false})
	microgame._running = true
	microgame.current_state = microgame.State.ADVICE_ACTIVE
	microgame._handle_player_input()
	assert_eq(microgame.microgame_result, MicrogameBase.Result.SUCCESS, "Input should resolve success")


func test_fail_when_deadline_passes():
	microgame._init_microgame({"presentation_enabled": false, "advice_deadline_sec": 0.5, "total_duration_sec": 4.0})
	microgame._running = true
	microgame.current_state = microgame.State.ADVICE_ACTIVE
	microgame._process(0.5)
	assert_eq(microgame.microgame_result, MicrogameBase.Result.FAILURE, "Deadline expiry should fail")


func test_fail_when_total_duration_hits_without_input():
	microgame._init_microgame({"presentation_enabled": false, "intro_duration_sec": 0.2, "total_duration_sec": 0.6, "advice_deadline_sec": 0.55})
	microgame._running = true
	microgame.current_state = microgame.State.ADVICE_ACTIVE
	microgame._intro_elapsed = 0.3
	microgame._active_elapsed = 0.3
	microgame._process(0.1)
	assert_eq(microgame.microgame_result, MicrogameBase.Result.FAILURE, "Total timeout should fail")


func test_resolved_emitted_once_inputs_afterwards_ignored():
	microgame._init_microgame({"presentation_enabled": false})
	microgame._running = true
	microgame.current_state = microgame.State.ADVICE_ACTIVE
	var resolve_count := 0
	microgame.resolved.connect(func(_outcome):
		resolve_count += 1
	)
	microgame._handle_player_input()
	microgame._handle_player_input()
	assert_eq(resolve_count, 1, "Resolved should emit once")
	assert_eq(microgame.microgame_result, MicrogameBase.Result.SUCCESS)
