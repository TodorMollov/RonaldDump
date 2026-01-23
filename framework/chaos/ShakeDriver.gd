extends Node
## Applies screen shake based on chaos tier

var screen_shake_strength: float = 0.0
var _time_accum: float = 0.0
var _current_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	if not ChaosManager.tier_changed.is_connected(_on_tier_changed):
		ChaosManager.tier_changed.connect(_on_tier_changed)
	set_process(true)


func _process(delta: float) -> void:
	if screen_shake_strength <= 0.0:
		_current_offset = Vector2.ZERO
		return
	_time_accum += delta
	var shake = Vector2(
		sin(_time_accum * 23.0),
		cos(_time_accum * 17.0)
	) * (screen_shake_strength * 10.0)
	_current_offset = shake


func _on_tier_changed(_tier: int, fx_config: Dictionary) -> void:
	screen_shake_strength = float(fx_config.get("screen_shake_strength", 0.0))


func get_current_offset() -> Vector2:
	return _current_offset
