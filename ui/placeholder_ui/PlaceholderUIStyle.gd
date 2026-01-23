extends Node
class_name PlaceholderUIStyle
## Shared UI styling for placeholder/early-stage microgames
## Provides constants and helpers for consistent visual appearance across all placeholder microgames

# ============================================================
# COLORS (using Color8 for easy RGB values)
# ============================================================

const BG_DARK := Color8(30, 30, 30)
const PRIMARY_URGENT := Color8(220, 60, 60)
const PRIMARY_WARNING := Color8(255, 190, 60)
const TEXT_NOISE := Color8(240, 240, 240, 180)
const BUBBLE_BG := Color8(245, 245, 245)
const BUBBLE_OUTLINE := Color8(40, 40, 40)

# ============================================================
# SIZES
# ============================================================

const ADVICE_BAR_HEIGHT := 28
const BUBBLE_SIZE := Vector2(320, 140)
const BUBBLE_PADDING := 20
const CHARACTER_SCALE_RONALD := 1.15
const CHARACTER_SCALE_EXPERT := 0.95

# ============================================================
# MOTION PARAMETERS (values only, no tweens)
# ============================================================

const IDLE_BOB_AMPLITUDE := 6.0
const IDLE_BOB_SPEED := 3.0
const INTERRUPT_JERK_PIXELS := 24.0
const EXPERT_TALK_JITTER_RANGE := 3.0

# ============================================================
# HELPER FUNCTIONS (pure, no state)
# ============================================================

## Get advice bar color based on progress (0.0 to 1.0)
## Returns urgent red <70%, warning orange >=70%
static func advice_bar_color(progress: float) -> Color:
	if progress < 0.7:
		return PRIMARY_URGENT
	return PRIMARY_WARNING

## Get text alpha for unreadable placeholder text
static func unreadable_text_alpha() -> float:
	return 0.75
