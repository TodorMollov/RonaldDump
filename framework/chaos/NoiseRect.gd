extends ColorRect
## Noise overlay driven by chaos tier

var noise_opacity: float = 0.0
var animate_noise: bool = true
var _time_accum: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not ChaosManager.tier_changed.is_connected(_on_tier_changed):
		ChaosManager.tier_changed.connect(_on_tier_changed)
	set_process(true)


func _process(delta: float) -> void:
	_time_accum += delta
	var alpha = noise_opacity
	if animate_noise and noise_opacity > 0.0:
		alpha = clampf(noise_opacity + sin(_time_accum * 17.0) * 0.05, 0.0, 1.0)
	modulate.a = alpha


func _on_tier_changed(_tier: int, fx_config: Dictionary) -> void:
	noise_opacity = float(fx_config.get("noise_opacity", 0.0))
