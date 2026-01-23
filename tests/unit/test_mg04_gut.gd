extends GutTest
## GUT-based test for mg04_disinfectant_brainstorm
## Tests that the game loads from boot and can handle normal choice selection

const MG04_SCENE_PATH := "res://microgames/mg04_disinfectant_brainstorm/Microgame04_DisinfBrainstorm.tscn"
const Result = MicrogameBase.Result

var main_scene
var microgame


func before_each():
	"""Setup before each test"""
	main_scene = null
	microgame = null


func test_load_main_scene():
	"""Test that main boot scene loads"""
	var boot_scene = load("res://scenes/boot.tscn")
	assert_not_null(boot_scene, "Boot scene should load")
	
	main_scene = boot_scene.instantiate()
	assert_not_null(main_scene, "Boot scene should instantiate")
	
	get_tree().root.add_child(main_scene)
	assert_eq(main_scene.get_parent(), get_tree().root, "Scene should be added to tree")


func test_game_initializes():
	"""Test that game initializes with RunManager"""
	var boot_scene = load("res://scenes/boot.tscn")
	main_scene = boot_scene.instantiate()
	get_tree().root.add_child(main_scene)
	
	# Give it a frame to initialize
	await get_tree().process_frame
	
	assert_not_null(RunManager, "RunManager should be accessible")
	assert_not_null(MicrogameRegistry, "MicrogameRegistry should be accessible")


func test_mg04_loads_and_runs():
	"""Test that mg04 can be loaded and run"""
	var mg04_scene = load(MG04_SCENE_PATH)
	assert_not_null(mg04_scene, "mg04 scene should load")
	
	microgame = mg04_scene.instantiate()
	assert_not_null(microgame, "mg04 should instantiate")
	
	get_tree().root.add_child(microgame)
	microgame.activate({})
	
	# Start the microgame
	microgame.start_microgame({
		"rng_seed": 456,
		"presentation_enabled": false,
		"intro_sec": 0.0,
		"duration_sec": 5.0,
		"total_duration_sec": 5.0
	})
	microgame.on_active_start()
	
	# Give it a frame to start
	await get_tree().process_frame
	
	# Check that it's running
	assert_false(microgame._resolved, "Microgame should not resolve immediately after start")


func test_mg04_option_selection():
	"""Test that mg04 handles option selection"""
	var mg04_scene = load(MG04_SCENE_PATH)
	microgame = mg04_scene.instantiate()
	get_tree().root.add_child(microgame)
	microgame.activate({})
	
	# Start with presentation disabled
	microgame.start_microgame({
		"rng_seed": 456,
		"presentation_enabled": false,
		"intro_sec": 0.0,
		"duration_sec": 5.0,
		"total_duration_sec": 5.0
	})
	microgame.on_active_start()
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Select the normal option (Option A - "Consult experts")
	# This should fail since only the absurd option wins
	microgame._on_option_pressed(0)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Game should eventually resolve
	assert_true(microgame._resolved, "Microgame should resolve after option selection")
	assert_eq(microgame.microgame_result, Result.FAILURE, "Normal choice should fail (only absurd option wins)")


func test_mg04_win_condition():
	"""Test that mg04 success condition works"""
	var mg04_scene = load(MG04_SCENE_PATH)
	microgame = mg04_scene.instantiate()
	get_tree().root.add_child(microgame)
	microgame.activate({})
	
	# Start with presentation disabled
	microgame.start_microgame({
		"rng_seed": 456,
		"presentation_enabled": false,
		"intro_sec": 0.0,
		"duration_sec": 5.0,
		"total_duration_sec": 5.0
	})
	microgame.on_active_start()
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Select the absurd option (Option B - "!!! DRINK IT !!!")
	# Option B is index 1
	microgame._on_option_pressed(1)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Game should resolve as success
	assert_true(microgame._resolved, "Microgame should resolve after absurd choice")
	assert_eq(microgame.microgame_result, Result.SUCCESS, "Absurd choice should succeed")


func after_each():
	"""Cleanup after each test"""
	if main_scene and main_scene.is_inside_tree():
		main_scene.queue_free()
	if microgame and microgame.is_inside_tree():
		microgame.queue_free()
