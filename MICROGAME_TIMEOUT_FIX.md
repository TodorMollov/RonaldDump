# Microgame Timeout Bug - FIXED

## Problem

Microgames were not transitioning to the next game after completing. The game would get stuck on one microgame indefinitely (showing TIME: 134.9s from the 150-second run duration, but the microgame itself never ending).

## Root Cause

In `RunManager._start_active_phase()`, when a microgame resolved (either through player input or timeout), the code would:

1. Wait for `GlobalTimingController.phase_complete` 
2. Disable input
3. Check if microgame was resolved
4. **But then do nothing!** ❌

The `_finish_microgame()` function was only called in the timeout case via `_force_neutral_resolve()`, but not when a microgame resolved normally.

### Old Code Flow

```gdscript
await GlobalTimingController.phase_complete

InputRouter.disable_input()
InputRouter.input_delivered.disconnect(_on_input_delivered)

# Force resolve if not already resolved
if active_microgame and not active_microgame.is_resolved():
    active_microgame.on_active_end()
    _force_neutral_resolve()  // Only called if NOT resolved!
// Function ends here - nothing happens if resolved! ❌
```

**Result:** Microgames that resolved would never transition to the next one.

---

## Solution

Always call `_finish_microgame()` after the active phase completes, regardless of how the microgame resolved.

### New Code Flow

```gdscript
await GlobalTimingController.phase_complete

InputRouter.disable_input()
InputRouter.input_delivered.disconnect(_on_input_delivered)

# Force resolve if not already resolved
if active_microgame and not active_microgame.is_resolved():
    active_microgame.on_active_end()

# Finish the microgame (whether it resolved early or timed out)
if active_microgame:
    var success = active_microgame.get_result() == MicrogameBase.Result.SUCCESS
    _finish_microgame(success)  // ✓ Always called!
```

**Result:** All microgames properly transition to the next one after completing.

---

## Changes Made

### File: `autoload/run_manager.gd`

**1. Updated `_start_active_phase()`**
   - Added call to `_finish_microgame()` after phase completes
   - Removed conditional logic that prevented finishing on early resolve

**2. Updated `_on_microgame_resolved()`**
   - Simplified to just force resolve
   - Result is already set by microgame's resolve methods
   - Added underscore prefix to unused `success` parameter

---

## Verification

### Before Fix
- ❌ Microgame stays on screen indefinitely
- ❌ Timer counts down run time (150s → 0s)
- ❌ Never transitions to next microgame

### After Fix
- ✓ Microgames complete after ~4 seconds (ACTIVE_DURATION)
- ✓ Properly transitions to next microgame
- ✓ Run progresses normally through multiple microgames

---

## Testing

### Manual Test
1. Start game (Normal mode)
2. Play "DO NOTHING" microgame (test_zero_input)
3. Wait ~4 seconds
4. **Expected:** Microgame resolves and transitions to next one
5. **Result:** ✓ Works correctly!

### Edge Cases Tested
- ✓ Microgame resolves early (player input)
- ✓ Microgame times out (no input)
- ✓ Multiple microgames in sequence
- ✓ Different microgame types (any input, zero input, directional)

---

## Status

🎉 **FIXED AND VERIFIED**

- ✓ No compilation errors
- ✓ No linter warnings
- ✓ Microgames properly time out after 4 seconds
- ✓ Transitions work correctly
- ✓ All microgame types tested

**The game now works properly! Each microgame lasts 3.5-4.5 seconds (with the framework duration spec) or exactly 4 seconds for the ACTIVE phase, then transitions to the next microgame.**
