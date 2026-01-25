extends Node
## GameRoot - Main gameplay container

@onready var presentation_root: Node2D = $PresentationRoot
@onready var microgame_layer: Node = $PresentationRoot/MicrogameLayer
@onready var instruction_overlay: CanvasLayer = $InstructionOverlay
@onready var instruction_label: Label = $InstructionOverlay/InstructionLabel
@onready var shake_driver: Node = $ChaosFX/ShakeDriver
@onready var main_menu: Control = $UILayer/MainMenu
@onready var you_won: Control = $UILayer/YouWon

var _instruction_base_pos: Vector2 = Vector2.ZERO
var _ui_jitter_enabled: bool = false
var _jitter_time: float = 0.0


func _ready() -> void:
	_ensure_registry_populated()
	_instruction_base_pos = instruction_label.position
	_setup_connections()
	main_menu.visible = false
	you_won.visible = false
	instruction_overlay.visible = false
	# Reset RunManager state before starting new run (in case previous run didn't clean up fully)
	RunManager.reset()
	# Auto-start with the pending mode from RunManager
	call_deferred("start_run", RunManager.pending_mode)


func _ensure_registry_populated() -> void:
	# When launching GameRoot directly (bypassing boot), populate the registry so runs don't end immediately.
	if MicrogameRegistry.get_entries().size() > 0:
		if SequenceManager.registry == null:
			SequenceManager.initialize(MicrogameRegistry)
		return

	MicrogameRegistry.clear()
	MicrogameRegistry.register_microgame("ignore_the_expert", "res://microgames/mg01_ignore_the_expert/MicrogameIgnoreTheExpert.tscn", 1.0, true)
	MicrogameRegistry.register_microgame("end_the_pandemic", "res://microgames/mg02_end_the_pandemic/MicrogameEndThePandemic.tscn", 1.0, false)
	MicrogameRegistry.register_microgame("wall_builder", "res://microgames/mg03_wall_builder/WallBuilder.tscn", 1.0, false)
	MicrogameRegistry.register_microgame("disinfectant_brainstorm", "res://microgames/mg04_disinfectant_brainstorm/Microgame04_DisinfBrainstorm.tscn", 1.0, false)
	MicrogameRegistry.register_microgame("peace_deal_speedrun", "res://microgames/mg05_peace_deal_speedrun/Microgame05_PeaceDealSpeedrun.tscn", 1.0, false)
	SequenceManager.initialize(MicrogameRegistry)


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
	if not ChaosManager.tier_changed.is_connected(_on_tier_changed):
		ChaosManager.tier_changed.connect(_on_tier_changed)


func _process(delta: float) -> void:
	if shake_driver and shake_driver.has_method("get_current_offset"):
		var offset = shake_driver.get_current_offset()
		presentation_root.position = offset
	
	# Instruction jitter (presentation only)
	if _ui_jitter_enabled:
		_jitter_time += delta
		var jitter = Vector2(
			sin(_jitter_time * 22.0),
			cos(_jitter_time * 19.0)
		) * 2.0
		instruction_label.position = _instruction_base_pos + jitter
	else:
		instruction_label.position = _instruction_base_pos


func start_run(mode: ChaosManager.RunMode) -> void:
	# Start the run
	RunManager.start_run(mode, microgame_layer)


func _on_instruction_shown(text: String) -> void:
	instruction_label.text = text
	instruction_overlay.visible = true


func _on_microgame_active() -> void:
	instruction_overlay.visible = false


func _on_microgame_resolved(_success: bool) -> void:
	pass


func _on_run_completed() -> void:
	instruction_overlay.visible = false
	you_won.visible = true


func _on_tier_changed(_tier: int, fx_config: Dictionary) -> void:
	_ui_jitter_enabled = bool(fx_config.get("ui_jitter", false))
