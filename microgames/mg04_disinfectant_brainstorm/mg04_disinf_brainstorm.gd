extends MicrogameBase
const Style = preload("res://ui/placeholder_ui/PlaceholderUIStyle.gd")

## Manual Test Checklist
## - Start microgame; options appear immediately
## - Left/right cycles selection; confirm selects
## - Mouse click selects option
## - Select absurd option to succeed; other choices fail
## - Timeout without selection fails
## - After resolve, inputs do nothing

enum State {
	INTRO,
	CHOICE_ACTIVE,
	SUCCESS_RESOLVE,
	FAIL_RESOLVE
}

const INTRO_MIN := 0.0
const INTRO_MAX := 0.2
const DURATION_MIN := 3.5
const DURATION_MAX := 4.5

const ABSURD_INDEX := 1

@onready var option_a: Button = $UI/OptionsRow/OptionA
@onready var option_b: Button = $UI/OptionsRow/OptionB
@onready var option_c: Button = $UI/OptionsRow/OptionC
@onready var hint_label: Label = $UI/HintLabel
@onready var timer_bar: TextureProgressBar = $UI/TimerBar
@onready var ronald_sprite: ColorRect = $Ronald/RonaldSprite
@onready var ronald_label: Label = $Ronald/RonaldLabel
@onready var state_label: Label = $Debug/StateLabel

var _state: State = State.INTRO
var _resolved := false
var _selected_index := 0
var _absurd_index := ABSURD_INDEX

var _intro_duration := 0.1
var _duration_seconds := 4.0
var _elapsed := 0.0
var _intro_elapsed := 0.0

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	call_deferred("_apply_full_rect")
	_setup_buttons()
	set_process(false)

func activate(_context := {}) -> void:
	is_active = true
	microgame_result = Result.NONE
	on_activate()

func on_activate() -> void:
	super.on_activate()
	input_policy = InputRouter.InputPolicy.new(false, false, false, [
		InputRouter.Action.MOVE_LEFT,
		InputRouter.Action.MOVE_RIGHT,
		InputRouter.Action.CONFIRM
	], [])
	start_microgame()

func on_active_start() -> void:
	super.on_active_start()
	set_process(true)

func on_active_end() -> void:
	super.on_active_end()
	set_process(false)
	if not is_resolved():
		force_resolve(Result.FAILURE)

func on_deactivate() -> void:
	super.on_deactivate()
	is_active = false
	set_process(false)

func get_instruction_text() -> String:
	return "KILL THE VIRUS"

func get_input_policy() -> InputRouter.InputPolicy:
	return input_policy

func on_input(actions: Array) -> void:
	if _resolved or _state != State.CHOICE_ACTIVE:
		return
	for action in actions:
		match action:
			InputRouter.Action.MOVE_LEFT:
				_cycle_selection(-1)
			InputRouter.Action.MOVE_RIGHT:
				_cycle_selection(1)
			InputRouter.Action.CONFIRM:
				_select_current()
			_:
				pass

func force_resolve(outcome: int = Result.FAILURE) -> void:
	if _resolved:
		return
	if outcome == Result.SUCCESS:
		_resolve_success()
	else:
		_resolve_fail()

func start_microgame(params := {}) -> void:
	_resolved = false
	_elapsed = 0.0
	_intro_elapsed = 0.0
	_selected_index = 0
	_absurd_index = ABSURD_INDEX
	_state = State.INTRO
	call_deferred("_apply_full_rect")
	
	var rng_seed = params.get("rng_seed", null)
	if rng_seed != null:
		_rng.seed = rng_seed
	else:
		_rng.randomize()
	_intro_duration = params.get("intro_sec", _rng.randf_range(INTRO_MIN, INTRO_MAX))
	_duration_seconds = params.get("duration_sec", _rng.randf_range(DURATION_MIN, DURATION_MAX))
	
	_update_selection_visual()
	_update_timer_visual()
	_update_state_label()

func set_rng(rng: RandomNumberGenerator) -> void:
	_rng = rng

func set_duration_seconds(value: float) -> void:
	_duration_seconds = value

func set_intro_seconds(value: float) -> void:
	_intro_duration = value

func _process(delta: float) -> void:
	if _resolved:
		return
	
	match _state:
		State.INTRO:
			_intro_elapsed += delta
			if _intro_elapsed >= _intro_duration:
				_state = State.CHOICE_ACTIVE
				_update_selection_visual()
				_update_state_label()
		State.CHOICE_ACTIVE:
			_elapsed += delta
			_update_timer_visual()
			if _elapsed >= _duration_seconds:
				_resolve_fail()

func _setup_buttons() -> void:
	option_a.pressed.connect(func(): _on_option_pressed(0))
	option_b.pressed.connect(func(): _on_option_pressed(1))
	option_c.pressed.connect(func(): _on_option_pressed(2))
	option_a.focus_mode = Control.FOCUS_ALL
	option_b.focus_mode = Control.FOCUS_ALL
	option_c.focus_mode = Control.FOCUS_ALL
	# Enable keyboard focus navigation between options (standalone friendly)
	option_a.focus_neighbor_left = option_c.get_path()
	option_a.focus_neighbor_right = option_b.get_path()
	option_b.focus_neighbor_left = option_a.get_path()
	option_b.focus_neighbor_right = option_c.get_path()
	option_c.focus_neighbor_left = option_b.get_path()
	option_c.focus_neighbor_right = option_a.get_path()
	hint_label.text = "THINK BIG"
	option_b.text = "!!! DRINK IT !!!"
	option_a.text = "Consult experts"
	option_c.text = "Run clinical trials"

func _apply_full_rect() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var ui_node = get_node_or_null("UI")
	if ui_node is Control:
		(ui_node as Control).anchors_preset = Control.PRESET_FULL_RECT
		(ui_node as Control).set_deferred("size", viewport_size)

func _on_option_pressed(index: int) -> void:
	if _resolved or _state != State.CHOICE_ACTIVE:
		return
	_selected_index = index
	_update_selection_visual()
	_select_current()

func _select_current() -> void:
	if _selected_index == _absurd_index:
		_resolve_success()
	else:
		_resolve_fail()

func _cycle_selection(delta: int) -> void:
	var next = (_selected_index + delta) % 3
	if next < 0:
		next = 2
	_selected_index = next
	_update_selection_visual()

func _update_selection_visual() -> void:
	var buttons = [option_a, option_b, option_c]
	for i in range(buttons.size()):
		var button = buttons[i]
		if i == _selected_index:
			button.grab_focus()
			button.modulate = Style.BUBBLE_BG
		else:
			button.modulate = Color.WHITE

func _update_timer_visual() -> void:
	if timer_bar == null:
		return
	var progress = clampf(_elapsed / _duration_seconds, 0.0, 1.0)
	timer_bar.value = progress * 100.0

func _resolve_success() -> void:
	if _resolved:
		return
	_resolved = true
	_state = State.SUCCESS_RESOLVE
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

func _update_state_label() -> void:
	if state_label:
		state_label.text = "State: %s" % State.keys()[_state]

## Test helpers
func _get_selected_index_for_tests() -> int:
	return _selected_index

func _set_selected_index_for_tests(value: int) -> void:
	_selected_index = value
	_update_selection_visual()

func _get_duration_for_tests() -> float:
	return _duration_seconds
