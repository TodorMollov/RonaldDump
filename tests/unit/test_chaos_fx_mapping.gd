extends GutTest
## Tests for chaos tier to FX mapping

var chaos_manager: Node


func before_each():
	chaos_manager = ChaosManager
	chaos_manager.reset(ChaosManager.RunMode.NORMAL)


func test_fx_config_tier_zero():
	chaos_manager.chaos_level = 0.0
	var fx = chaos_manager.get_fx_config()
	assert_false(fx["ui_jitter"])
	assert_eq(fx["screen_shake_strength"], 0.0)
	assert_eq(fx["noise_opacity"], 0.0)


func test_fx_config_tier_five_values():
	chaos_manager.chaos_level = ChaosManager.TIER_STEP * 5.0
	var fx = chaos_manager.get_fx_config()
	assert_true(fx["ui_jitter"])
	assert_eq(fx["screen_shake_strength"], 0.6)
	assert_eq(fx["noise_opacity"], 0.35)
	assert_eq(fx["fake_ui_density"], 0.30)
	assert_eq(fx["flicker_interval"], 0.20)
