extends Resource
class_name MicrogameRegistry
## Resource-based registry for all microgames

class MicrogameEntry:
	var id: String
	var scene_path: String
	var weight: int = 1
	var display_name: String = ""
	
	func _init(p_id: String, p_scene_path: String, p_weight: int = 1, p_display_name: String = ""):
		id = p_id
		scene_path = p_scene_path
		weight = p_weight
		display_name = p_display_name if p_display_name != "" else p_id

var entries: Array[MicrogameEntry] = []


func register_microgame(id: String, scene_path: String, weight: int = 1, display_name: String = "") -> void:
	var entry = MicrogameEntry.new(id, scene_path, weight, display_name)
	entries.append(entry)


func get_all_entries() -> Array[MicrogameEntry]:
	return entries


func get_entry_by_id(id: String) -> MicrogameEntry:
	for entry in entries:
		if entry.id == id:
			return entry
	return null


func get_total_weight() -> int:
	var total = 0
	for entry in entries:
		total += entry.weight
	return total


func clear() -> void:
	entries.clear()
