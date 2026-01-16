extends Node
class_name IgnoreRngUtils
## Deterministic RNG utilities for Ignore The Expert microgame


static func seeded_rng(seed_value: int) -> RandomNumberGenerator:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


static func randf_range(rng: RandomNumberGenerator, a: float, b: float) -> float:
	return rng.randf_range(a, b)


static func randi_range(rng: RandomNumberGenerator, a: int, b: int) -> int:
	return rng.randi_range(a, b)
