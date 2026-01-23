extends MicrogameBase
const Style = preload("res://ui/placeholder_ui/PlaceholderUIStyle.gd")

## Manual Test Checklist
## - Start a run; ensure instruction is "Build Wall"
## - A block spawns immediately
## - Left/right move the active block within bounds
## - Confirm instantly drops and locks in lowest available cell
## - Without confirming, block auto-falls and locks when landing
## - Fill any 2 rows → immediate success resolve
## - Attempt to overflow a column until spawn is blocked → failure resolve
## - After resolution, further input does nothing

enum State {
	INTRO,
	ACTIVE,
	SUCCESS_RESOLVE,
	FAIL_RESOLVE
}

const COLS := 3
const ROWS := 4
const CELL_SIZE := 48.0
const GRID_ORIGIN := Vector2(240, 160)
const FALL_INTERVAL_MIN := 0.20
const FALL_INTERVAL_MAX := 0.36

@onready var visual_root: Node2D = $VisualRoot
@onready var grid_root: Node2D = $VisualRoot/GridRoot
@onready var grid_background: ColorRect = $VisualRoot/GridRoot/GridBackground
@onready var grid_lines: Node2D = $VisualRoot/GridRoot/GridLines
@onready var blocks_root: Node2D = $VisualRoot/GridRoot/BlocksRoot
@onready var active_block: ColorRect = $VisualRoot/GridRoot/ActiveBlock
@onready var border_line: ColorRect = $VisualRoot/GridRoot/BorderLine
@onready var ronald_root: Node2D = $VisualRoot/RonaldRoot
@onready var ronald_placeholder: ColorRect = $VisualRoot/RonaldRoot/RonaldPlaceholder
@onready var ronald_label: Label = $VisualRoot/RonaldRoot/RonaldLabel

var current_state: State = State.INTRO
var grid: Array = []
var bottom_row_complete: bool = false
var active_col: int = 0
var active_row: int = 0
var has_active: bool = false
var resolved_once: bool = false

var fall_timer: Timer = null
var fall_interval := 0.27
var rng := RandomNumberGenerator.new()

var presentation_enabled := true

func _ready() -> void:
	_setup_timer()
	_setup_visuals()
	set_process(false)

func on_activate() -> void:
	super.on_activate()
	input_policy = InputRouter.InputPolicy.new(false, false, false, [
		InputRouter.Action.MOVE_LEFT,
		InputRouter.Action.MOVE_RIGHT,
		InputRouter.Action.CONFIRM
	], [])
	_reset_state()
	_spawn_block()

func activate(_context := {}) -> void:
	is_active = true
	microgame_result = Result.NONE
	on_activate()

func on_active_start() -> void:
	super.on_active_start()
	is_active = true
	current_state = State.ACTIVE
	_start_fall_timer()

func on_active_end() -> void:
	super.on_active_end()
	is_active = false
	_stop_fall_timer()
	if not is_resolved():
		force_resolve(Result.FAILURE)

func on_deactivate() -> void:
	super.on_deactivate()
	is_active = false
	_stop_fall_timer()
	_clear_blocks()
	active_block.visible = false

func get_instruction_text() -> String:
	return "Build Wall"

func get_input_policy() -> InputRouter.InputPolicy:
	return input_policy

func on_input(actions: Array) -> void:
	if not is_active or resolved_once:
		return
	if current_state != State.ACTIVE:
		return
	for action in actions:
		match action:
			InputRouter.Action.MOVE_LEFT:
				_move_active(-1)
			InputRouter.Action.MOVE_RIGHT:
				_move_active(1)
			InputRouter.Action.CONFIRM:
				_hard_drop_and_lock()
			_:
				pass

func force_resolve(outcome: int = Result.FAILURE) -> void:
	if resolved_once:
		return
	if outcome == Result.SUCCESS:
		_resolve_success()
	else:
		_resolve_fail()

func start_microgame(params := {}) -> void:
	"""Optional start hook for tests or manual runs."""
	presentation_enabled = params.get("presentation_enabled", true)
	var seed = params.get("rng_seed", null)
	if seed != null:
		rng.seed = seed
	else:
		rng.randomize()
	fall_interval = rng.randf_range(FALL_INTERVAL_MIN, FALL_INTERVAL_MAX)
	_setup_visuals()

func _reset_state() -> void:
	grid.clear()
	for r in range(ROWS):
		var row: Array = []
		for c in range(COLS):
			row.append(false)
		grid.append(row)
	bottom_row_complete = false
	resolved_once = false
	is_active = false
	current_state = State.INTRO
	has_active = false
	active_block.visible = false
	_clear_blocks()

func _spawn_block() -> void:
	var spawn_col = _find_spawn_column()
	if spawn_col < 0:
		_overflow_fail()
		return
	_spawn_block_at(spawn_col)

func _find_spawn_column() -> int:
	var center = int(COLS / 2)
	var candidates: Array = []
	candidates.append(center)
	for offset in range(1, COLS):
		var left = center - offset
		var right = center + offset
		if left >= 0:
			candidates.append(left)
		if right < COLS:
			candidates.append(right)
	for col in candidates:
		if not grid[0][col]:
			return col
	return -1

func _spawn_block_at(col: int) -> void:
	active_col = clampi(col, 0, COLS - 1)
	active_row = 0
	if grid[active_row][active_col]:
		_overflow_fail()
		return
	has_active = true
	_update_active_visual()

func _move_active(delta: int) -> void:
	if not has_active:
		return
	var target = clampi(active_col + delta, 0, COLS - 1)
	if grid[active_row][target]:
		return
	active_col = target
	_update_active_visual()

func _start_fall_timer() -> void:
	if fall_timer:
		fall_timer.wait_time = fall_interval
		fall_timer.start()

func _stop_fall_timer() -> void:
	if fall_timer:
		fall_timer.stop()

func _on_fall_tick() -> void:
	if not is_active or resolved_once:
		return
	if not has_active:
		return
	if _can_move_down():
		active_row += 1
		_update_active_visual()
	else:
		_lock_current_cell()

func _can_move_down() -> bool:
	if active_row + 1 >= ROWS:
		return false
	return not grid[active_row + 1][active_col]

func _hard_drop_and_lock() -> void:
	if not has_active:
		return
	while _can_move_down():
		active_row += 1
	_update_active_visual()
	_lock_current_cell()

func _lock_current_cell() -> void:
	if resolved_once:
		return
	grid[active_row][active_col] = true
	_spawn_locked_visual(active_row, active_col)
	if _is_bottom_row_full():
		bottom_row_complete = true
		_resolve_success()
		return
	_spawn_block()

func _is_bottom_row_full() -> bool:
	var row = ROWS - 1
	for c in range(COLS):
		if not grid[row][c]:
			return false
	return true

func _resolve_success() -> void:
	if resolved_once:
		return
	resolved_once = true
	current_state = State.SUCCESS_RESOLVE
	_stop_fall_timer()
	resolve_success()

func _resolve_fail() -> void:
	if resolved_once:
		return
	resolved_once = true
	current_state = State.FAIL_RESOLVE
	_stop_fall_timer()
	resolve_failure()

func _overflow_fail() -> void:
	_resolve_fail()

func _spawn_locked_visual(row: int, col: int) -> void:
	if not presentation_enabled:
		return
	var block = ColorRect.new()
	block.color = Style.PRIMARY_WARNING
	block.size = Vector2(CELL_SIZE, CELL_SIZE)
	block.position = _grid_to_position(row, col)
	blocks_root.add_child(block)

func _update_active_visual() -> void:
	if not presentation_enabled:
		return
	active_block.visible = true
	active_block.size = Vector2(CELL_SIZE, CELL_SIZE)
	active_block.color = Style.PRIMARY_URGENT
	active_block.position = _grid_to_position(active_row, active_col)

func _grid_to_position(row: int, col: int) -> Vector2:
	return GRID_ORIGIN + Vector2(col * CELL_SIZE, row * CELL_SIZE)

func _setup_timer() -> void:
	fall_timer = Timer.new()
	fall_timer.one_shot = false
	fall_timer.wait_time = fall_interval
	fall_timer.timeout.connect(_on_fall_tick)
	add_child(fall_timer)

func _setup_visuals() -> void:
	if not presentation_enabled:
		return
	grid_root.position = Vector2.ZERO
	grid_background.position = GRID_ORIGIN
	grid_background.size = Vector2(COLS * CELL_SIZE, ROWS * CELL_SIZE)
	grid_background.color = Style.BG_DARK
	_build_grid_lines()
	active_block.visible = false
	border_line.position = GRID_ORIGIN + Vector2(0, ROWS * CELL_SIZE + 4)
	border_line.size = Vector2(COLS * CELL_SIZE, 4)
	border_line.color = Style.TEXT_NOISE
	_setup_ronald_placeholder()

func _build_grid_lines() -> void:
	for child in grid_lines.get_children():
		child.queue_free()
	var line_color = Style.TEXT_NOISE
	for c in range(COLS + 1):
		var line = Line2D.new()
		line.width = 2.0
		line.default_color = line_color
		var x = GRID_ORIGIN.x + c * CELL_SIZE
		line.add_point(Vector2(x, GRID_ORIGIN.y))
		line.add_point(Vector2(x, GRID_ORIGIN.y + ROWS * CELL_SIZE))
		grid_lines.add_child(line)
	for r in range(ROWS + 1):
		var line_h = Line2D.new()
		line_h.width = 2.0
		line_h.default_color = line_color
		var y = GRID_ORIGIN.y + r * CELL_SIZE
		line_h.add_point(Vector2(GRID_ORIGIN.x, y))
		line_h.add_point(Vector2(GRID_ORIGIN.x + COLS * CELL_SIZE, y))
		grid_lines.add_child(line_h)

func _setup_ronald_placeholder() -> void:
	ronald_root.position = GRID_ORIGIN + Vector2(COLS * CELL_SIZE + 60, 40)
	ronald_placeholder.position = Vector2.ZERO
	ronald_placeholder.size = Vector2(120, 180)
	ronald_placeholder.color = Style.PRIMARY_WARNING
	ronald_label.position = Vector2(10, 10)
	ronald_label.text = "RONALD"

func _clear_blocks() -> void:
	for child in blocks_root.get_children():
		child.queue_free()

# ---- Test helpers ----
func _get_cell_for_tests(row: int, col: int) -> bool:
	return grid[row][col]

func _set_cell_for_tests(row: int, col: int, filled: bool) -> void:
	grid[row][col] = filled

func _is_bottom_row_full_for_tests() -> bool:
	return _is_bottom_row_full()

func _clear_active_for_tests() -> void:
	has_active = false
	active_block.visible = false

func _force_spawn_for_tests(col: int) -> void:
	_spawn_block_at(col)

func _force_active_for_tests(row: int, col: int) -> void:
	active_row = row
	active_col = col
	has_active = true
	_update_active_visual()

func _lock_active_for_tests() -> void:
	_lock_current_cell()

func _get_active_col_for_tests() -> int:
	return active_col

func _get_active_row_for_tests() -> int:
	return active_row
