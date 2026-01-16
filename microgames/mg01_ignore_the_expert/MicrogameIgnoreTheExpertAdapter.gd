extends MicrogameBase
## Adapter to make Ignore The Expert compatible with MicrogameBase framework
## Wraps the Control-based implementation in a Node2D-based MicrogameBase

# Preload the actual microgame implementation
const MicrogameIgnoreTheExpert = preload("res://microgames/mg01_ignore_the_expert/MicrogameIgnoreTheExpert.tscn")

# Reference to the wrapped microgame instance
var microgame_instance = null

# Track if we've started
var has_started: bool = false


func _ready() -> void:
	super._ready()
	
	# Set up input policy
	input_policy = InputRouter.InputPolicy.new(true, false, false, [], [])


func get_instruction_text() -> String:
	return "IGNORE THE EXPERT"


func on_activate() -> void:
	super.on_activate()
	
	# Instantiate the actual microgame
	microgame_instance = MicrogameIgnoreTheExpert.instantiate()
	
	# Add to CanvasLayer so Control nodes render properly
	var canvas_layer = get_node("CanvasLayer")
	canvas_layer.add_child(microgame_instance)
	
	# Connect the resolved signal
	microgame_instance.resolved.connect(_on_microgame_resolved)
	
	# Don't start yet - wait for on_active_start()
	has_started = false


func on_active_start() -> void:
	super.on_active_start()
	
	if not has_started and microgame_instance:
		# Start the microgame with framework-specified duration
		# Duration is automatically randomized per framework spec (3.5-4.5s, hard cap 5.0s)
		var duration = get_framework_duration()
		
		# Detect if we're in headless mode (for testing)
		var is_headless = DisplayServer.get_name() == "headless"
		
		microgame_instance.start_microgame({
			"rng_seed": randi(),
			"presentation_enabled": not is_headless,  # Disable in headless mode
			"total_duration_sec": duration
		})
		has_started = true


func on_input(_actions: Array) -> void:
	# Input is handled internally by the microgame
	# It will resolve itself and emit the signal
	pass


func on_active_end() -> void:
	super.on_active_end()
	
	# Force resolve if not already resolved
	if microgame_instance and not is_resolved():
		microgame_instance.force_resolve(microgame_instance.Outcome.FAIL)


func on_deactivate() -> void:
	super.on_deactivate()
	
	# Clean up the microgame instance
	if microgame_instance:
		microgame_instance.queue_free()
		microgame_instance = null
	
	has_started = false


func _on_microgame_resolved(outcome: int) -> void:
	# Translate the microgame's outcome to framework success/failure
	# Outcome: 0 = SUCCESS, 1 = FAIL
	var is_success = (outcome == 0)
	if is_success:
		resolve_success()
	else:
		resolve_failure()
