extends MicrogameBase
const Style = preload("res://ui/placeholder_ui/PlaceholderUIStyle.gd")

## Manual Test Checklist
## - Start microgame; sides/stamp/progress visible immediately
## - Mash confirm (keyboard/mouse click) advances progress
## - Rate limit prevents held/rapid spam from over-counting
## - Fill meter before timeout → SUCCESS
## - Timeout before completion → FAIL
## - After resolve, inputs do nothing

enum State {
	INTRO,
	MASH_ACTIVE,
	SUCCESS_RESOLVE,
	FAIL_RESOLVE
}

const INTRO_MIN := 0.0
const INTRO_MAX := 0.12
const DURATION_MIN := 2.6
const DURATION_MAX := 3.4

const TARGET_PPS := 9.0
const REQUIRED_MIN := 16
const REQUIRED_MAX := 30
const CONFIRM_COOLDOWN := 0.035  # Faster cadence
const CONFIRM_ACTION := "ui_accept"

@onready var visual_root: Node2D = $VisualRoot
@onready var left_side: ColorRect = $VisualRoot/LeftSide
@onready var right_side: ColorRect = $VisualRoot/RightSide
@onready var peace_stamp: Label = $VisualRoot/PeaceStamp
@onready var progress_bar: TextureProgressBar = $VisualRoot/ProgressBar
@onready var ronald_sprite: ColorRect = $VisualRoot/RonaldRoot/RonaldSprite
@onready var ronald_label: Label = $VisualRoot/RonaldRoot/RonaldLabel

var _state: State = State.INTRO
var _resolved := false
var _elapsed := 0.0
var _intro_elapsed := 0.0
var _duration_seconds := 3.5
var _intro_duration := 0.1

var _required_presses := 30
var _press_count := 0
var _since_last_confirm := 999.0

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_setup_visuals()
	set_process(false)
	set_process_input(false)

func activate(_context := {}) -> void:
	is_active = true
	microgame_result = Result.NONE
	on_activate()

func on_activate() -> void:
	super.on_activate()
	input_policy = InputRouter.InputPolicy.new(false, false, false, [
		InputRouter.Action.CONFIRM,
		InputRouter.Action.POINTER_PRIMARY
	], [])
	start_microgame()

func on_active_start() -> void:
	super.on_active_start()
	set_process(true)
	set_process_input(true)

func on_active_end() -> void:
	super.on_active_end()
	set_process(false)
	set_process_input(false)
	if not is_resolved():
		force_resolve(Result.FAILURE)

func on_deactivate() -> void:
	super.on_deactivate()
	set_process(false)
	set_process_input(false)

func get_instruction_text() -> String:
	return "Make Peace"

func get_input_policy() -> InputRouter.InputPolicy:
	return input_policy

func on_input(actions: Array) -> void:
	if _resolved or _state != State.MASH_ACTIVE:
		return
	for action in actions:
		if action == InputRouter.Action.CONFIRM or action == InputRouter.Action.POINTER_PRIMARY:
			_try_count_confirm()

func force_resolve(outcome: int = Result.FAILURE) -> void:
	if _resolved:
		return
	if outcome == Result.SUCCESS:
		_resolve_success()
	else:
		_resolve_fail()

func start_microgame(params := {}) -> void:
	_resolved = false
	_state = State.INTRO
	_elapsed = 0.0
	_intro_elapsed = 0.0
	_press_count = 0
	_since_last_confirm = 999.0
	
	var rng_seed = params.get("rng_seed", null)
	if rng_seed != null:
		_rng.seed = rng_seed
	else:
		_rng.randomize()
	
	_intro_duration = params.get("intro_sec", _rng.randf_range(INTRO_MIN, INTRO_MAX))
	_duration_seconds = params.get("duration_sec", _rng.randf_range(DURATION_MIN, DURATION_MAX))
	_required_presses = _compute_required_presses(_duration_seconds)
	
	_update_progress_visual()
	_update_state_label()

func set_duration_seconds(value: float) -> void:
	_duration_seconds = value
	_required_presses = _compute_required_presses(_duration_seconds)

func set_intro_seconds(value: float) -> void:
	_intro_duration = value

func set_rng(rng: RandomNumberGenerator) -> void:
	_rng = rng

func _process(delta: float) -> void:
	if _resolved:
		return
	match _state:
		State.INTRO:
			_intro_elapsed += delta
			if _intro_elapsed >= _intro_duration:
				_state = State.MASH_ACTIVE
		State.MASH_ACTIVE:
			_elapsed += delta
			_since_last_confirm += delta
			# Direct keyboard fallback so holding focus without routed actions still works
			if Input.is_action_just_pressed(CONFIRM_ACTION):
				_try_count_confirm()
			if _elapsed >= _duration_seconds:
				_resolve_fail()

func _compute_required_presses(duration_sec: float) -> int:
	var raw = int(ceil(duration_sec * TARGET_PPS))
	return clampi(raw, REQUIRED_MIN, REQUIRED_MAX)

func _try_count_confirm() -> void:
	if _since_last_confirm < CONFIRM_COOLDOWN:
		return
	_since_last_confirm = 0.0
	_press_count += 1
	_punch_stamp()
	_update_progress_visual()
	_update_side_positions()
	if _press_count >= _required_presses:
		_resolve_success()

func _resolve_success() -> void:
	if _resolved:
		return
	_resolved = true
	_state = State.SUCCESS_RESOLVE
	peace_stamp.text = "PEACE!"
	peace_stamp.scale = Vector2(1.4, 1.4)
	ronald_label.text = "Exactly."
	ronald_sprite.modulate = Style.PRIMARY_WARNING
	resolve_success()

func _resolve_fail() -> void:
	if _resolved:
		return
	_resolved = true
	_state = State.FAIL_RESOLVE
	ronald_label.text = "Whatever."
	ronald_sprite.modulate = Style.PRIMARY_URGENT
	resolve_failure()

func _setup_visuals() -> void:
	left_side.position = Vector2(140, 260)
	left_side.size = Vector2(180, 160)
	left_side.color = Style.PRIMARY_WARNING
	
	right_side.position = Vector2(620, 260)
	right_side.size = Vector2(180, 160)
	right_side.color = Style.PRIMARY_URGENT
	
	peace_stamp.position = Vector2(430, 240)
	peace_stamp.scale = Vector2(1.0, 1.0)
	peace_stamp.text = "PEACE"
	peace_stamp.set("theme_override_font_sizes/font_size", 36)
	
	progress_bar.position = Vector2(220, 160)
	progress_bar.size = Vector2(520, 16)
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0
	progress_bar.set("show_percentage", false)
	
	ronald_sprite.position = Vector2(820, 180)
	ronald_sprite.size = Vector2(120, 180)
	ronald_sprite.color = Style.PRIMARY_WARNING
	ronald_label.position = Vector2(830, 370)
	ronald_label.text = "Ronald Dump"
	ronald_label.set("theme_override_font_sizes/font_size", 18)

func _update_progress_visual() -> void:
	if progress_bar == null:
		return
	var progress = clampf(float(_press_count) / float(_required_presses), 0.0, 1.0)
	progress_bar.value = progress * 100.0

func _update_side_positions() -> void:
	var progress = clampf(float(_press_count) / float(_required_presses), 0.0, 1.0)
	var shift = progress * 260.0
	left_side.position.x = 140 + shift
	right_side.position.x = 620 - shift

func _punch_stamp() -> void:
	peace_stamp.scale = Vector2(1.1, 1.1)

func _update_state_label() -> void:
	pass

# --- Test helpers ---
func _get_press_count_for_tests() -> int:
	return _press_count

func _get_required_presses_for_tests() -> int:
	return _required_presses

func _set_elapsed_for_tests(value: float) -> void:
	_elapsed = value
