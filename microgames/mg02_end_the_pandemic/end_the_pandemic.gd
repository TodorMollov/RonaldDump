extends MicrogameBase
const ViewScenePath := "res://microgames/mg02_end_the_pandemic/end_the_pandemic_view.tscn"

const INTRO_DURATION := 0.18
const MIN_WAIT_DURATION := 3.0
const MAX_WAIT_DURATION := 4.0

enum State {
	INTRO,
	WAITING,
	FAIL_RESOLVE,
	SUCCESS_RESOLVE
}

var current_state := State.INTRO
var intro_elapsed := 0.0
var waiting_elapsed := 0.0
var waiting_duration := MIN_WAIT_DURATION
var presentation_enabled := true

var view_instance: Control = null
var timer_bar: ProgressBar
var ronald_panel: Control
var noise_nodes: Array[Control] = []
var noise_base_positions: Array[Vector2] = []

var duration_rng := RandomNumberGenerator.new()
var noise_rng := RandomNumberGenerator.new()
var visual_phase := 0.0

func _ready() -> void:
	set_process(false)
	set_process_input(false)

func on_activate() -> void:
	super.on_activate()
	input_policy = InputRouter.InputPolicy.new(false, true, false, [], [])
	set_process(false)
	set_process_input(false)

func on_active_start() -> void:
	super.on_active_start()
	start_microgame()

func on_active_end() -> void:
	super.on_active_end()
	# Ensure processing stops when active phase ends
	set_process(false)
	if not is_resolved():
		force_resolve(Result.FAILURE)

func on_deactivate() -> void:
	super.on_deactivate()
	_cleanup_view()

func get_instruction_text() -> String:
	return "DO NOTHING"

func start_microgame(params := {}) -> void:
	"""Initialize or reset the microgame for a new active phase."""
	presentation_enabled = params.get("presentation_enabled", true)
	if params.has("rng_seed"):
		duration_rng.seed = params["rng_seed"]
	else:
		duration_rng.randomize()
	noise_rng.seed = duration_rng.randi()

	waiting_duration = _determine_wait_duration(params)
	_waiting_duration_guard()

	current_state = State.INTRO
	intro_elapsed = 0.0
	waiting_elapsed = 0.0
	visual_phase = 0.0

	_cleanup_view()
	_prepare_view()

	_update_timer_visual()
	set_process(true)
	set_process_input(true)

func _determine_wait_duration(params: Dictionary) -> float:
	var candidate = params.get("total_wait_duration_sec", null)
	if candidate != null:
		return clampf(candidate, MIN_WAIT_DURATION, MAX_WAIT_DURATION)
	return duration_rng.randf_range(MIN_WAIT_DURATION, MAX_WAIT_DURATION)

func _waiting_duration_guard() -> void:
	if waiting_duration < MIN_WAIT_DURATION:
		waiting_duration = MIN_WAIT_DURATION

func _prepare_view() -> void:
	if not presentation_enabled:
		return
	if ResourceLoader.exists(ViewScenePath):
		var packed_scene = load(ViewScenePath) as PackedScene
		if packed_scene:
			view_instance = packed_scene.instantiate()
			add_child(view_instance)
			timer_bar = view_instance.get_node_or_null("TimerBar")
			ronald_panel = view_instance.get_node_or_null("RonaldPanel")
			var noise_parent = view_instance.get_node_or_null("NoiseContainer")
			noise_nodes.clear()
			noise_base_positions.clear()
			if noise_parent:
				for child in noise_parent.get_children():
					if child is Control:
						var control_node := child as Control
						noise_nodes.append(control_node)
						noise_base_positions.append(control_node.position)

func _cleanup_view() -> void:
	if view_instance:
		view_instance.queue_free()
	view_instance = null
	timer_bar = null
	ronald_panel = null
	noise_nodes.clear()
	noise_base_positions.clear()

func _process(delta: float) -> void:
	match current_state:
		State.INTRO:
			intro_elapsed += delta
			_animate_noise(delta)
			if intro_elapsed >= INTRO_DURATION:
				_enter_waiting()
		State.WAITING:
			waiting_elapsed += delta
			_animate_noise(delta)
			_update_timer_visual()
			if waiting_elapsed >= waiting_duration:
				_enter_success_state()

func _enter_waiting() -> void:
	current_state = State.WAITING
	waiting_elapsed = 0.0
	visual_phase = 0.0
	_update_timer_visual()

func _enter_fail_state() -> void:
	if is_resolved():
		return
	current_state = State.FAIL_RESOLVE
	set_process(false)
	_paint_ronald(Color(0.85, 0.45, 0.45))
	resolve_failure()
	_cleanup_view()

func _enter_success_state() -> void:
	if is_resolved():
		return
	current_state = State.SUCCESS_RESOLVE
	set_process(false)
	_paint_ronald(Color(0.5, 1.0, 0.5))
	resolve_success()
	_cleanup_view()

func _animate_noise(delta: float) -> void:
	if noise_nodes.is_empty():
		return
	visual_phase += delta
	for index in range(noise_nodes.size()):
		var node = noise_nodes[index]
		if not node:
			continue
		var base = noise_base_positions[index]
		var offset = Vector2(
			sin(visual_phase * (1.1 + index * 0.2)) * 12 + noise_rng.randf_range(-5, 5),
			cos(visual_phase * (0.9 + index * 0.2)) * 10 + noise_rng.randf_range(-4, 4)
		)
		node.position = base + offset

func _update_timer_visual() -> void:
	if not timer_bar:
		return
	var progress = clampf(waiting_elapsed / waiting_duration, 0.0, 1.0)
	timer_bar.value = progress * 100.0

func _paint_ronald(color: Color) -> void:
	if ronald_panel:
		ronald_panel.modulate = color

func on_input(actions: Array) -> void:
	if current_state != State.WAITING or is_resolved():
		return
	if _is_actionable(actions):
		_enter_fail_state()

func _is_actionable(actions: Array) -> bool:
	for action in actions:
		if action == InputRouter.Action.POINTER_POS:
			continue
		return true
	return false

func force_resolve(outcome: int = Result.FAILURE) -> void:
	if outcome == Result.SUCCESS:
		_enter_success_state()
	else:
		_enter_fail_state()
