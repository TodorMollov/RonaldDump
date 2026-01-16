# Microgame 01: Ignore The Expert

## Overview
**"Ignore The Expert"** is a microgame where the player must interrupt an expert giving advice by pressing any button before the expert finishes talking. Success requires acting quickly before the deadline.

## Gameplay
- **Objective**: Press any button/key while the expert is talking (before deadline)
- **Success**: First actionable input during ADVICE_ACTIVE phase before advice deadline
- **Failure**: Waiting past advice deadline OR overall timeout without input
- **Duration**: 3.5-4.5 seconds randomized (target avg ~4.0s, hard cap 5.0s)
- **Advice Deadline**: 1.8-2.2 seconds into the game (randomized, deterministic with seed)

## Architecture

This microgame uses an **adapter pattern** for framework integration:

- **`MicrogameIgnoreTheExpert.gd`**: Standalone Control-based implementation with full game logic
- **`MicrogameIgnoreTheExpertAdapter.gd`**: MicrogameBase adapter that wraps the implementation

The adapter allows the microgame to have its own clean API while remaining compatible with the framework's MicrogameBase interface. This separation of concerns makes the microgame more testable and maintainable.

## Technical Details

### State Machine
1. **INTRO** (0.0 - 0.3s): Input ignored during intro
2. **ADVICE_ACTIVE** (0.3s - deadline): Input triggers SUCCESS
3. **SUCCESS_RESOLVE**: Victory animation
4. **FAIL_RESOLVE**: Failure animation

### Input Handling
- **Accepted**: Keyboard keys, mouse clicks, joypad buttons
- **Ignored**: Mouse motion, key echo events
- **First input wins**: Additional inputs after resolution are ignored

### API

```gdscript
# Start the microgame
start_microgame(params := {}) -> void
# params:
#   - rng_seed: int (optional, default: randi())
#   - presentation_enabled: bool (optional, default: true)
#   - total_duration_sec: float (optional, random 3.5-4.5)

# Force resolution (called by framework on timeout)
force_resolve(outcome: int = Outcome.FAIL) -> void

# Get input policy for framework integration
get_input_policy() -> Dictionary
# Returns: {
#   "success_on_any_input": true,
#   "pointer_move_counts_as_input": false
# }

# Signal emitted when microgame resolves
signal resolved(outcome: int)  # Outcome.SUCCESS or Outcome.FAIL
```

### Assets
The microgame includes an auto-generation system for placeholder assets:
- **Images**: `ronald.png`, `expert.png`, `speech.png`
- **Audio**: `sfx_talk.wav`, `sfx_cutoff.wav`, `sfx_success.wav`, `sfx_fail.wav`

Assets are automatically generated on first run via `AssetBootstrap.gd` and can be replaced with proper assets by simply overwriting the generated files.

**Note:** On first instantiation, you may see "Failed loading resource" errors in the console as the system attempts to load assets before generating them. This is expected behavior - the microgame uses fallback textures until the next run when the generated assets will load successfully.

### Presentation Features
When `presentation_enabled = true`:
- Ronald character sprite (left side)
- Expert character sprite (right side)
- Speech bubble with procedural gibberish text
- Progress bar showing time until deadline
- Audio feedback (talk loop, cutoff, success/fail SFX)
- Character animations on success/fail

### Deterministic Behavior
All randomness (timing, text generation) is controlled by the provided RNG seed, ensuring deterministic behavior for testing and replays.

## Testing

### Manual Test
Run `test_manual.tscn` to verify basic functionality.

### Unit Tests
See `tests/unit/microgames/test_ignore_the_expert.gd` for comprehensive GUT tests:
- Input policy validation
- State machine transitions
- Input handling (keyboard, mouse, joypad)
- Timing and deadline mechanics
- Edge cases (key echo, mouse motion, force resolve)
- Deterministic behavior with seeds

## Files

### Core Implementation
- `MicrogameIgnoreTheExpert.gd` - Main microgame script (Control-based)
- `MicrogameIgnoreTheExpert.tscn` - Microgame scene file
- `MicrogameIgnoreTheExpertAdapter.gd` - Framework adapter (MicrogameBase)
- `MicrogameIgnoreTheExpertAdapter.tscn` - Adapter scene (used by framework)

### Utilities
- `ignore_rng_utils.gd` - Deterministic RNG utilities
- `assets/AssetBootstrap.gd` - Auto-generates placeholder assets
- `assets/AssetBootstrapPlugin.gd` - Editor plugin for asset generation
- `assets/plugin.cfg` - Plugin configuration

### Documentation & Testing
- `README.md` - This file
- `COMPLETION_STATUS.md` - Technical completion status
- `FINISHED.txt` - Summary
- `test_*.gd` / `test_*.tscn` - Test suites

## Integration
The microgame is registered in `scenes/boot.gd` using the adapter:

```gdscript
registry.register_microgame(
    "ignore_the_expert",
    "res://microgames/mg01_ignore_the_expert/MicrogameIgnoreTheExpertAdapter.tscn",
    2,  # weight
    "Ignore The Expert"
)
```

The adapter wraps the Control-based implementation and provides the MicrogameBase interface expected by the framework.

## Future Enhancements
- Replace placeholder assets with proper art
- Add more varied expert text patterns
- Add visual effects for success/failure
- Add difficulty variations (shorter/longer deadlines)
