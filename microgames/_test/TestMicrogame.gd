extends MicrogameBase
## Test microgame for framework/integration tests

enum ResolveMode {
	NONE,
	ON_INPUT_SUCCESS,
	ON_INPUT_FAILURE,
	AFTER_DELAY_SUCCESS,
	AFTER_DELAY_FAILURE
}

@export var resolve_mode: ResolveMode = ResolveMode.NONE
@export var resolve_delay_sec: float = 0.0

var _delay_remaining: float = 0.0


func on_activate() -> void:
	input_policy = InputRouter.InputPolicy.new(false, false, false)
	_delay_remaining = resolve_delay_sec


func on_active_start() -> void:
	if resolve_mode == ResolveMode.AFTER_DELAY_SUCCESS or resolve_mode == ResolveMode.AFTER_DELAY_FAILURE:
		set_process(true)


func on_actions(_actions: Array) -> void:
	if is_resolved():
		return
	if resolve_mode == ResolveMode.ON_INPUT_SUCCESS:
		resolve_success()
	elif resolve_mode == ResolveMode.ON_INPUT_FAILURE:
		resolve_failure()
	else:
		# Any input still counts as activity, but no resolve in NONE mode
		pass


func on_active_end() -> void:
	set_process(false)


func _process(delta: float) -> void:
	if is_resolved():
		return
	if resolve_mode == ResolveMode.AFTER_DELAY_SUCCESS or resolve_mode == ResolveMode.AFTER_DELAY_FAILURE:
		_delay_remaining -= delta
		if _delay_remaining <= 0.0:
			if resolve_mode == ResolveMode.AFTER_DELAY_SUCCESS:
				resolve_success()
			else:
				resolve_failure()
			set_process(false)


## Test helpers
func set_resolve_on_input(success: bool) -> void:
	resolve_mode = ResolveMode.ON_INPUT_SUCCESS if success else ResolveMode.ON_INPUT_FAILURE


func set_resolve_after_delay(seconds: float, success: bool) -> void:
	resolve_delay_sec = seconds
	_delay_remaining = seconds
	resolve_mode = ResolveMode.AFTER_DELAY_SUCCESS if success else ResolveMode.AFTER_DELAY_FAILURE


func set_no_resolve() -> void:
	resolve_mode = ResolveMode.NONE
