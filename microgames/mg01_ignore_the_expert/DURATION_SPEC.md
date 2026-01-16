# Duration Specification - Verified

## Requirements

✅ **3-5 seconds per microgame**  
✅ **Target average: ~4.0 seconds**  
✅ **Randomized range: 3.5-4.5 seconds**  
✅ **Hard cap: never exceed 5.0 seconds**

---

## Implementation

### Adapter (MicrogameIgnoreTheExpertAdapter.gd)

```gdscript
func on_active_start() -> void:
    # Duration: 3.5-4.5 seconds randomized, target average ~4.0s, hard cap 5.0s
    var duration = randf_range(3.5, 4.5)
    duration = minf(duration, 5.0)  # Hard cap at 5.0 seconds
    
    microgame_instance.start_microgame({
        "rng_seed": randi(),
        "presentation_enabled": true,
        "total_duration_sec": duration
    })
```

### Internal Microgame (MicrogameIgnoreTheExpert.gd)

```gdscript
# Default duration if not specified by adapter
total_duration_sec = params.get("total_duration_sec", 
    IgnoreRngUtils.randf_range(rng, 3.5, 4.5))
```

---

## Verification Test Results

**Test:** 10 instantiations with randomized durations

```
Duration Statistics from 10 runs:
  Min: 3.57s
  Max: 4.48s
  Avg: 3.95s

✓ Min duration >= 3.5s
✓ Max duration <= 5.0s (hard cap)
✓ Max duration <= 4.5s (target range)
✓ Avg duration ~4.0s (target)

=== DURATION TEST PASSED ===
```

---

## Breakdown

### Phase Timing

The microgame consists of multiple phases within the total duration:

1. **INTRO Phase** (0.0 - 0.3s)
   - Input is ignored
   - Setup and initial display

2. **ADVICE_ACTIVE Phase** (0.3s - deadline)
   - Advice deadline: 1.8-2.2s (randomized)
   - Input is accepted
   - Player must interrupt before deadline for SUCCESS

3. **RESOLVE Phase** (deadline - end)
   - Animation and feedback
   - Remaining time until total duration

### Example Timing Scenarios

**Scenario 1: Fast Game**
- Total duration: 3.5s
- Advice deadline: 1.8s
- Player window: 1.5s to respond (0.3s - 1.8s)
- Resolve time: 1.7s (1.8s - 3.5s)

**Scenario 2: Average Game**
- Total duration: 4.0s
- Advice deadline: 2.0s
- Player window: 1.7s to respond
- Resolve time: 2.0s

**Scenario 3: Slow Game**
- Total duration: 4.5s
- Advice deadline: 2.2s
- Player window: 1.9s to respond
- Resolve time: 2.3s

---

## Status

✅ **SPECIFICATION MET AND VERIFIED**

- Duration properly randomized between 3.5-4.5s
- Average duration ~4.0s
- Hard cap at 5.0s enforced
- No compilation errors
- No linter warnings
- Test suite passes

**The microgame meets all duration requirements!**
