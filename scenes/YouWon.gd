extends Control
## You Won screen

@onready var play_again_button: Button = $VBoxContainer/PlayAgainButton
@onready var main_menu_button: Button = $VBoxContainer/MainMenuButton

var _listening := false
var _valid := true  ## Flag to prevent callbacks after scene exit


func _ready() -> void:
	play_again_button.pressed.connect(_on_play_again)
	main_menu_button.pressed.connect(_on_main_menu)
	InputRouter.set_ui_mode()
	_connect_input()


func _exit_tree() -> void:
	_valid = false
	_disconnect_input()


func _connect_input() -> void:
	if not InputRouter.input_delivered.is_connected(_on_input_delivered):
		InputRouter.input_delivered.connect(_on_input_delivered)
	_listening = true


func _disconnect_input() -> void:
	if _listening and InputRouter.input_delivered.is_connected(_on_input_delivered):
		InputRouter.input_delivered.disconnect(_on_input_delivered)
	_listening = false


func _on_input_delivered(actions: Array) -> void:
	# Guard against input after scene exit
	if not _valid:
		return
	if InputRouter.has_action(actions, InputRouter.Action.CONFIRM):
		_on_play_again()
	elif InputRouter.has_action(actions, InputRouter.Action.CANCEL):
		_on_main_menu()


func _on_play_again() -> void:
	if not _valid:
		return
	RunManager.pending_mode = RunManager.current_mode
	get_tree().change_scene_to_file("res://scenes/GameRoot.tscn")


func _on_main_menu() -> void:
	if not _valid:
		return
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
