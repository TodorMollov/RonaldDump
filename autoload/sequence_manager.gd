extends Node
## SequenceManager - Weighted random microgame selection with cooldown
## Cooldown window = last 3 games, no immediate repetition

const COOLDOWN_WINDOW_SIZE: int = 3

var registry = null
var recent_history: Array[String] = []  # Last N microgame IDs
var last_played_id: String = ""


func _ready() -> void:
	pass


func initialize(p_registry) -> void:
	registry = p_registry
	recent_history.clear()
	last_played_id = ""


func select_next_microgame():
	if not registry or registry.entries.size() == 0:
		push_error("SequenceManager: No microgames registered")
		return null
	
	# If only one microgame, return it
	if registry.entries.size() == 1:
		var entry = registry.entries[0]
		_record_selection(entry.id)
		return entry
	
	# Build weighted pool excluding cooldown entries
	var available_entries: Array = []
	var total_weight: int = 0
	
	for entry in registry.entries:
		# Skip if in cooldown window
		if entry.id in recent_history:
			continue
		
		# Skip if was last played (no immediate repetition)
		if entry.id == last_played_id:
			continue
		
		available_entries.append(entry)
		total_weight += entry.weight
	
	# Fallback: if all are in cooldown, allow last played to be excluded only
	if available_entries.size() == 0:
		available_entries.clear()
		total_weight = 0
		for entry in registry.entries:
			if entry.id != last_played_id:
				available_entries.append(entry)
				total_weight += entry.weight
	
	# Final fallback: if still empty, just use all
	if available_entries.size() == 0:
		available_entries = registry.entries.duplicate()
		total_weight = registry.get_total_weight()
	
	# Weighted random selection
	var roll = randi() % total_weight
	var cumulative = 0
	
	for entry in available_entries:
		cumulative += entry.weight
		if roll < cumulative:
			_record_selection(entry.id)
			return entry
	
	# Should never reach here, but return first as fallback
	var selected = available_entries[0]
	_record_selection(selected.id)
	return selected


func _record_selection(id: String) -> void:
	last_played_id = id
	
	# Add to history
	recent_history.append(id)
	
	# Maintain cooldown window size
	while recent_history.size() > COOLDOWN_WINDOW_SIZE:
		recent_history.pop_front()


func reset() -> void:
	recent_history.clear()
	last_played_id = ""


func get_history() -> Array[String]:
	return recent_history.duplicate()
