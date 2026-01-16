extends Control
## HUD - Displays instruction, timer, chaos level, and results

@onready var instruction_label = $InstructionLabel
@onready var timer_label = $TimerLabel
@onready var chaos_label = $ChaosLabel
@onready var result_label = $ResultLabel
@onready var you_won_panel = $YouWonPanel
@onready var play_again_button = $YouWonPanel/VBoxContainer/PlayAgainButton
@onready var main_menu_button = $YouWonPanel/VBoxContainer/MainMenuButton


func _ready() -> void:
	instruction_label.hide()
	result_label.hide()
	you_won_panel.hide()
	# Default to run mode visibility
	set_microgame_mode(false)
	
	play_again_button.pressed.connect(_on_play_again)
	main_menu_button.pressed.connect(_on_main_menu)
	
	set_process(true)


func _process(_delta: float) -> void:
	if RunManager.is_running():
		var remaining = RunManager.get_run_time_remaining()
		timer_label.text = "TIME: %.1fs" % remaining


func show_run_start(mode: ChaosManager.RunMode) -> void:
	result_label.hide()
	you_won_panel.hide()
	set_microgame_mode(false)
	
	var mode_text = ""
	match mode:
		ChaosManager.RunMode.NORMAL:
			mode_text = "NORMAL"
		ChaosManager.RunMode.UNHINGED:
			mode_text = "UNHINGED"
		ChaosManager.RunMode.ENDLESS:
			mode_text = "ENDLESS"
	
	instruction_label.text = "MODE: " + mode_text
	instruction_label.show()


func show_instruction(text: String) -> void:
	instruction_label.text = text
	instruction_label.show()
	result_label.hide()


func show_active() -> void:
	# Keep instruction visible during active phase
	set_microgame_mode(true)


func show_resolve(success: bool) -> void:
	result_label.text = "SUCCESS!" if success else "FAILURE!"
	result_label.modulate = Color.GREEN if success else Color.RED
	result_label.show()
	set_microgame_mode(false)
	
	# Hide instruction
	instruction_label.hide()


func show_you_won() -> void:
	instruction_label.hide()
	result_label.hide()
	you_won_panel.show()
	set_microgame_mode(false)


func update_chaos(value: float) -> void:
	var category = ChaosManager.get_chaos_category()
	chaos_label.text = "CHAOS: %s (%.0f%%)" % [category, value * 100]


func set_microgame_mode(is_active: bool) -> void:
	# Hide global run UI during microgame gameplay
	timer_label.visible = not is_active
	chaos_label.visible = not is_active


func is_timer_visible() -> bool:
	return timer_label.visible


func is_chaos_visible() -> bool:
	return chaos_label.visible


func _on_play_again() -> void:
	get_tree().reload_current_scene()


func _on_main_menu() -> void:
	RunManager.reset()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
