extends Node
## Manual test script for Ignore The Expert microgame
## Run this scene to visually test the microgame

@onready var microgame = $MicrogameIgnoreTheExpert

func _ready():
	print("=== Starting Ignore The Expert Manual Test ===")
	
	# Test 1: Basic instantiation
	print("✓ Microgame instantiated")
	
	# Test 2: Start with presentation disabled
	microgame.start_microgame({
		"rng_seed": 12345,
		"presentation_enabled": false,
		"total_duration_sec": 5.0
	})
	print("✓ Microgame started (presentation off)")
	
	# Connect resolved signal
	microgame.resolved.connect(_on_resolved)
	
	print("Waiting for resolution or 6 seconds...")
	await get_tree().create_timer(6.0).timeout
	
	print("=== Test Complete ===")
	get_tree().quit()


func _on_resolved(outcome: int):
	if outcome == microgame.Outcome.SUCCESS:
		print("✓ Microgame resolved: SUCCESS")
	else:
		print("✓ Microgame resolved: FAIL")
