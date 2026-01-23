extends GutTest
## Tests for ThemeConfig

const ThemeConfig = preload("res://framework/ui/ThemeConfig.gd")


func test_constants_exist():
	assert_true(ThemeConfig.TITLE_SIZE > 0)
	assert_true(ThemeConfig.HEADER_SIZE > 0)
	assert_true(ThemeConfig.BODY_SIZE > 0)
	assert_true(ThemeConfig.INSTRUCTION_SIZE > 0)
	assert_true(ThemeConfig.BUTTON_MIN_W > 0)
	assert_true(ThemeConfig.BUTTON_MIN_H > 0)


func test_clamp_alpha_bounds():
	assert_eq(ThemeConfig.clamp_alpha(0.0), ThemeConfig.SAFE_ALPHA_MIN)
	assert_eq(ThemeConfig.clamp_alpha(2.0), ThemeConfig.SAFE_ALPHA_MAX)
	var mid = (ThemeConfig.SAFE_ALPHA_MIN + ThemeConfig.SAFE_ALPHA_MAX) * 0.5
	assert_eq(ThemeConfig.clamp_alpha(mid), mid)
