extends Control
## Main Menu - Mode selection

@onready var normal_button: Button = $VBoxContainer/NormalButton
@onready var unhinged_button: Button = $VBoxContainer/UnhingedButton
@onready var endless_button: Button = $VBoxContainer/EndlessButton

var _listening := false


func _ready() -> void:
	normal_button.pressed.connect(_on_normal_pressed)
	unhinged_button.pressed.connect(_on_unhinged_pressed)
	endless_button.pressed.connect(_on_endless_pressed)
	
	InputRouter.set_ui_mode()
	_connect_input()


func _exit_tree() -> void:
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
	if InputRouter.has_action(actions, InputRouter.Action.CONFIRM):
		_start_game(ChaosManager.RunMode.NORMAL)


func _on_normal_pressed() -> void:
	_start_game(ChaosManager.RunMode.NORMAL)


func _on_unhinged_pressed() -> void:
	_start_game(ChaosManager.RunMode.UNHINGED)


func _on_endless_pressed() -> void:
	_start_game(ChaosManager.RunMode.ENDLESS)


func _start_game(mode: ChaosManager.RunMode) -> void:
	RunManager.pending_mode = mode
	get_tree().change_scene_to_file("res://scenes/GameRoot.tscn")
