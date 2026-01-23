extends Node
## SequenceManager - Weighted random microgame selection with cooldown
## Cooldown window = last 3 games, no immediate repetition

const COOLDOWN_WINDOW_SIZE: int = 3

var registry = null
var recent_history: Array[String] = []  # Last N microgame IDs


func _ready() -> void:
	pass


func initialize(p_registry) -> void:
	registry = p_registry
	recent_history.clear()


func select_next_microgame():
	if not registry:
		return null
	
	var entries = registry.get_enabled_entries()
	if entries.size() == 0:
		# Empty registry is valid during production boot (no microgames registered yet)
		# Return null silently - RunManager will handle gracefully
		return null
	
	# If only one microgame, return it
	if entries.size() == 1:
		var entry = entries[0]
		_record_selection(entry.id)
		return entry
	
	# Build weighted pool excluding cooldown entries
	var available_entries: Array = []
	var total_weight: float = 0.0
	
	for entry in entries:
		# Skip if in cooldown window
		if entry.id in recent_history:
			continue
		if entry.weight <= 0.0:
			continue
		available_entries.append(entry)
		total_weight += float(entry.weight)
	
	# Fallback: if all are in cooldown, allow any enabled entries
	if available_entries.size() == 0:
		available_entries.clear()
		total_weight = 0.0
		for entry in entries:
			if entry.weight <= 0.0:
				continue
			available_entries.append(entry)
			total_weight += float(entry.weight)
	
	# Final fallback: if still empty, just use all
	if available_entries.size() == 0:
		available_entries = entries.duplicate()
		total_weight = registry.get_total_weight(entries)
	
	# Weighted random selection
	var roll = randf() * total_weight
	var cumulative = 0.0
	
	for entry in available_entries:
		cumulative += float(entry.weight)
		if roll <= cumulative:
			_record_selection(entry.id)
			return entry
	
	# Should never reach here, but return first as fallback
	var selected = available_entries[0]
	_record_selection(selected.id)
	return selected


func _record_selection(id: String) -> void:
	# Add to history
	recent_history.append(id)
	
	# Maintain cooldown window size
	while recent_history.size() > COOLDOWN_WINDOW_SIZE:
		recent_history.pop_front()


func reset() -> void:
	recent_history.clear()


func get_history() -> Array[String]:
	return recent_history.duplicate()
