extends Node
## ChaosManager - Deterministic chaos growth with mode multipliers
## Chaos affects presentation only, never gameplay logic

signal chaos_changed(new_value: float)
signal tier_changed(new_tier: int, fx_config: Dictionary)

enum RunMode {
	NORMAL,
	UNHINGED,
	ENDLESS
}

const CHAOS_MAX := 10.0
const BASE_SUCCESS := 0.22
const BASE_FAILURE := 0.55
const MODE_MULT := {
	RunMode.NORMAL: 1.0,
	RunMode.UNHINGED: 1.6,
	RunMode.ENDLESS: 1.0
}

const TIER_STEP := 1.25
const MAX_TIER := 7

const CHAOS_TIERS := {
	0: {"ui_jitter": false, "screen_shake_strength": 0.0, "noise_opacity": 0.0,  "fake_ui_density": 0.0,  "flicker_interval": 0.0},
	1: {"ui_jitter": true,  "screen_shake_strength": 0.1, "noise_opacity": 0.0,  "fake_ui_density": 0.0,  "flicker_interval": 0.0},
	2: {"ui_jitter": true,  "screen_shake_strength": 0.25,"noise_opacity": 0.0,  "fake_ui_density": 0.0,  "flicker_interval": 0.0},
	3: {"ui_jitter": true,  "screen_shake_strength": 0.35,"noise_opacity": 0.15, "fake_ui_density": 0.0,  "flicker_interval": 0.0},
	4: {"ui_jitter": true,  "screen_shake_strength": 0.45,"noise_opacity": 0.25, "fake_ui_density": 0.15, "flicker_interval": 0.0},
	5: {"ui_jitter": true,  "screen_shake_strength": 0.6, "noise_opacity": 0.35, "fake_ui_density": 0.30, "flicker_interval": 0.20},
	6: {"ui_jitter": true,  "screen_shake_strength": 0.8, "noise_opacity": 0.50, "fake_ui_density": 0.45, "flicker_interval": 0.12},
	7: {"ui_jitter": true,  "screen_shake_strength": 1.0, "noise_opacity": 0.65, "fake_ui_density": 0.65, "flicker_interval": 0.08}
}

var chaos_level: float = 0.0
var current_mode: RunMode = RunMode.NORMAL
var current_tier: int = 0
var microgames_completed: int = 0


func _ready() -> void:
	pass


func reset(mode: RunMode = RunMode.NORMAL) -> void:
	chaos_level = 0.0
	current_mode = mode
	microgames_completed = 0
	_update_tier_and_emit(true)


func apply_microgame_result(success: bool, forced: bool = false) -> void:
	"""Apply chaos based on microgame outcome. Forced resolve adds 0.0."""
	if forced:
		return
	var base = BASE_SUCCESS if success else BASE_FAILURE
	var multiplier = MODE_MULT.get(current_mode, 1.0)
	chaos_level = clampf(chaos_level + (base * multiplier), 0.0, CHAOS_MAX)
	microgames_completed += 1
	_update_tier_and_emit(false)


func increment_chaos() -> void:
	"""Compatibility: treat as success."""
	apply_microgame_result(true, false)


func get_chaos_level() -> float:
	return chaos_level


func get_tier() -> int:
	return int(clampf(floor(chaos_level / TIER_STEP), 0.0, float(MAX_TIER)))


func get_fx_config() -> Dictionary:
	return CHAOS_TIERS.get(get_tier(), CHAOS_TIERS[0])


func _update_tier_and_emit(force_emit: bool) -> void:
	var new_tier = get_tier()
	if force_emit or new_tier != current_tier:
		current_tier = new_tier
		tier_changed.emit(current_tier, get_fx_config())
	chaos_changed.emit(chaos_level)
