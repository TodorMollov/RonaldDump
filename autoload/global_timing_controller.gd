extends Node
## GlobalTimingController - Manages microgame phase timing
## INSTRUCTION → ACTIVE → RESOLVE → NEXT

enum Phase {
	NONE,
	INSTRUCTION,
	ACTIVE,
	RESOLVE
}

signal phase_changed(phase: Phase)
signal phase_complete(phase: Phase)

const INSTRUCTION_DURATION: float = 0.6
const ACTIVE_DURATION: float = 4.0
const RESOLVE_DURATION: float = 0.4

## Microgame Duration Specification
## All microgames must follow these rules:
## - 3-5 seconds per microgame
## - Target average: ~4.0 seconds
## - Randomized range: 3.5-4.5 seconds
## - Hard cap: never exceed 5.0 seconds
const MICROGAME_DURATION_MIN: float = 3.5
const MICROGAME_DURATION_MAX: float = 4.5
const MICROGAME_DURATION_HARD_CAP: float = 5.0
const MICROGAME_DURATION_TARGET: float = 4.0

var current_phase: Phase = Phase.NONE
var phase_timer: float = 0.0
var phase_duration: float = 0.0
var phase_running: bool = false


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	if not phase_running:
		return
	
	phase_timer += delta
	
	if phase_timer >= phase_duration:
		_complete_phase()


func start_instruction() -> void:
	_start_phase(Phase.INSTRUCTION, INSTRUCTION_DURATION)


func start_active() -> void:
	_start_phase(Phase.ACTIVE, ACTIVE_DURATION)


func start_resolve() -> void:
	_start_phase(Phase.RESOLVE, RESOLVE_DURATION)


func force_resolve_immediate() -> void:
	"""Force immediate transition to resolve phase"""
	if current_phase == Phase.ACTIVE:
		_complete_phase()
		start_resolve()


func stop() -> void:
	phase_running = false
	current_phase = Phase.NONE
	set_process(false)


func is_active_phase() -> bool:
	return current_phase == Phase.ACTIVE and phase_running


func is_instruction_phase() -> bool:
	return current_phase == Phase.INSTRUCTION and phase_running


func is_resolve_phase() -> bool:
	return current_phase == Phase.RESOLVE and phase_running


func get_phase_progress() -> float:
	"""Returns 0.0 to 1.0 progress through current phase"""
	if phase_duration <= 0.0:
		return 0.0
	return clampf(phase_timer / phase_duration, 0.0, 1.0)


func get_phase_time_remaining() -> float:
	return maxf(0.0, phase_duration - phase_timer)


func _start_phase(phase: Phase, duration: float) -> void:
	current_phase = phase
	phase_timer = 0.0
	phase_duration = duration
	phase_running = true
	set_process(true)
	phase_changed.emit(phase)


func _complete_phase() -> void:
	var completed_phase = current_phase
	phase_running = false
	set_process(false)
	phase_complete.emit(completed_phase)


## Microgame Duration Functions

func get_random_microgame_duration() -> float:
	"""
	Returns a randomized microgame duration within specification.
	Range: 3.5-4.5 seconds, hard cap at 5.0 seconds
	"""
	var duration = randf_range(MICROGAME_DURATION_MIN, MICROGAME_DURATION_MAX)
	duration = minf(duration, MICROGAME_DURATION_HARD_CAP)
	return duration


func get_target_microgame_duration() -> float:
	"""
	Returns the target average microgame duration.
	Use this for testing or when deterministic duration is needed.
	"""
	return MICROGAME_DURATION_TARGET


func get_microgame_duration_with_seed(seed_value: int) -> float:
	"""
	Returns a deterministic randomized duration using provided seed.
	Useful for replays and testing.
	"""
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	var duration = rng.randf_range(MICROGAME_DURATION_MIN, MICROGAME_DURATION_MAX)
	duration = minf(duration, MICROGAME_DURATION_HARD_CAP)
	return duration


func validate_microgame_duration(duration: float) -> bool:
	"""
	Validates if a duration meets the specification.
	Returns true if valid, false otherwise.
	"""
	return duration >= MICROGAME_DURATION_MIN and duration <= MICROGAME_DURATION_HARD_CAP
