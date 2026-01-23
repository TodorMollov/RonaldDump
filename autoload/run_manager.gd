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

	# Ensure registry/sequence manager are initialized (defensive)
	if SequenceManager.registry == null:
		SequenceManager.initialize(MicrogameRegistry)

	# Debug trace: starting selection
	print("[RunManager] Selecting next microgame. Entries:", MicrogameRegistry.get_enabled_entries().size())

	# Select next microgame
	var entry = SequenceManager.select_next_microgame()
	if not entry:
		# No microgames available - end run gracefully
		# This is valid during development when no production microgames exist
		# Try to repopulate once from MicrogameRegistry if empty
		if MicrogameRegistry.get_enabled_entries().size() == 0:
			print("[RunManager] No enabled entries; ending run.")
			_end_run()
			return
		SequenceManager.initialize(MicrogameRegistry)
		entry = SequenceManager.select_next_microgame()
		if not entry:
			print("[RunManager] Selection still null after reinit; ending run.")
			_end_run()
		return

	print("[RunManager] Selected microgame:", entry.id)
	
	# Load and instantiate microgame
	var microgame_scene = ResourceLoader.load(entry.scene_path, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if not microgame_scene:
		push_error("RunManager: Failed to load microgame scene: " + entry.scene_path)
		_end_run()
		return
	
	active_microgame = microgame_scene.instantiate()
	if not active_microgame or not active_microgame.has_method("activate"):
		push_error("RunManager: Microgame scene is not MicrogameBase: " + entry.scene_path)
		_end_run()
		return
	
	microgame_container.add_child(active_microgame)
	active_microgame.resolved.connect(_on_microgame_resolved)
	
	# Start microgame sequence
	microgame_sequence_started.emit()
	active_microgame.activate({ "run_mode": current_mode })
	
	# Start INSTRUCTION phase
	GlobalTimingController.start_instruction()
	var instruction = active_microgame.get_instruction_text()
	microgame_instruction_shown.emit(instruction)
	
	# Wait for instruction to complete
	await GlobalTimingController.phase_complete
	
	# Start ACTIVE phase
	await _start_active_phase()


func _start_active_phase() -> void:
	if not active_microgame or current_state != RunState.RUNNING:
		return
	
	GlobalTimingController.start_active()
	
	# Set up input routing
	var policy = active_microgame.get_input_policy()
	InputRouter.set_input_policy(policy)
	InputRouter.set_gameplay_mode()
	InputRouter.enable_input()
	
	# Safely connect (disconnect first if already connected)
	if InputRouter.input_delivered.is_connected(_on_input_delivered):
		InputRouter.input_delivered.disconnect(_on_input_delivered)
	InputRouter.input_delivered.connect(_on_input_delivered)
	
	active_microgame.on_active_start()
	microgame_active.emit()
	
	# Wait for active phase to complete (or early resolve)
	await GlobalTimingController.phase_complete
	
	# Disable input
	InputRouter.disable_input()
	
	# Safely disconnect
	if InputRouter.input_delivered.is_connected(_on_input_delivered):
		InputRouter.input_delivered.disconnect(_on_input_delivered)
	
	# Force resolve if not already resolved
	if active_microgame and not active_microgame.is_resolved():
		active_microgame.on_active_end()
	
	# Finish the microgame (whether it resolved early or timed out)
	if active_microgame:
		var success = active_microgame.get_result() == MicrogameBase.Result.SUCCESS
		await _finish_microgame(success)


func _on_input_delivered(actions: Array) -> void:
	if active_microgame and active_microgame.is_active:
		active_microgame.on_actions(actions)


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
	
	# Neutral resolve: do not increment chaos
	active_microgame.microgame_result = MicrogameBase.Result.SUCCESS
	active_microgame.deactivate()
	active_microgame.queue_free()
	active_microgame = null


func _finish_microgame(success: bool) -> void:
	if not active_microgame:
		print("[RunManager._finish_microgame] No active microgame; returning early.")
		return
	
	print("[RunManager._finish_microgame] Starting cleanup.")
	
	# Start RESOLVE phase (if not already running)
	if GlobalTimingController.current_phase != GlobalTimingController.Phase.RESOLVE:
		print("[RunManager._finish_microgame] Starting RESOLVE phase.")
		GlobalTimingController.start_resolve()
	microgame_resolved.emit(success)
	print("[RunManager._finish_microgame] Emitted signal. Success:", success)
	
	# Increment chaos
	ChaosManager.apply_microgame_result(success, false)
	microgames_played += 1
	print("[RunManager._finish_microgame] Microgames played:", microgames_played)
	
	# Wait for resolve to complete
	print("[RunManager._finish_microgame] Awaiting RESOLVE phase...")
	await GlobalTimingController.phase_complete
	print("[RunManager._finish_microgame] RESOLVE complete.")
	
	# Clean up microgame
	print("[RunManager._finish_microgame] Deactivating microgame...")
	if active_microgame:
		active_microgame.on_deactivate()
		print("[RunManager._finish_microgame] Freeing microgame...")
		active_microgame.queue_free()
		active_microgame = null
	print("[RunManager._finish_microgame] Flushing input...")
	
	# Flush input for next microgame
	InputRouter.flush_input()
	
	# Start next microgame
	print("[RunManager._finish_microgame] Awaiting frame...")
	await get_tree().process_frame
	print("[RunManager._finish_microgame] Calling _start_next_microgame()...")
	await _start_next_microgame()
	print("[RunManager._finish_microgame] Complete.")


func _end_run() -> void:
	current_state = RunState.COMPLETED
	set_process(false)
	
	# Clean up active microgame if any
	if active_microgame:
		_force_neutral_resolve()
	
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
