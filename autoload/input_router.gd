extends Node
## InputRouter - Single authority for all player input during gameplay
## Normalizes keyboard, mouse, and controller input into canonical actions

enum Action {
	MOVE_LEFT,
	MOVE_RIGHT,
	CONFIRM,
	ANY,  # Synthetic action
	CANCEL,  # UI/framework only
	POINTER_PRIMARY,
	POINTER_POS  # Mouse movement
}

enum Mode {
	GAMEPLAY,
	UI_MODE
}

## Per-microgame input policy
class InputPolicy:
	var success_on_any_input: bool = false
	var fail_on_any_input: bool = false
	var pointer_move_counts_as_input: bool = false
	var allowed_actions: Array = []
	var blocked_actions: Array = []
	
	func _init(
		p_success_on_any: bool = false,
		p_fail_on_any: bool = false,
		p_pointer_counts: bool = false,
		p_allowed: Array = [],
		p_blocked: Array = []
	):
		success_on_any_input = p_success_on_any
		fail_on_any_input = p_fail_on_any
		pointer_move_counts_as_input = p_pointer_counts
		allowed_actions = p_allowed.duplicate()
		blocked_actions = p_blocked.duplicate()

signal input_delivered(actions: Array)

var current_mode: Mode = Mode.UI_MODE
var current_policy: InputPolicy = null
var input_enabled: bool = false
var dead_zone_frames: int = 0
var first_input_consumed: bool = false

# Frame-local action batch
var _frame_actions: Dictionary = {}
var _any_actionable_input: bool = false
var _pointer_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	set_process_input(true)
	set_process_unhandled_input(false)


func _input(event: InputEvent) -> void:
	if not input_enabled or dead_zone_frames > 0:
		return
	
	if first_input_consumed:
		return
	
	# Collect raw input and normalize to canonical actions
	_collect_input(event)


func _process(_delta: float) -> void:
	# Handle dead zone countdown
	if dead_zone_frames > 0:
		dead_zone_frames -= 1
		return
	
	if not input_enabled:
		return
	
	# Synthesize ANY if actionable input occurred
	if _any_actionable_input and not _frame_actions.has(Action.ANY):
		_frame_actions[Action.ANY] = true
	
	# Apply policy and deliver
	if _frame_actions.size() > 0:
		var filtered_actions = _apply_policy(_frame_actions.keys())
		if filtered_actions.size() > 0:
			input_delivered.emit(filtered_actions)
		
		# Clear frame batch
		_frame_actions.clear()
		_any_actionable_input = false


func _collect_input(event: InputEvent) -> void:
	var actionable = false
	
	# Keyboard
	if event is InputEventKey and event.pressed and not event.echo:
		actionable = true
		match event.keycode:
			KEY_LEFT, KEY_A:
				_frame_actions[Action.MOVE_LEFT] = true
			KEY_RIGHT, KEY_D:
				_frame_actions[Action.MOVE_RIGHT] = true
			KEY_SPACE, KEY_ENTER, KEY_E:
				_frame_actions[Action.CONFIRM] = true
			KEY_ESCAPE:
				_frame_actions[Action.CANCEL] = true
			_:
				# Any other key is still actionable
				pass
	
	# Mouse button
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			actionable = true
			_frame_actions[Action.POINTER_PRIMARY] = true
	
	# Mouse motion
	elif event is InputEventMouseMotion:
		_pointer_position = event.position
		_frame_actions[Action.POINTER_POS] = true
		# Motion is NOT actionable by default
		if current_policy and current_policy.pointer_move_counts_as_input:
			actionable = true
	
	# Controller button
	elif event is InputEventJoypadButton and event.pressed:
		actionable = true
		match event.button_index:
			JOY_BUTTON_DPAD_LEFT:
				_frame_actions[Action.MOVE_LEFT] = true
			JOY_BUTTON_DPAD_RIGHT:
				_frame_actions[Action.MOVE_RIGHT] = true
			JOY_BUTTON_A, JOY_BUTTON_B:
				_frame_actions[Action.CONFIRM] = true
			JOY_BUTTON_BACK, JOY_BUTTON_START:
				_frame_actions[Action.CANCEL] = true
	
	# Controller axis
	elif event is InputEventJoypadMotion:
		if abs(event.axis_value) > 0.5:
			actionable = true
			if event.axis == JOY_AXIS_LEFT_X:
				if event.axis_value < -0.5:
					_frame_actions[Action.MOVE_LEFT] = true
				elif event.axis_value > 0.5:
					_frame_actions[Action.MOVE_RIGHT] = true
	
	if actionable:
		_any_actionable_input = true


func _apply_policy(actions: Array) -> Array:
	if current_mode == Mode.UI_MODE:
		return _apply_ui_mode_filter(actions)
	
	if not current_policy:
		return actions
	
	var filtered: Array = []
	
	for action in actions:
		# Apply blocked list
		if current_policy.blocked_actions.size() > 0 and action in current_policy.blocked_actions:
			continue
		
		# Apply allowed list (if specified, only these pass)
		if current_policy.allowed_actions.size() > 0 and action not in current_policy.allowed_actions:
			continue
		
		filtered.append(action)
	
	return filtered


func _apply_ui_mode_filter(actions: Array) -> Array:
	var filtered: Array = []
	for action in actions:
		if action == Action.CONFIRM or action == Action.ANY or action == Action.POINTER_PRIMARY:
			filtered.append(Action.CONFIRM)  # Normalize to CONFIRM in UI mode
		elif action == Action.CANCEL:
			filtered.append(Action.CANCEL)
	return filtered


## Set the input policy for the active microgame
func set_input_policy(policy: InputPolicy) -> void:
	current_policy = policy
	first_input_consumed = false


## Enable input delivery
func enable_input() -> void:
	input_enabled = true


## Disable input delivery
func disable_input() -> void:
	input_enabled = false
	_flush_input()


## Flush all pending input (called when microgame ends)
func flush_input() -> void:
	_flush_input()
	dead_zone_frames = 1  # Enforce 1-frame dead zone


func _flush_input() -> void:
	_frame_actions.clear()
	_any_actionable_input = false
	first_input_consumed = false


## Mark first input as consumed (first-input dominance rule)
func consume_first_input() -> void:
	first_input_consumed = true


## Switch to gameplay mode
func set_gameplay_mode() -> void:
	current_mode = Mode.GAMEPLAY
	input_enabled = false


## Switch to UI mode
func set_ui_mode() -> void:
	current_mode = Mode.UI_MODE
	current_policy = null
	first_input_consumed = false
	input_enabled = true


## Get current pointer position
func get_pointer_position() -> Vector2:
	return _pointer_position


## Check if specific action is in the batch
func has_action(actions: Array, action: Action) -> bool:
	return action in actions


## Create standard input policies for common microgame types
static func create_any_input_policy() -> InputPolicy:
	"""Ignore the Expert - first input = success"""
	return InputPolicy.new(true, false, false)


static func create_zero_input_policy() -> InputPolicy:
	"""End the Pandemic - any input = failure"""
	return InputPolicy.new(false, true, false)


static func create_directional_policy() -> InputPolicy:
	"""Wall Builder - directional + confirm only"""
	var policy = InputPolicy.new()
	policy.allowed_actions = [Action.MOVE_LEFT, Action.MOVE_RIGHT, Action.CONFIRM]
	return policy
