extends Node
## Preview scene for Ignore The Expert microgame
## Run this scene to see the microgame in action with presentation enabled

@onready var microgame = $MicrogameIgnoreTheExpert

func _ready():
	print("\n=== IGNORE THE EXPERT - VISUAL PREVIEW ===")
	print("Press any key/button to interrupt the expert")
	print("Do nothing and wait to see failure\n")
	
	# Connect signal
	microgame.resolved.connect(_on_resolved)
	
	# Start with presentation enabled
	microgame.start_microgame({
		"rng_seed": randi(),
		"presentation_enabled": true
	})


func _on_resolved(outcome: int):
	var outcome_str = "SUCCESS" if outcome == 0 else "FAILURE"
	print("✓ Microgame resolved: " + outcome_str)
	
	# Wait a bit then restart
	await get_tree().create_timer(2.0).timeout
	print("\n--- Restarting preview ---\n")
	
	microgame.start_microgame({
		"rng_seed": randi(),
		"presentation_enabled": true
	})
