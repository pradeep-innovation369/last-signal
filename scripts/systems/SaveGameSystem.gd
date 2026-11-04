extends RefCounted
class_name SaveGameSystem

const SAVE_PATH: String = "user://last_signal_save.cfg"
const SAVE_VERSION: int = 1


func save_game(
	player_position: Vector2,
	life_support: LifeSupport,
	power_management: PowerManagement,
	crew_data_log_system: CrewDataLogSystem
) -> bool:
	var config := ConfigFile.new()
	config.set_value("save", "version", SAVE_VERSION)
	config.set_value("save", "player_position", player_position)
	config.set_value("save", "oxygen", life_support.get_oxygen_level())
	config.set_value("save", "discovered_log_ids", crew_data_log_system.get_discovered_log_ids())
	for system_name: String in PowerManagement.SYSTEM_NAMES:
		config.set_value(
			"power",
			system_name,
			power_management.get_system_allocated_power(system_name)
		)

	var save_error := config.save(SAVE_PATH)
	if save_error != OK:
		push_error("SaveGameSystem: Could not write save file (error %d)." % save_error)
		return false

	return true


func load_game(crew_data_log_system: CrewDataLogSystem) -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}

	var config := ConfigFile.new()
	var load_error := config.load(SAVE_PATH)
	if load_error != OK:
		push_warning("SaveGameSystem: Save file could not be read (error %d)." % load_error)
		return {}

	var version: Variant = config.get_value("save", "version", null)
	if typeof(version) != TYPE_INT or version != SAVE_VERSION:
		push_warning("SaveGameSystem: Save file has an unsupported or missing version.")
		return {}

	var player_position: Variant = config.get_value("save", "player_position", null)
	if typeof(player_position) != TYPE_VECTOR2:
		push_warning("SaveGameSystem: Save file has a malformed player position.")
		return {}
	if not is_finite(player_position.x) or not is_finite(player_position.y):
		push_warning("SaveGameSystem: Save file has a non-finite player position.")
		return {}

	var oxygen: Variant = config.get_value("save", "oxygen", null)
	if typeof(oxygen) != TYPE_INT and typeof(oxygen) != TYPE_FLOAT:
		push_warning("SaveGameSystem: Save file has a malformed oxygen value.")
		return {}
	if not is_finite(float(oxygen)):
		push_warning("SaveGameSystem: Save file has a non-finite oxygen value.")
		return {}

	var power_allocations: Dictionary = {}
	var total_allocation: int = 0
	for system_name: String in PowerManagement.SYSTEM_NAMES:
		var allocation: Variant = config.get_value("power", system_name, null)
		if typeof(allocation) != TYPE_INT or allocation < 0:
			push_warning("SaveGameSystem: Save file has a malformed '%s' allocation." % system_name)
			return {}
		power_allocations[system_name] = allocation
		total_allocation += allocation

	if total_allocation > PowerManagement.TOTAL_AVAILABLE_POWER:
		push_warning("SaveGameSystem: Save allocations exceed available ship power.")
		return {}

	var discovered_log_ids: Variant = config.get_value("save", "discovered_log_ids", null)
	if typeof(discovered_log_ids) != TYPE_ARRAY:
		push_warning("SaveGameSystem: Save file has a malformed discovered-log list.")
		return {}

	var known_log_ids: Array[String] = []
	for log_id: Variant in discovered_log_ids:
		if typeof(log_id) == TYPE_STRING and crew_data_log_system.has_log(log_id):
			if not known_log_ids.has(log_id):
				known_log_ids.append(log_id)

	return {
		"player_position": player_position,
		"oxygen": clampf(float(oxygen), 0.0, 100.0),
		"power_allocations": power_allocations,
		"discovered_log_ids": known_log_ids,
	}
