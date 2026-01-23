extends Control
## Non-interactive fake UI clutter driven by chaos tier

var fake_ui_density: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not ChaosManager.tier_changed.is_connected(_on_tier_changed):
		ChaosManager.tier_changed.connect(_on_tier_changed)


func _on_tier_changed(_tier: int, fx_config: Dictionary) -> void:
	fake_ui_density = float(fx_config.get("fake_ui_density", 0.0))
	_spawn_fake_ui()


func _spawn_fake_ui() -> void:
	for child in get_children():
		child.queue_free()
	if fake_ui_density <= 0.0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	var count = int(round(fake_ui_density * 10.0))
	for i in range(count):
		var label := Label.new()
		label.text = "SYS"
		label.modulate = Color(1, 1, 1, 0.5)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.position = Vector2(rng.randi_range(0, 900), rng.randi_range(0, 500))
		add_child(label)
