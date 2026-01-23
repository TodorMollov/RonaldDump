extends Node
## Flicker presentation overlays driven by chaos tier

@export var instruction_overlay_path: NodePath
@export var noise_rect_path: NodePath

var flicker_interval: float = 0.0
var _timer: float = 0.0
var _visible_state: bool = true


func _ready() -> void:
	if not ChaosManager.tier_changed.is_connected(_on_tier_changed):
		ChaosManager.tier_changed.connect(_on_tier_changed)
	set_process(true)


func _process(delta: float) -> void:
	if flicker_interval <= 0.0:
		_set_targets_visible(true)
		return
	_timer += delta
	if _timer >= flicker_interval:
		_timer = 0.0
		_visible_state = not _visible_state
		_set_targets_visible(_visible_state)


func _on_tier_changed(_tier: int, fx_config: Dictionary) -> void:
	flicker_interval = float(fx_config.get("flicker_interval", 0.0))
	_timer = 0.0
	_visible_state = true
	_set_targets_visible(true)


func _set_targets_visible(visible_state: bool) -> void:
	var instruction_overlay = get_node_or_null(instruction_overlay_path)
	if instruction_overlay:
		instruction_overlay.visible = visible_state
	var noise_rect = get_node_or_null(noise_rect_path)
	if noise_rect:
		noise_rect.visible = visible_state
