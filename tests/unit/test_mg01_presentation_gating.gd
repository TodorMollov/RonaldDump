extends GutTest
## Test MG01 Ignore The Expert presentation gating
## Ensures visuals/audio/tweens are bypassed when presentation_enabled=false
## This is critical for headless test runs

var microgame: Node = null
const MG_PATH = "res://microgames/mg01_ignore_the_expert/MicrogameIgnoreTheExpert.tscn"
const MicrogameBase = preload("res://framework/microgame_base.gd")
const Result = MicrogameBase.Result


func after_each():
	if microgame:
		if microgame.is_inside_tree():
			microgame.get_parent().remove_child(microgame)
		microgame.queue_free()
		await wait_frames(1)


## Test that presentation_enabled=false prevents idle animations
func test_mg01_presentation_disabled_no_idle_tweens():
	microgame = load(MG_PATH).instantiate()
	add_child(microgame)
	
	# Initialize with presentation_enabled=false
	microgame._init_microgame({"presentation_enabled": false})
	
	# Check that idle_tweens array is empty (no animations created)
	assert_eq(microgame.idle_tweens.size(), 0, "presentation_enabled=false should not create idle tweens")


## Test that presentation_enabled=true creates idle tweens
func test_mg01_presentation_enabled_creates_idle_tweens():
	microgame = load(MG_PATH).instantiate()
	add_child(microgame)
	
	# Initialize with presentation_enabled=true
	microgame._init_microgame({"presentation_enabled": true})
	
	# Check that idle_tweens array has animations (3 tweens: ronald bob, ronald rot, expert wobble)
	assert_gt(microgame.idle_tweens.size(), 0, "presentation_enabled=true should create idle tweens")


## Test that presentation_enabled=false prevents expert jitter
func test_mg01_presentation_disabled_no_expert_jitter():
	microgame = load(MG_PATH).instantiate()
	add_child(microgame)
	
	# Initialize with presentation_enabled=false
	microgame._init_microgame({"presentation_enabled": false})
	
	# Simulate entering ADVICE_ACTIVE state
	microgame._enter_advice_active()
	
	# Check that expert_jitter_tween was not created
	assert_null(microgame.expert_jitter_tween, "presentation_enabled=false should not create expert jitter tween")


## Test that UI text is not updated when presentation_enabled=false
func test_mg01_presentation_disabled_no_expert_text_update():
	microgame = load(MG_PATH).instantiate()
	add_child(microgame)
	
	# Initialize with presentation_enabled=false
	microgame._init_microgame({"presentation_enabled": false})
	
	# Simulate time passing in ADVICE_ACTIVE (this would normally update text)
	microgame.current_state = microgame.State.ADVICE_ACTIVE
	microgame._update_expert_text(0.1)
	
	# Expert buffer should remain empty (no text was generated)
	assert_eq(microgame.expert_buffer, "", "presentation_enabled=false should not generate expert text")


## Test that tweens are cleaned up on resolve
func test_mg01_tweens_cleanup_on_resolve():
	microgame = load(MG_PATH).instantiate()
	add_child(microgame)
	
	# Initialize with presentation_enabled=true to create tweens
	microgame._init_microgame({"presentation_enabled": true})
	var initial_tween_count = microgame.idle_tweens.size()
	assert_gt(initial_tween_count, 0, "Setup should have created tweens")
	
	# Trigger resolution
	microgame._resolve_framework(Result.SUCCESS)
	
	# Verify tweens are cleaned up
	assert_eq(microgame.idle_tweens.size(), 0, "Tweens should be cleared on resolve")
	assert_null(microgame.expert_jitter_tween, "Expert jitter should be null on resolve")
