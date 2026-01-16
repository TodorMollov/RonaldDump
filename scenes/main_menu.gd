extends Control
## Main Menu - Mode selection

@onready var normal_button = $VBoxContainer/NormalButton
@onready var unhinged_button = $VBoxContainer/UnhingedButton
@onready var endless_button = $VBoxContainer/EndlessButton


func _ready() -> void:
	normal_button.pressed.connect(_on_normal_pressed)
	unhinged_button.pressed.connect(_on_unhinged_pressed)
	endless_button.pressed.connect(_on_endless_pressed)
	
	# Enable UI input
	InputRouter.set_ui_mode()


func _on_normal_pressed() -> void:
	_start_game(ChaosManager.RunMode.NORMAL)


func _on_unhinged_pressed() -> void:
	_start_game(ChaosManager.RunMode.UNHINGED)


func _on_endless_pressed() -> void:
	_start_game(ChaosManager.RunMode.ENDLESS)


func _start_game(mode: ChaosManager.RunMode) -> void:
	# Store mode in RunManager so game_root can access it
	RunManager.pending_mode = mode
	get_tree().change_scene_to_file("res://scenes/game_root.tscn")
