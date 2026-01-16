extends GutTest
## UI visibility tests for microgame phase (global HUD + microgame view)

var hud_scene = preload("res://scenes/hud.tscn")
var pandemic_view_scene = preload("res://microgames/mg02_end_the_pandemic/end_the_pandemic_view.tscn")

func test_hud_hides_run_ui_during_microgame():
	var hud = hud_scene.instantiate()
	add_child_autofree(hud)
	
	hud.show_run_start(ChaosManager.RunMode.NORMAL)
	assert_true(hud.is_timer_visible(), "Run timer should be visible before microgame")
	assert_true(hud.is_chaos_visible(), "Chaos label should be visible before microgame")
	
	hud.show_active()
	assert_false(hud.is_timer_visible(), "Run timer should be hidden during microgame")
	assert_false(hud.is_chaos_visible(), "Chaos label should be hidden during microgame")
	
	hud.show_resolve(true)
	assert_true(hud.is_timer_visible(), "Run timer should be visible after microgame")
	assert_true(hud.is_chaos_visible(), "Chaos label should be visible after microgame")

func test_end_the_pandemic_timer_is_non_numeric():
	var view = pandemic_view_scene.instantiate()
	add_child_autofree(view)
	
	var timer = view.get_node_or_null("TimerBar")
	assert_not_null(timer, "TimerBar node should exist in microgame view")
	assert_true(timer is ProgressBar or timer is TextureProgressBar, "TimerBar should be a ProgressBar type")
	
	var labels = _collect_labels(view)
	for label in labels:
		assert_false(label.text.find("TIME") >= 0, "Microgame view should not show TIME label")

func _collect_labels(root: Node) -> Array:
	var results: Array = []
	var stack: Array = [root]
	while stack.size() > 0:
		var node = stack.pop_back()
		if node is Label:
			results.append(node)
		for child in node.get_children():
			stack.append(child)
	return results
