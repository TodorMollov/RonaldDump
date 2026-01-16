extends Node
## ChaosManager - Deterministic chaos growth with mode multipliers
## Chaos affects presentation only, never gameplay logic

signal chaos_changed(new_value: float)

enum RunMode {
	NORMAL,
	UNHINGED,
	ENDLESS
}

const BASE_CHAOS_INCREMENT: float = 0.05
const MODE_MULTIPLIERS = {
	RunMode.NORMAL: 1.0,
	RunMode.UNHINGED: 1.5,
	RunMode.ENDLESS: 0.8
}

var current_chaos: float = 0.0
var current_mode: RunMode = RunMode.NORMAL
var microgames_completed: int = 0


func _ready() -> void:
	pass


func reset(mode: RunMode = RunMode.NORMAL) -> void:
	current_chaos = 0.0
	current_mode = mode
	microgames_completed = 0
	chaos_changed.emit(current_chaos)


func increment_chaos() -> void:
	"""Called after each microgame completes (success or failure)"""
	var multiplier = MODE_MULTIPLIERS.get(current_mode, 1.0)
	var increment = BASE_CHAOS_INCREMENT * multiplier
	
	current_chaos = clampf(current_chaos + increment, 0.0, 1.0)
	microgames_completed += 1
	
	chaos_changed.emit(current_chaos)


func get_chaos_level() -> float:
	return current_chaos


func get_chaos_category() -> String:
	if current_chaos < 0.25:
		return "LOW"
	elif current_chaos < 0.5:
		return "MEDIUM"
	elif current_chaos < 0.75:
		return "HIGH"
	else:
		return "EXTREME"


func get_visual_intensity() -> float:
	"""Returns 0.0 to 1.0 for visual effect intensity"""
	return current_chaos


func should_apply_screen_shake() -> bool:
	return current_chaos > 0.4


func get_screen_shake_intensity() -> float:
	return clampf((current_chaos - 0.4) / 0.6, 0.0, 1.0)


func get_color_distortion() -> float:
	return clampf(current_chaos * 0.5, 0.0, 0.5)
