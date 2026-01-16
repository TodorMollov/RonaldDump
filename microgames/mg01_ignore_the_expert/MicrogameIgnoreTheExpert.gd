extends Control
## Microgame: Ignore The Expert
## Success = first actionable input during ADVICE_ACTIVE before advice deadline
## Failure = wait past advice deadline OR overall timeout without input

# Preload utility classes (use different names to avoid class_name conflicts)
const RngUtils = preload("res://microgames/mg01_ignore_the_expert/ignore_rng_utils.gd")
const AssetBootstrap = preload("res://microgames/mg01_ignore_the_expert/assets/AssetBootstrap.gd")

signal resolved(outcome: int)

enum State { INTRO, ADVICE_ACTIVE, SUCCESS_RESOLVE, FAIL_RESOLVE }
enum Outcome { SUCCESS, FAIL }

# Node references
@onready var background = $Background
@onready var ronald_sprite = $Characters/Ronald
@onready var expert_sprite = $Characters/Expert
@onready var advice_progress = $UI/AdviceProgress
@onready var expert_bubble = $UI/ExpertBubble
@onready var expert_text = $UI/ExpertBubble/ExpertText
@onready var debug_state = $UI/DebugState
@onready var sfx_talk = $Audio/SFX_Talk
@onready var sfx_cutoff = $Audio/SFX_Cutoff
@onready var sfx_success = $Audio/SFX_Success
@onready var sfx_fail = $Audio/SFX_Fail

# State
var current_state: State = State.INTRO
var is_resolved: bool = false
var final_outcome: int = Outcome.FAIL

# Timing
# Duration spec: 3.5-4.5s randomized (avg ~4.0s), hard cap 5.0s
var elapsed: float = 0.0
var total_duration_sec: float = 4.0
var intro_end_sec: float = 0.3
var advice_deadline_sec: float = 2.0

# RNG
var rng: RandomNumberGenerator = null

# Expert text generation
var expert_buffer: String = ""
var last_char_time: float = 0.0
var chars_per_sec: float = 100.0
var syllables = ["ba", "bla", "glo", "qu", "xz", "thk", "mph", "vrg", "sch", "krt"]

# Presentation
var presentation_enabled: bool = true

# Animation state
var ronald_bob_time: float = 0.0
var expert_wobble_time: float = 0.0
var idle_tweens: Array[Tween] = []


func _ready():
	# Assert critical nodes exist
	assert(background != null, "Background node missing")
	assert(ronald_sprite != null, "Ronald sprite missing")
	assert(expert_sprite != null, "Expert sprite missing")
	assert(advice_progress != null, "AdviceProgress node missing")
	assert(expert_bubble != null, "ExpertBubble node missing")
	assert(expert_text != null, "ExpertText node missing")
	
	# Set initial visibility
	advice_progress.visible = true
	expert_bubble.visible = true
	expert_text.visible = true
	advice_progress.value = 0.0
	expert_text.text = ""
	
	if debug_state:
		debug_state.visible = false
	
	# DO NOT load assets here - they will be loaded in start_microgame() when needed


func start_microgame(params := {}) -> void:
	"""Start/restart the microgame with optional parameters"""
	# Reset state
	current_state = State.INTRO
	is_resolved = false
	final_outcome = Outcome.FAIL
	elapsed = 0.0
	expert_buffer = ""
	last_char_time = 0.0
	ronald_bob_time = 0.0
	expert_wobble_time = 0.0
	
	# Stop any existing animations
	_stop_idle_animations()
	
	# Parse parameters
	presentation_enabled = params.get("presentation_enabled", true)
	
	# Ensure assets exist (only when presentation enabled)
	if presentation_enabled:
		AssetBootstrap.ensure_assets()
	
	# Setup RNG
	var seed_value = params.get("rng_seed", randi())
	rng = RngUtils.seeded_rng(seed_value)
	
	# Determine timing (deterministic if seeded)
	total_duration_sec = params.get("total_duration_sec", RngUtils.randf_range(rng, 3.5, 4.5))
	advice_deadline_sec = RngUtils.randf_range(rng, 1.8, 2.2)
	chars_per_sec = RngUtils.randf_range(rng, 80.0, 140.0)
	
	# Setup UI and presentation
	advice_progress.value = 0.0
	expert_text.text = ""
	
	if presentation_enabled:
		_setup_visuals()
		_load_assets()  # Load assets after ensuring they exist
		_start_idle_animations()
	
	# Start processing
	set_process(true)
	set_process_unhandled_input(true)


func force_resolve(outcome: int = Outcome.FAIL) -> void:
	"""Force resolution (called by framework on timeout)"""
	if not is_resolved:
		_resolve(outcome)


func get_input_policy() -> Dictionary:
	"""Return input policy for framework integration"""
	return {
		"success_on_any_input": true,
		"pointer_move_counts_as_input": false
	}


func _process(delta: float) -> void:
	elapsed += delta
	
	# Update state machine
	match current_state:
		State.INTRO:
			_process_intro()
		
		State.ADVICE_ACTIVE:
			_process_advice_active(delta)
		
		State.SUCCESS_RESOLVE:
			_process_success_resolve(delta)
		
		State.FAIL_RESOLVE:
			_process_fail_resolve(delta)
	
	# Check overall timeout
	if elapsed >= total_duration_sec and not is_resolved:
		_resolve(Outcome.FAIL)
	
	# Update debug display
	if debug_state and debug_state.visible:
		debug_state.text = "State: %s\nElapsed: %.2f\nResolved: %s" % [
			State.keys()[current_state],
			elapsed,
			is_resolved
		]


func _process_intro() -> void:
	if elapsed >= intro_end_sec:
		_enter_advice_active()


func _process_advice_active(delta: float) -> void:
	# Update progress bar
	var progress_start = intro_end_sec
	var progress_duration = advice_deadline_sec - intro_end_sec
	var progress = clampf((elapsed - progress_start) / progress_duration, 0.0, 1.0)
	
	if presentation_enabled and advice_progress:
		advice_progress.value = progress * 100.0
	
	# Generate expert text fragments
	_update_expert_text(delta)
	
	# Check deadline
	if elapsed >= advice_deadline_sec:
		_resolve(Outcome.FAIL)


func _process_success_resolve(_delta: float) -> void:
	# Success animation is handled by tweens
	pass


func _process_fail_resolve(_delta: float) -> void:
	# Failure animation is handled by tweens
	pass


func _enter_advice_active() -> void:
	current_state = State.ADVICE_ACTIVE
	
	# Start talk SFX (loop)
	if presentation_enabled and sfx_talk and sfx_talk.stream:
		sfx_talk.play()


func _update_expert_text(delta: float) -> void:
	if not presentation_enabled or not rng:
		return
	
	last_char_time += delta
	var chars_to_add = int(last_char_time * chars_per_sec)
	
	if chars_to_add > 0:
		last_char_time = 0.0
		
		# Generate random syllable fragments
		for i in range(chars_to_add):
			if expert_buffer.length() >= 60:
				# Cap length, remove from start
				expert_buffer = expert_buffer.substr(chars_to_add)
			
			# Add random syllable or punctuation
			if rng.randf() < 0.1:
				expert_buffer += ", "
			else:
				expert_buffer += syllables[rng.randi() % syllables.size()]
		
		if expert_text:
			expert_text.text = expert_buffer


func _input(event: InputEvent) -> void:
	# Only handle input during ADVICE_ACTIVE and not yet resolved
	if current_state != State.ADVICE_ACTIVE or is_resolved:
		return
	
	var is_actionable = false
	
	# Check for actionable input
	if event is InputEventKey:
		if event.pressed and not event.echo:
			is_actionable = true
	
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			is_actionable = true
	
	elif event is InputEventJoypadButton:
		if event.pressed:
			is_actionable = true
	
	elif event is InputEventMouseMotion:
		# Mouse motion is NEVER actionable
		is_actionable = false
	
	if is_actionable:
		_resolve(Outcome.SUCCESS)
		get_viewport().set_input_as_handled()


func _resolve(outcome: int) -> void:
	if is_resolved:
		return
	
	is_resolved = true
	final_outcome = outcome
	
	# Stop idle animations
	_stop_idle_animations()
	
	# Stop talk SFX
	if presentation_enabled and sfx_talk and sfx_talk.playing:
		sfx_talk.stop()
	
	# Transition to resolve state
	if outcome == Outcome.SUCCESS:
		current_state = State.SUCCESS_RESOLVE
		_on_success()
	else:
		current_state = State.FAIL_RESOLVE
		_on_failure()
	
	# Emit signal ONCE
	resolved.emit(outcome)


func _on_success() -> void:
	# Cut text mid-word (do not clean up)
	# Text stays as-is
	
	# Play cutoff + success SFX
	if presentation_enabled:
		if sfx_cutoff and sfx_cutoff.stream:
			sfx_cutoff.play()
		if sfx_success and sfx_success.stream:
			sfx_success.play()
		
		# Ronald dismissive animation
		if ronald_sprite:
			var tween = create_tween()
			tween.tween_property(ronald_sprite, "rotation", 0.3, 0.2)
			tween.tween_property(ronald_sprite, "rotation", 0.0, 0.3)
		
		# Expert recoil
		if expert_sprite:
			var tween = create_tween()
			tween.tween_property(expert_sprite, "position:x", expert_sprite.position.x + 20, 0.1)
			tween.tween_property(expert_sprite, "position:x", expert_sprite.position.x, 0.3)


func _on_failure() -> void:
	# Stop text generation
	
	# Play fail SFX
	if presentation_enabled and sfx_fail and sfx_fail.stream:
		sfx_fail.play()
	
	# Ronald "yawn" animation
	if presentation_enabled and ronald_sprite:
		var tween = create_tween()
		tween.tween_property(ronald_sprite, "scale", Vector2(1.05, 0.95), 0.3)
		tween.tween_property(ronald_sprite, "scale", Vector2.ONE, 0.2)


func _load_assets() -> void:
	"""Load assets with fallbacks to procedural"""
	var base_path = "res://microgames/mg01_ignore_the_expert/assets/"
	
	# Load textures
	if ronald_sprite:
		var ronald_tex = _load_texture(base_path + "ronald.png")
		if ronald_tex:
			ronald_sprite.texture = ronald_tex
		else:
			ronald_sprite.texture = _create_fallback_texture(Color(0.9, 0.7, 0.4))  # Orange-ish
	
	if expert_sprite:
		var expert_tex = _load_texture(base_path + "expert.png")
		if expert_tex:
			expert_sprite.texture = expert_tex
		else:
			expert_sprite.texture = _create_fallback_texture(Color(0.6, 0.6, 0.8))  # Blue-gray
	
	if expert_bubble:
		var bubble_tex = _load_texture(base_path + "speech.png")
		if bubble_tex:
			expert_bubble.texture = bubble_tex
		else:
			# Fallback: use modulate to tint background
			expert_bubble.modulate = Color(0.9, 0.9, 0.9, 0.8)
	
	# Load audio
	_load_audio(sfx_talk, base_path + "sfx_talk.wav")
	_load_audio(sfx_cutoff, base_path + "sfx_cutoff.wav")
	_load_audio(sfx_success, base_path + "sfx_success.wav")
	_load_audio(sfx_fail, base_path + "sfx_fail.wav")


func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _load_audio(player: AudioStreamPlayer, path: String) -> void:
	if player and ResourceLoader.exists(path):
		player.stream = load(path) as AudioStream


func _create_fallback_texture(color: Color) -> ImageTexture:
	"""Create a simple colored square texture as fallback"""
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)


func _setup_visuals() -> void:
	"""Setup initial visual state"""
	if background:
		background.color = Color(0.15, 0.15, 0.2)
	
	# Position characters
	if ronald_sprite:
		ronald_sprite.position = Vector2(200, 400)
		ronald_sprite.scale = Vector2(1.5, 1.5)
	
	if expert_sprite:
		expert_sprite.position = Vector2(800, 400)
		expert_sprite.scale = Vector2(1.2, 1.2)
	
	# Setup progress bar
	if advice_progress:
		advice_progress.value = 0.0
		advice_progress.max_value = 100.0


## Animation Helpers

func _start_idle_animations() -> void:
	"""Start idle animations for characters"""
	if not presentation_enabled or not ronald_sprite or not expert_sprite:
		return
	
	# Ronald idle bob
	var ronald_tween = create_tween()
	ronald_tween.set_loops()
	ronald_tween.tween_property(ronald_sprite, "position:y", ronald_sprite.position.y - 8, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	ronald_tween.tween_property(ronald_sprite, "position:y", ronald_sprite.position.y, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_tweens.append(ronald_tween)
	
	# Ronald gentle rotation
	var ronald_rot_tween = create_tween()
	ronald_rot_tween.set_loops()
	ronald_rot_tween.tween_property(ronald_sprite, "rotation", 0.05, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	ronald_rot_tween.tween_property(ronald_sprite, "rotation", -0.05, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_tweens.append(ronald_rot_tween)
	
	# Expert subtle wobble (only during ADVICE_ACTIVE, controlled manually)
	# We'll add scale pulse instead
	var expert_tween = create_tween()
	expert_tween.set_loops()
	expert_tween.tween_property(expert_sprite, "scale", expert_sprite.scale * 1.03, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	expert_tween.tween_property(expert_sprite, "scale", expert_sprite.scale, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_tweens.append(expert_tween)


func _stop_idle_animations() -> void:
	"""Stop all idle animations"""
	for tween in idle_tweens:
		if tween and tween.is_valid():
			tween.kill()
	idle_tweens.clear()


# Test helpers
func _get_state_for_tests() -> int:
	return current_state


func _get_advice_deadline_for_tests() -> float:
	return advice_deadline_sec


func _get_total_duration_for_tests() -> float:
	return total_duration_sec


func _get_elapsed_for_tests() -> float:
	return elapsed
