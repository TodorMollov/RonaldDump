extends Node2D
class_name MicrogameBase
## Base class for all microgames
## Microgames must extend this and implement the required methods

signal resolved(success: bool)

enum Result {
	NONE,
	SUCCESS,
	FAILURE
}

var microgame_result: Result = Result.NONE
var is_active: bool = false
var input_policy: InputRouter.InputPolicy = null


func _ready() -> void:
	pass


## Called when microgame is activated (start of INSTRUCTION phase)
func on_activate() -> void:
	is_active = true
	microgame_result = Result.NONE


## Called when ACTIVE phase begins (input enabled)
func on_active_start() -> void:
	pass


## Called when input is received during ACTIVE phase
func on_input(_actions: Array) -> void:
	pass


## Called when ACTIVE phase ends (forced by timer)
func on_active_end() -> void:
	pass


## Called when microgame is deactivated (after RESOLVE)
func on_deactivate() -> void:
	is_active = false


## Get the input policy for this microgame
func get_input_policy() -> InputRouter.InputPolicy:
	return input_policy


## Get instruction text to display
func get_instruction_text() -> String:
	return "DO SOMETHING"


## Resolve the microgame with success
func resolve_success() -> void:
	if microgame_result != Result.NONE:
		return  # Already resolved
	
	microgame_result = Result.SUCCESS
	InputRouter.consume_first_input()
	resolved.emit(true)


## Resolve the microgame with failure
func resolve_failure() -> void:
	if microgame_result != Result.NONE:
		return  # Already resolved
	
	microgame_result = Result.FAILURE
	InputRouter.consume_first_input()
	resolved.emit(false)


## Check if resolved
func is_resolved() -> bool:
	return microgame_result != Result.NONE


## Get the result
func get_result() -> Result:
	return microgame_result


## Get a randomized duration that meets framework specification
## All microgames should use this to ensure consistent timing
func get_framework_duration() -> float:
	return GlobalTimingController.get_random_microgame_duration()


## Get the target average duration (for testing/deterministic scenarios)
func get_target_duration() -> float:
	return GlobalTimingController.get_target_microgame_duration()