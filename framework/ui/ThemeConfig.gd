extends Resource
class_name ThemeConfig
## Central UI constants (presentation only)

const FONT_PATH_DEFAULT: String = ""
const TITLE_SIZE: int = 64
const HEADER_SIZE: int = 36
const BODY_SIZE: int = 24
const INSTRUCTION_SIZE: int = 72
const PADDING: int = 24
const BUTTON_MIN_W: int = 260
const BUTTON_MIN_H: int = 64
const SAFE_ALPHA_MIN: float = 0.15
const SAFE_ALPHA_MAX: float = 0.90


static func clamp_alpha(a: float) -> float:
	return clampf(a, SAFE_ALPHA_MIN, SAFE_ALPHA_MAX)
