extends GutTest
## Tests for ChaosManager - deterministic chaos growth

var chaos_manager: Node


func before_each():
	chaos_manager = ChaosManager
	chaos_manager.reset()


func after_each():
	chaos_manager.reset()


func test_chaos_manager_exists():
	assert_not_null(chaos_manager, "ChaosManager should exist")


func test_run_mode_enum():
	assert_true(ChaosManager.RunMode.NORMAL >= 0)
	assert_true(ChaosManager.RunMode.UNHINGED >= 0)
	assert_true(ChaosManager.RunMode.ENDLESS >= 0)


func test_initial_chaos():
	assert_eq(chaos_manager.current_chaos, 0.0, "Initial chaos should be 0")
	assert_eq(chaos_manager.microgames_completed, 0, "Initial microgames count should be 0")


func test_chaos_increment_normal_mode():
	chaos_manager.reset(ChaosManager.RunMode.NORMAL)
	var initial = chaos_manager.current_chaos
	chaos_manager.increment_chaos()
	var after = chaos_manager.current_chaos
	assert_gt(after, initial, "Chaos should increase")
	assert_eq(chaos_manager.microgames_completed, 1, "Microgames count should be 1")


func test_chaos_increment_unhinged_mode():
	chaos_manager.reset(ChaosManager.RunMode.UNHINGED)
	chaos_manager.increment_chaos()
	var unhinged_chaos = chaos_manager.current_chaos
	
	chaos_manager.reset(ChaosManager.RunMode.NORMAL)
	chaos_manager.increment_chaos()
	var normal_chaos = chaos_manager.current_chaos
	
	assert_gt(unhinged_chaos, normal_chaos, "Unhinged mode should have higher chaos multiplier")


func test_chaos_clamped_to_one():
	chaos_manager.reset(ChaosManager.RunMode.NORMAL)
	
	# Increment many times
	for i in range(100):
		chaos_manager.increment_chaos()
	
	assert_lte(chaos_manager.current_chaos, 1.0, "Chaos should be clamped to 1.0")


func test_chaos_categories():
	chaos_manager.current_chaos = 0.1
	assert_eq(chaos_manager.get_chaos_category(), "LOW")
	
	chaos_manager.current_chaos = 0.3
	assert_eq(chaos_manager.get_chaos_category(), "MEDIUM")
	
	chaos_manager.current_chaos = 0.6
	assert_eq(chaos_manager.get_chaos_category(), "HIGH")
	
	chaos_manager.current_chaos = 0.8
	assert_eq(chaos_manager.get_chaos_category(), "EXTREME")


func test_visual_intensity():
	chaos_manager.current_chaos = 0.5
	assert_almost_eq(chaos_manager.get_visual_intensity(), 0.5, 0.01)


func test_screen_shake_threshold():
	chaos_manager.current_chaos = 0.3
	assert_false(chaos_manager.should_apply_screen_shake(), "Screen shake should not apply below 0.4")
	
	chaos_manager.current_chaos = 0.5
	assert_true(chaos_manager.should_apply_screen_shake(), "Screen shake should apply above 0.4")


func test_screen_shake_intensity():
	chaos_manager.current_chaos = 0.4
	assert_almost_eq(chaos_manager.get_screen_shake_intensity(), 0.0, 0.01)
	
	chaos_manager.current_chaos = 0.7
	var intensity = chaos_manager.get_screen_shake_intensity()
	assert_gt(intensity, 0.0, "Screen shake intensity should be positive")
	assert_lte(intensity, 1.0, "Screen shake intensity should be <= 1.0")
