extends Node
## Autoload registry for microgames

const MicrogameDefScript = preload("res://framework/data/MicrogameDef.gd")

var entries: Array = []
var _test_defs: Array = []  ## Test-only override for injecting test microgames


func clear() -> void:
	entries.clear()
	_test_defs.clear()


func register_entry(entry) -> void:
	if entry == null:
		return
	entries.append(entry)


func register_microgame(id: String, scene_path: String, weight: float = 1.0, enabled: bool = true) -> void:
	var entry := MicrogameDefScript.new()
	entry.id = id
	entry.scene_path = scene_path
	entry.weight = weight
	entry.enabled = enabled
	register_entry(entry)


func get_entries() -> Array:
	return entries


func get_enabled_entries() -> Array:
	var enabled_entries: Array = []
	for entry in entries:
		if entry.enabled:
			enabled_entries.append(entry)
	return enabled_entries


func get_entry_by_id(id: String):
	for entry in entries:
		if entry.id == id:
			return entry
	return null


func get_total_weight(entries_list: Array) -> float:
	var total := 0.0
	for entry in entries_list:
		total += entry.weight
	return total

## TEST-ONLY: Inject microgame defs for tests without shipping them in production registry.
## This allows tests to register TestMicrogame without it appearing in production builds.
## IMPORTANT: This must be called in test setup, never in production code.
func set_defs_for_tests(defs: Array) -> void:
	_test_defs = defs.duplicate(true)
	entries = _test_defs


## Get entries, preferring test-injected defs if set, otherwise production entries.
func get_entries_for_selection() -> Array:
	# If test defs are set, use those exclusively
	if not _test_defs.is_empty():
		return _test_defs
	return entries