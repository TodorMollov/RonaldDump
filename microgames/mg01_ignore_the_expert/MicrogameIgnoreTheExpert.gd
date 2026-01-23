extends MicrogameBase
## Microgame: Ignore The Expert

const Style = preload("res://ui/placeholder_ui/PlaceholderUIStyle.gd")
const AssetBootstrap = preload("res://microgames/mg01_ignore_the_expert/assets/AssetBootstrap.gd")
const InputPolicyFactory = preload("res://autoload/input_router.gd")

enum Outcome { SUCCESS, FAIL }
enum State { INTRO, ADVICE_ACTIVE, SUCCESS_RESOLVE, FAIL_RESOLVE }

const INTRO_RANGE := Vector2(0.18, 0.32)
const ADVICE_RANGE := Vector2(1.8, 2.2)
const TOTAL_RANGE := Vector2(3.5, 4.5)
const HARD_CAP := 5.0
const RESOLVE_FREEZE := 0.65
const EXPERT_CHAR_INTERVAL := 0.085
const EXPERT_MAX_LENGTH := 180
const ADVICE_MIN_BUFFER := 0.3
const GIBBERISH_BANK := [
	"ER", "UM", "ACTUALLY", "LISTEN", "HENCE", "THUS",
	"FURTHERMORE", "PLEASE", "IMPORTANT", "STATISTICALLY"
]

@onready var background: ColorRect = $Background
@onready var ronald_sprite: Sprite2D = $Characters/Ronald
@onready var expert_sprite: Sprite2D = $Characters/Expert
@onready var advice_progress: ProgressBar = $UI/AdviceProgress
@onready var expert_bubble: PanelContainer = $UI/ExpertBubble
@onready var expert_text: Label = $UI/ExpertBubble/ExpertText
@onready var debug_state: Label = $UI/DebugState
@onready var sfx_talk: AudioStreamPlayer = $Audio/SFX_Talk
@onready var sfx_cutoff: AudioStreamPlayer = $Audio/SFX_Cutoff
@onready var sfx_success: AudioStreamPlayer = $Audio/SFX_Success
@onready var sfx_fail: AudioStreamPlayer = $Audio/SFX_Fail

var presentation_enabled := true
var current_state: State = State.INTRO
var idle_tweens: Array = []
var expert_jitter_tween: Tween = null
var expert_buffer := ""

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _intro_duration := INTRO_RANGE.x
var _advice_deadline := ADVICE_RANGE.x
var _total_duration := TOTAL_RANGE.x
var _intro_elapsed := 0.0
var _active_elapsed := 0.0
var _resolve_timer := 0.0
var _expert_char_timer := 0.0
var _running := false
var _resolved_flag := false


func _ready() -> void:
	AssetBootstrap.ensure_assets()
	_apply_assets()
	_apply_style()
	set_process(false)
	set_process_unhandled_input(true)
	update_debug_state()


func on_activate() -> void:
	input_policy = InputPolicyFactory.create_any_input_policy()
	start_microgame()


func on_active_start() -> void:
	_begin_runtime()


func on_active_end() -> void:
	if not is_resolved():
		force_resolve(Result.FAILURE)
	_running = false
	set_process(false)


func on_deactivate() -> void:
	_running = false
	set_process(false)
	_stop_all_audio()
	_clear_idle_tweens()
	_clear_expert_jitter()


func start_microgame(params := {}) -> void:
	_init_microgame(params)
	if not is_active:
		_begin_runtime()


func _init_microgame(params := {}) -> void:
	presentation_enabled = params.get("presentation_enabled", true)
	microgame_result = Result.NONE
	_resolved_flag = false
	_rng = RandomNumberGenerator.new()
	if params.has("rng_seed"):
		_rng.seed = params["rng_seed"]
	else:
		_rng.randomize()
	_intro_duration = params.get("intro_duration_sec", _rng.randf_range(INTRO_RANGE.x, INTRO_RANGE.y))
	_total_duration = clampf(params.get("total_duration_sec", _rng.randf_range(TOTAL_RANGE.x, TOTAL_RANGE.y)), TOTAL_RANGE.x, HARD_CAP)
	var deadline_candidate = params.get("advice_deadline_sec", _rng.randf_range(ADVICE_RANGE.x, ADVICE_RANGE.y))
	var max_deadline = maxf(0.6, _total_duration - ADVICE_MIN_BUFFER)
	_advice_deadline = clampf(deadline_candidate, 0.5, max_deadline)
	_intro_elapsed = 0.0
	_active_elapsed = 0.0
	_resolve_timer = 0.0
	_expert_char_timer = 0.0
	expert_buffer = ""
	if expert_text:
		expert_text.text = ""
	current_state = State.INTRO
	_running = false
	_stop_all_audio()
	_clear_idle_tweens()
	_create_idle_tweens()
	_clear_expert_jitter()
	if advice_progress:
		advice_progress.value = 0.0
	_update_progress_bar_color(0.0)
	update_debug_state()


func force_resolve(outcome: int = Outcome.FAIL) -> void:
	if outcome == Outcome.SUCCESS:
		_resolve_success()
	else:
		_resolve_fail()


func _resolve_framework(result: int) -> void:
	if result == Result.SUCCESS:
		_resolve_success()
	else:
		_resolve_fail()


func get_instruction_text() -> String:
	return "Ignore Advice"


func get_input_policy() -> InputRouter.InputPolicy:
	if input_policy == null:
		input_policy = InputPolicyFactory.create_any_input_policy()
	return input_policy


func _begin_runtime() -> void:
	_running = true
	set_process(true)


func _process(delta: float) -> void:
	if not _running:
		return
	match current_state:
		State.INTRO:
			_intro_elapsed += delta
			if _intro_elapsed >= _intro_duration:
				_enter_advice_active()
		State.ADVICE_ACTIVE:
			_active_elapsed += delta
			_update_expert_text(delta)
			_update_progress()
			if _active_elapsed >= _advice_deadline or _intro_elapsed + _active_elapsed >= _total_duration:
				_resolve_fail()
		State.SUCCESS_RESOLVE, State.FAIL_RESOLVE:
			_resolve_timer += delta
			if _resolve_timer >= RESOLVE_FREEZE:
				_running = false
				set_process(false)


func _unhandled_input(event: InputEvent) -> void:
	if not _running or _resolved_flag:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_handle_player_input()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_player_input()
	elif event is InputEventJoypadButton and event.pressed:
		_handle_player_input()


func handle_any_input() -> void:
	_handle_player_input()


func _handle_player_input() -> void:
	if not _running or _resolved_flag:
		return
	if current_state == State.ADVICE_ACTIVE:
		_resolve_success()


func _enter_advice_active() -> void:
	current_state = State.ADVICE_ACTIVE
	_active_elapsed = 0.0
	_expert_char_timer = 0.0
	if presentation_enabled:
		_start_expert_jitter()
		_play_safe(sfx_talk)
	update_debug_state()


func _update_progress() -> void:
	if not advice_progress:
		return
	var pct = clampf(_active_elapsed / _advice_deadline, 0.0, 1.0)
	advice_progress.value = pct * advice_progress.max_value
	_update_progress_bar_color(pct)


func _update_progress_bar_color(percent: float) -> void:
	if not advice_progress:
		return
	advice_progress.add_theme_color_override("fg_color", Style.advice_bar_color(percent))


func _update_expert_text(delta: float) -> void:
	if not presentation_enabled or current_state != State.ADVICE_ACTIVE:
		return
	_expert_char_timer += delta
	if _expert_char_timer < EXPERT_CHAR_INTERVAL:
		return
	_expert_char_timer = 0.0
	expert_buffer += _next_chunk() + " "
	if expert_buffer.length() > EXPERT_MAX_LENGTH:
		expert_buffer = expert_buffer.substr(expert_buffer.length() - EXPERT_MAX_LENGTH, EXPERT_MAX_LENGTH)
	if expert_text:
		expert_text.text = expert_buffer


func _next_chunk() -> String:
	var syllables = _rng.randi_range(1, 3)
	var chunk := ""
	for i in range(syllables):
		chunk += GIBBERISH_BANK[_rng.randi_range(0, GIBBERISH_BANK.size() - 1)]
		if i < syllables - 1:
			chunk += " "
	return chunk


func _resolve_success() -> void:
	if _resolved_flag:
		return
	current_state = State.SUCCESS_RESOLVE
	_resolved_flag = true
	_resolve_timer = 0.0
	_stop_all_audio()
	_play_safe(sfx_cutoff)
	_play_safe(sfx_success)
	_clear_expert_jitter()
	_clear_idle_tweens()
	if advice_progress:
		advice_progress.value = advice_progress.max_value
	microgame_result = Result.SUCCESS
	InputRouter.consume_first_input()
	resolved.emit(Outcome.SUCCESS)
	update_debug_state()


func _resolve_fail() -> void:
	if _resolved_flag:
		return
	current_state = State.FAIL_RESOLVE
	_resolved_flag = true
	_resolve_timer = 0.0
	_stop_all_audio()
	_play_safe(sfx_cutoff)
	_play_safe(sfx_fail)
	_clear_expert_jitter()
	_clear_idle_tweens()
	microgame_result = Result.FAILURE
	InputRouter.consume_first_input()
	resolved.emit(Outcome.FAIL)
	update_debug_state()


func _create_idle_tweens() -> void:
	idle_tweens.clear()
	if not presentation_enabled:
		return
	if ronald_sprite:
		var bob = create_tween().set_loops()
		bob.tween_property(ronald_sprite, "position:y", ronald_sprite.position.y - Style.IDLE_BOB_AMPLITUDE, 1.0 / Style.IDLE_BOB_SPEED).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		bob.tween_property(ronald_sprite, "position:y", ronald_sprite.position.y, 1.0 / Style.IDLE_BOB_SPEED)
		idle_tweens.append(bob)
	if expert_sprite:
		var wobble = create_tween().set_loops()
		wobble.tween_property(expert_sprite, "rotation_degrees", -2.0, 0.6)
		wobble.tween_property(expert_sprite, "rotation_degrees", 2.0, 0.6)
		idle_tweens.append(wobble)


func _clear_idle_tweens() -> void:
	for tween in idle_tweens:
		if tween:
			tween.kill()
	idle_tweens.clear()


func _start_expert_jitter() -> void:
	_clear_expert_jitter()
	if not presentation_enabled or not expert_sprite:
		return
	expert_jitter_tween = create_tween().set_loops()
	expert_jitter_tween.tween_property(expert_sprite, "position:x", expert_sprite.position.x + Style.EXPERT_TALK_JITTER_RANGE, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	expert_jitter_tween.tween_property(expert_sprite, "position:x", expert_sprite.position.x - Style.EXPERT_TALK_JITTER_RANGE, 0.08)


func _clear_expert_jitter() -> void:
	if expert_jitter_tween:
		expert_jitter_tween.kill()
		expert_jitter_tween = null


func _apply_style() -> void:
	if background:
		background.color = Style.BG_DARK
	if expert_text:
		expert_text.modulate = Style.TEXT_NOISE
	if expert_bubble:
		expert_bubble.self_modulate = Style.BUBBLE_BG


func _apply_assets() -> void:
	_assign_texture(ronald_sprite, "res://microgames/mg01_ignore_the_expert/assets/ronald.png")
	_assign_texture(expert_sprite, "res://microgames/mg01_ignore_the_expert/assets/expert.png")


func _assign_texture(sprite: Sprite2D, path: String) -> void:
	if not sprite:
		return
	var loaded := ResourceLoader.load(path)
	if loaded:
		sprite.texture = loaded
		return
	if FileAccess.file_exists(path):
		var image := Image.new()
		if image.load(path) == OK:
			var texture := ImageTexture.create_from_image(image)
			sprite.texture = texture
			return
	push_warning("[IgnoreExpert] Failed to load texture: %s" % path)


func _stop_all_audio() -> void:
	for player in [sfx_talk, sfx_cutoff, sfx_success, sfx_fail]:
		if player and player.playing:
			player.stop()


func _play_safe(player: AudioStreamPlayer) -> void:
	if not presentation_enabled or not player:
		return
	player.stop()
	player.play()


func update_debug_state() -> void:
	if debug_state:
		debug_state.text = "State: %s" % State.keys()[current_state]


func _get_advice_deadline_for_tests() -> float:
	return _advice_deadline


func _get_total_duration_for_tests() -> float:
	return _total_duration
