extends Control
## Boot scene - Entry point of the game

func _ready() -> void:
	# Initialize registry
	var registry = MicrogameRegistry.new()
	
	# Register microgames
	registry.register_microgame(
		"end_the_pandemic",
		"res://microgames/mg02_end_the_pandemic/MicrogameEndThePandemic.tscn",
		1,
		"End The Pandemic"
	)
	registry.register_microgame(
		"ignore_the_expert",
		"res://microgames/mg01_ignore_the_expert/MicrogameIgnoreTheExpertAdapter.tscn",
		2,
		"Ignore The Expert"
	)
	registry.register_microgame(
		"mg04_disinfectant_brainstorm",
		"res://microgames/mg04_disinfectant_brainstorm/Microgame04_DisinfBrainstorm.tscn",
		2,
		"Think Big"
	)
	registry.register_microgame(
		"mg05_peace_deal_speedrun",
		"res://microgames/mg05_peace_deal_speedrun/Microgame05_PeaceDealSpeedrun.tscn",
		2,
		"Make Peace"
	)
	registry.register_microgame(
		"wall_builder",
		"res://microgames/mg03_wall_builder/WallBuilder.tscn",
		3,
		"Build The Wall"
	)
		
	
	
	# Initialize sequence manager
	SequenceManager.initialize(registry)
	
	# Transition to main menu after a frame
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
