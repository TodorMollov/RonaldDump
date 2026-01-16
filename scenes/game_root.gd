extends Node
## GameRoot - Main gameplay container

@onready var microgame_layer = $MicrogameLayer
@onready var ui_layer = $UILayer
@onready var hud = $UILayer/HUD


func _ready() -> void:
	_setup_connections()
	# Auto-start with the pending mode from RunManager
	call_deferred("start_run", RunManager.pending_mode)


func _setup_connections() -> void:
	# Connect run manager signals
	if not RunManager.microgame_instruction_shown.is_connected(_on_instruction_shown):
		RunManager.microgame_instruction_shown.connect(_on_instruction_shown)
	if not RunManager.microgame_active.is_connected(_on_microgame_active):
		RunManager.microgame_active.connect(_on_microgame_active)
	if not RunManager.microgame_resolved.is_connected(_on_microgame_resolved):
		RunManager.microgame_resolved.connect(_on_microgame_resolved)
	if not RunManager.run_completed.is_connected(_on_run_completed):
		RunManager.run_completed.connect(_on_run_completed)
	
	# Connect chaos manager
	if not ChaosManager.chaos_changed.is_connected(_on_chaos_changed):
		ChaosManager.chaos_changed.connect(_on_chaos_changed)


func start_run(mode: ChaosManager.RunMode) -> void:
	# Start the run
	RunManager.start_run(mode, microgame_layer)
	hud.show_run_start(mode)


func _on_instruction_shown(text: String) -> void:
	hud.show_instruction(text)


func _on_microgame_active() -> void:
	hud.show_active()


func _on_microgame_resolved(_success: bool) -> void:
	hud.show_resolve(_success)


func _on_run_completed() -> void:
	hud.show_you_won()


func _on_chaos_changed(value: float) -> void:
	hud.update_chaos(value)
