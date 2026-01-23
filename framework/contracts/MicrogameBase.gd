extends Node
## Base contract for all microgames

signal resolved(success: bool)

enum Result {
	NONE,
	SUCCESS,
	FAILURE
}

var microgame_result: Result = Result.NONE
var is_active: bool = false
var input_policy: InputRouter.InputPolicy = null


## Contract: activate(context)
func activate(_context := {}) -> void:
	is_active = true
	microgame_result = Result.NONE
	on_activate()


## Contract: on_actions(action_batch)
func on_actions(actions: Array) -> void:
	on_input(actions)


## Contract: deactivate()
func deactivate() -> void:
	on_deactivate()
	is_active = false


## Back-compat hooks for legacy microgames
func on_activate() -> void:
	pass

func on_active_start() -> void:
	pass

func on_input(_actions: Array) -> void:
	pass

func on_active_end() -> void:
	pass

func on_deactivate() -> void:
	pass


## Input policy (used by InputRouter)
func get_input_policy() -> InputRouter.InputPolicy:
	return input_policy


## Instruction text
func get_instruction_text() -> String:
	return "DO SOMETHING"


## Resolve the microgame with success
func resolve_success() -> void:
	if microgame_result != Result.NONE:
		return
	microgame_result = Result.SUCCESS
	InputRouter.consume_first_input()
	resolved.emit(true)


## Resolve the microgame with failure
func resolve_failure() -> void:
	if microgame_result != Result.NONE:
		return
	microgame_result = Result.FAILURE
	InputRouter.consume_first_input()
	resolved.emit(false)


## Check if resolved
func is_resolved() -> bool:
	return microgame_result != Result.NONE


## Get the result
func get_result() -> Result:
	return microgame_result
