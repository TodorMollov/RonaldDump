extends GutTest
## Tests for ChaosManager accumulation and tier mapping

var chaos_manager: Node


func before_each():
	chaos_manager = ChaosManager
	chaos_manager.reset(ChaosManager.RunMode.NORMAL)


func after_each():
	chaos_manager.reset(ChaosManager.RunMode.NORMAL)


func test_success_increment_normal_mode():
	chaos_manager.reset(ChaosManager.RunMode.NORMAL)
	chaos_manager.apply_microgame_result(true, false)
	assert_almost_eq(
		chaos_manager.get_chaos_level(),
		ChaosManager.BASE_SUCCESS,
		0.001
	)


func test_failure_increment_unhinged_mode():
	chaos_manager.reset(ChaosManager.RunMode.UNHINGED)
	chaos_manager.apply_microgame_result(false, false)
	var expected = ChaosManager.BASE_FAILURE * ChaosManager.MODE_MULT[ChaosManager.RunMode.UNHINGED]
	assert_almost_eq(chaos_manager.get_chaos_level(), expected, 0.001)


func test_forced_resolve_does_not_change_chaos():
	chaos_manager.chaos_level = 2.0
	chaos_manager.apply_microgame_result(true, true)
	assert_eq(chaos_manager.get_chaos_level(), 2.0)


func test_tier_mapping():
	chaos_manager.chaos_level = 0.0
	assert_eq(chaos_manager.get_tier(), 0)
	
	chaos_manager.chaos_level = ChaosManager.TIER_STEP - 0.01
	assert_eq(chaos_manager.get_tier(), 0)
	
	chaos_manager.chaos_level = ChaosManager.TIER_STEP
	assert_eq(chaos_manager.get_tier(), 1)
	
	chaos_manager.chaos_level = ChaosManager.TIER_STEP * 2.0
	assert_eq(chaos_manager.get_tier(), 2)
	
	chaos_manager.chaos_level = ChaosManager.TIER_STEP * ChaosManager.MAX_TIER + 0.5
	assert_eq(chaos_manager.get_tier(), ChaosManager.MAX_TIER)
