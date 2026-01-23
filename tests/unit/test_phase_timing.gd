extends Node

func _ready():
	print("\n=== PHASE TIMING TEST ===")
	print("INSTRUCTION_DURATION: ", GlobalTimingController.INSTRUCTION_DURATION)
	print("ACTIVE_DURATION: ", GlobalTimingController.ACTIVE_DURATION)
	print("RESOLVE_DURATION: ", GlobalTimingController.RESOLVE_DURATION)
	
	# Test phase progression
	GlobalTimingController.phase_complete.connect(_on_phase_complete)
	
	print("\nStarting INSTRUCTION phase...")
	GlobalTimingController.start_instruction()
	
	await get_tree().create_timer(1.0).timeout
	print("After 1 second - phase should have completed")
	
	await get_tree().create_timer(1.0).timeout
	print("Test complete")
	get_tree().quit()


func _on_phase_complete(phase):
	print("Phase completed: ", GlobalTimingController.Phase.keys()[phase])
