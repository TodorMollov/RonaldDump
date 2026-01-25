extends Control
## Boot scene - Entry point of the game

func _ready() -> void:
	# Initialize registry
	MicrogameRegistry.clear()
	
	# Register production microgames (all now extend MicrogameBase)
	MicrogameRegistry.register_microgame(
		"ignore_the_expert",
		"res://microgames/mg01_ignore_the_expert/MicrogameIgnoreTheExpert.tscn",
		1.0,
		true
	)
	MicrogameRegistry.register_microgame(
		"end_the_pandemic",
		"res://microgames/mg02_end_the_pandemic/MicrogameEndThePandemic.tscn",
		1.0,
		false
	)
	MicrogameRegistry.register_microgame(
		"wall_builder",
		"res://microgames/mg03_wall_builder/WallBuilder.tscn",
		1.0,
		false
	)
	MicrogameRegistry.register_microgame(
		"disinfectant_brainstorm",
		"res://microgames/mg04_disinfectant_brainstorm/Microgame04_DisinfBrainstorm.tscn",
		1.0,
		false
	)
	MicrogameRegistry.register_microgame(
		"peace_deal_speedrun",
		"res://microgames/mg05_peace_deal_speedrun/Microgame05_PeaceDealSpeedrun.tscn",
		1.0,
		false
	)
	
	# Initialize sequence manager
	SequenceManager.initialize(MicrogameRegistry)
	
	# Transition to main menu after a frame
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
