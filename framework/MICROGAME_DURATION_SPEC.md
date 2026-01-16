# Microgame Duration Specification - Framework Level

## Overview

All microgames in the RonaldDump framework MUST follow these duration rules. The specification is enforced at the framework level through `GlobalTimingController`.

---

## Specification

### Requirements

✅ **Range:** 3-5 seconds per microgame  
✅ **Randomized Range:** 3.5-4.5 seconds  
✅ **Target Average:** ~4.0 seconds  
✅ **Hard Cap:** Never exceed 5.0 seconds  

---

## Implementation

### Constants (GlobalTimingController)

```gdscript
const MICROGAME_DURATION_MIN: float = 3.5
const MICROGAME_DURATION_MAX: float = 4.5
const MICROGAME_DURATION_HARD_CAP: float = 5.0
const MICROGAME_DURATION_TARGET: float = 4.0
```

### Functions

#### `get_random_microgame_duration() -> float`
Returns a randomized duration within specification (3.5-4.5s, capped at 5.0s).

**Use this for normal gameplay.**

```gdscript
var duration = GlobalTimingController.get_random_microgame_duration()
# Returns: 3.5-4.5 seconds (hard cap 5.0s)
```

#### `get_target_microgame_duration() -> float`
Returns the target average duration (4.0s).

**Use this for testing or deterministic scenarios.**

```gdscript
var duration = GlobalTimingController.get_target_microgame_duration()
# Returns: 4.0 seconds
```

#### `get_microgame_duration_with_seed(seed_value: int) -> float`
Returns a deterministic randomized duration using the provided seed.

**Use this for replays and deterministic testing.**

```gdscript
var duration = GlobalTimingController.get_microgame_duration_with_seed(12345)
# Returns: Same duration every time with same seed
```

#### `validate_microgame_duration(duration: float) -> bool`
Validates if a duration meets the specification.

**Use this to verify custom durations.**

```gdscript
if GlobalTimingController.validate_microgame_duration(my_duration):
    # Duration is valid
```

---

## Usage in Microgames

### MicrogameBase Helpers

All microgames extend `MicrogameBase`, which provides convenience methods:

```gdscript
# Get framework-specified random duration
var duration = get_framework_duration()

# Get target duration (for testing)
var target = get_target_duration()
```

### Example: Adapter Pattern

```gdscript
extends MicrogameBase

func on_active_start() -> void:
    super.on_active_start()
    
    # Get framework-specified duration
    var duration = get_framework_duration()
    
    # Pass to internal implementation
    microgame_instance.start_microgame({
        "total_duration_sec": duration
    })
```

### Example: Direct Implementation

```gdscript
extends MicrogameBase

func on_activate() -> void:
    super.on_activate()
    
    # Get framework duration
    var duration = get_framework_duration()
    
    # Use it for your timing
    my_timer.wait_time = duration
    my_timer.start()
```

---

## Why This Specification?

### Game Flow
- **Too Short (< 3s):** Not enough time for player to react
- **Too Long (> 5s):** Breaks pacing, loses "microgame" feel
- **Sweet Spot (3.5-4.5s):** Perfect reaction time

### Randomization
- **Prevents Predictability:** Players can't memorize timing
- **Maintains Interest:** Slight variations keep gameplay fresh
- **Fair Distribution:** Average ~4.0s ensures consistency

### Hard Cap
- **Absolute Limit:** No matter what, never exceed 5.0s
- **Safety Net:** Protects against bugs or edge cases
- **Consistent Experience:** Players know max duration

---

## Testing

### Unit Tests

See `tests/test_framework_duration.gd` for comprehensive tests:
- Constant validation
- Random duration generation
- Deterministic seeded generation
- Duration validation
- Distribution testing

### Integration Test

```gdscript
# Test in your microgame
var duration = get_framework_duration()
assert(GlobalTimingController.validate_microgame_duration(duration))
```

---

## Migration Guide

### For Existing Microgames

**Before:**
```gdscript
# Hardcoded or ad-hoc duration
var duration = 5.0
```

**After:**
```gdscript
# Use framework-specified duration
var duration = get_framework_duration()
```

### For New Microgames

Always use the framework helpers:

```gdscript
extends MicrogameBase

func on_active_start() -> void:
    super.on_active_start()
    var duration = get_framework_duration()
    # Use duration...
```

---

## Benefits

✅ **Consistency:** All microgames follow same timing rules  
✅ **Centralized:** Change spec in one place affects all microgames  
✅ **Testable:** Easy to verify compliance  
✅ **Documented:** Clear specification for all developers  
✅ **Flexible:** Can adjust spec without touching individual microgames  

---

## Status

🎉 **IMPLEMENTED AND TESTED**

- ✅ Framework-level constants defined
- ✅ Helper functions implemented
- ✅ MicrogameBase integration complete
- ✅ Unit tests pass
- ✅ Documentation complete
- ✅ Example microgame updated

**All microgames now automatically follow the duration specification!**
