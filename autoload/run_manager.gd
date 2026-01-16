extends Node
## RunManager - Owns run lifecycle, forces resolve on run end, always ends in YOU WON

signal run_started(mode: ChaosManager.RunMode)
signal microgame_sequence_started()
signal microgame_instruction_shown(text: String)
signal microgame_active()
signal microgame_resolved(success: bool)
signal run_completed()

enum RunState {
	IDLE,
	RUNNING,
	COMPLETED
}

const RUN_DURATION_NORMAL: float = 150.0
const RUN_DURATION_UNHINGED: float = 150.0
const RUN_DURATION_ENDLESS: float = 999999.0

var current_state: RunState = RunState.IDLE
var current_mode: ChaosManager.RunMode = ChaosManager.RunMode.NORMAL
var run_timer: float = 0.0
var run_duration: float = 0.0
var microgames_played: int = 0

var active_microgame = null
var microgame_container: Node = null
var pending_mode: ChaosManager.RunMode = ChaosManager.RunMode.NORMAL


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	if current_state != RunState.RUNNING:
		return
	
	run_timer += delta
	
	# Check if run should end
	if run_timer >= run_duration:
		_end_run()


func start_run(mode: ChaosManager.RunMode, container: Node) -> void:
	if current_state != RunState.IDLE:
		push_warning("RunManager: Cannot start run, already running")
		return
	
	current_state = RunState.RUNNING
	current_mode = mode
	microgame_container = container
	run_timer = 0.0
	microgames_played = 0
	
	# Set duration based on mode
	match mode:
		ChaosManager.RunMode.NORMAL:
			run_duration = RUN_DURATION_NORMAL
		ChaosManager.RunMode.UNHINGED:
			run_duration = RUN_DURATION_UNHINGED
		ChaosManager.RunMode.ENDLESS:
			run_duration = RUN_DURATION_ENDLESS
	
	# Initialize managers
	ChaosManager.reset(mode)
	SequenceManager.reset()
	
	set_process(true)
	run_started.emit(mode)
	
	# Start first microgame after a frame
	await get_tree().process_frame
	_start_next_microgame()


func _start_next_microgame() -> void:
	if current_state != RunState.RUNNING:
		return
	
	# Check if run should end
	if run_timer >= run_duration:
		_end_run()
		return
	
	# Select next microgame
	var entry = SequenceManager.select_next_microgame()
	if not entry:
		push_error("RunManager: Failed to select microgame")
		_end_run()
		return
	
	# Load and instantiate microgame
	var microgame_scene = load(entry.scene_path) as PackedScene
	if not microgame_scene:
		push_error("RunManager: Failed to load microgame scene: " + entry.scene_path)
		_end_run()
		return
	
	active_microgame = microgame_scene.instantiate()
	if not active_microgame or not active_microgame.has_method("on_activate"):
		push_error("RunManager: Microgame scene is not MicrogameBase: " + entry.scene_path)
		_end_run()
		return
	
	microgame_container.add_child(active_microgame)
	active_microgame.resolved.connect(_on_microgame_resolved)
	
	# Start microgame sequence
	microgame_sequence_started.emit()
	active_microgame.on_activate()
	
	# Start INSTRUCTION phase
	GlobalTimingController.start_instruction()
	var instruction = active_microgame.get_instruction_text()
	microgame_instruction_shown.emit(instruction)
	
	# Wait for instruction to complete
	await GlobalTimingController.phase_complete
	
	# Start ACTIVE phase
	_start_active_phase()


func _start_active_phase() -> void:
	if not active_microgame or current_state != RunState.RUNNING:
		return
	
	GlobalTimingController.start_active()
	
	# Set up input routing
	var policy = active_microgame.get_input_policy()
	InputRouter.set_input_policy(policy)
	InputRouter.set_gameplay_mode()
	InputRouter.enable_input()
	InputRouter.input_delivered.connect(_on_input_delivered)
	
	active_microgame.on_active_start()
	microgame_active.emit()
	
	# Wait for active phase to complete (or early resolve)
	await GlobalTimingController.phase_complete
	
	# Disable input
	InputRouter.disable_input()
	InputRouter.input_delivered.disconnect(_on_input_delivered)
	
	# Force resolve if not already resolved
	if active_microgame and not active_microgame.is_resolved():
		active_microgame.on_active_end()
	
	# Finish the microgame (whether it resolved early or timed out)
	if active_microgame:
		var success = active_microgame.get_result() == MicrogameBase.Result.SUCCESS
		_finish_microgame(success)


func _on_input_delivered(actions: Array) -> void:
	if active_microgame and active_microgame.is_active:
		active_microgame.on_input(actions)


func _on_microgame_resolved(_success: bool) -> void:
	if not active_microgame:
		return
	
	# Force immediate resolve (this will trigger phase_complete)
	# The result is already set in the microgame via resolve_success()/resolve_failure()
	GlobalTimingController.force_resolve_immediate()


func _force_neutral_resolve() -> void:
	"""Force neutral resolve on run end (doesn't count as success or failure)"""
	if not active_microgame or active_microgame.is_resolved():
		return
	
	# For chaos purposes, treat as neutral (still increment)
	active_microgame.microgame_result = 1  # SUCCESS
	_finish_microgame(true)


func _finish_microgame(success: bool) -> void:
	if not active_microgame:
		return
	
	# Start RESOLVE phase
	GlobalTimingController.start_resolve()
	microgame_resolved.emit(success)
	
	# Increment chaos
	ChaosManager.increment_chaos()
	microgames_played += 1
	
	# Wait for resolve to complete
	await GlobalTimingController.phase_complete
	
	# Clean up microgame
	active_microgame.on_deactivate()
	active_microgame.queue_free()
	active_microgame = null
	
	# Flush input for next microgame
	InputRouter.flush_input()
	
	# Start next microgame
	await get_tree().process_frame
	_start_next_microgame()


func _end_run() -> void:
	current_state = RunState.COMPLETED
	set_process(false)
	
	# Clean up active microgame if any
	if active_microgame:
		active_microgame.queue_free()
		active_microgame = null
	
	GlobalTimingController.stop()
	InputRouter.set_ui_mode()
	
	run_completed.emit()


func get_run_progress() -> float:
	if run_duration <= 0.0:
		return 0.0
	return clampf(run_timer / run_duration, 0.0, 1.0)


func get_run_time_remaining() -> float:
	return maxf(0.0, run_duration - run_timer)


func is_running() -> bool:
	return current_state == RunState.RUNNING


func reset() -> void:
	current_state = RunState.IDLE
	run_timer = 0.0
	microgames_played = 0
	active_microgame = null
	microgame_container = null
	set_process(false)
