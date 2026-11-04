extends RefCounted
class_name SaveGameSystem

const SAVE_PATH: String = "user://last_signal_save.cfg"
const SAVE_VERSION: int = 1


func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game(
	player_position: Vector2,
	life_support: LifeSupport,
	power_management: PowerManagement,
	crew_data_log_system: CrewDataLogSystem,
	objective_system: ObjectiveSystem,
	opening_tutorial_dismissed: bool,
	communications_transmission_discovered: bool,
	navigation_flight_record_discovered: bool,
	security_incident_record_discovered: bool,
	command_bridge_evidence_discovered: bool,
	ending_id: String
) -> bool:
	var config := ConfigFile.new()
	config.set_value("save", "version", SAVE_VERSION)
	config.set_value("save", "player_position", player_position)
	config.set_value("save", "oxygen", life_support.get_oxygen_level())
	config.set_value("save", "discovered_log_ids", crew_data_log_system.get_discovered_log_ids())
	config.set_value("save", "objectives", objective_system.get_save_data())
	config.set_value("save", "opening_tutorial_dismissed", opening_tutorial_dismissed)
	config.set_value(
		"save",
		"communications_transmission_discovered",
		communications_transmission_discovered
	)
	config.set_value(
		"save",
		"navigation_flight_record_discovered",
		navigation_flight_record_discovered
	)
	config.set_value(
		"save",
		"security_incident_record_discovered",
		security_incident_record_discovered
	)
	config.set_value(
		"save",
		"command_bridge_evidence_discovered",
		command_bridge_evidence_discovered
	)
	config.set_value("save", "ending_id", ending_id)
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


func load_game(
	crew_data_log_system: CrewDataLogSystem,
	objective_system: ObjectiveSystem
) -> Dictionary:
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

	var objective_state: Dictionary = {}
	var objective_state_variant: Variant = config.get_value("save", "objectives", null)
	if objective_state_variant != null:
		if typeof(objective_state_variant) == TYPE_DICTIONARY:
			objective_state = _validate_objective_state(objective_state_variant, objective_system)
		else:
			push_warning("SaveGameSystem: Objective state was malformed; starting objectives anew.")
	else:
		push_warning("SaveGameSystem: Save has no objective state; starting objectives anew.")

	var tutorial_dismissed_variant: Variant = config.get_value(
		"save",
		"opening_tutorial_dismissed",
		null
	)
	var tutorial_dismissed: bool = player_position.x >= -80.0
	if typeof(tutorial_dismissed_variant) == TYPE_BOOL:
		tutorial_dismissed = tutorial_dismissed_variant
	else:
		var completed_objective_ids: Array = objective_state.get("completed_ids", [])
		if completed_objective_ids.has("investigate_ship"):
			tutorial_dismissed = true

	var communications_discovered_variant: Variant = config.get_value(
		"save",
		"communications_transmission_discovered",
		null
	)
	var communications_discovered: bool = false
	if typeof(communications_discovered_variant) == TYPE_BOOL:
		communications_discovered = communications_discovered_variant
	elif not config.has_section_key("save", "communications_transmission_discovered"):
		var completed_objective_ids: Array = objective_state.get("completed_ids", [])
		communications_discovered = completed_objective_ids.has("investigate_communications")
	elif config.has_section_key("save", "communications_transmission_discovered"):
		push_warning(
			"SaveGameSystem: Communications discovery flag was malformed; using undiscovered state."
		)

	var navigation_discovered := _load_optional_discovery_flag(
		config,
		"navigation_flight_record_discovered"
	)
	var security_discovered := _load_optional_discovery_flag(
		config,
		"security_incident_record_discovered"
	)
	var command_bridge_discovered := _load_optional_discovery_flag(
		config,
		"command_bridge_evidence_discovered"
	)
	var ending_id_variant: Variant = config.get_value("save", "ending_id", "")
	var ending_id: String = ""
	if typeof(ending_id_variant) == TYPE_STRING:
		if ending_id_variant in ["response", "silence"]:
			ending_id = ending_id_variant
		elif not ending_id_variant.is_empty():
			push_warning("SaveGameSystem: Unknown ending id; ignoring saved ending.")
	else:
		push_warning("SaveGameSystem: Malformed ending id; ignoring saved ending.")
	if not ending_id.is_empty():
		command_bridge_discovered = true

	return {
		"player_position": player_position,
		"oxygen": clampf(float(oxygen), 0.0, 100.0),
		"power_allocations": power_allocations,
		"discovered_log_ids": known_log_ids,
		"objective_state": objective_state,
		"opening_tutorial_dismissed": tutorial_dismissed,
		"communications_transmission_discovered": communications_discovered,
		"navigation_flight_record_discovered": navigation_discovered,
		"security_incident_record_discovered": security_discovered,
		"command_bridge_evidence_discovered": command_bridge_discovered,
		"ending_id": ending_id,
	}


func _load_optional_discovery_flag(config: ConfigFile, key: String) -> bool:
	var value: Variant = config.get_value("save", key, false)
	if typeof(value) == TYPE_BOOL:
		return value
	if config.has_section_key("save", key):
		push_warning(
			"SaveGameSystem: '%s' was malformed; using undiscovered state." % key
		)
	return false


func clear_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return true
	var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	if remove_error != OK:
		push_error("SaveGameSystem: Could not remove save file for a new game (error %d)." % remove_error)
		return false
	return true


func _validate_objective_state(
	state: Dictionary,
	objective_system: ObjectiveSystem
) -> Dictionary:
	var completed_ids: Variant = state.get("completed_ids", [])
	var current_id: Variant = state.get("current_id", "")
	if typeof(completed_ids) != TYPE_ARRAY:
		push_warning("SaveGameSystem: Completed objective list was malformed; starting objectives anew.")
		return {}
	if typeof(current_id) != TYPE_STRING:
		push_warning("SaveGameSystem: Current objective id was malformed; deriving it from progress.")
		current_id = ""
	elif current_id != "" and not objective_system.is_known_objective_id(current_id):
		push_warning("SaveGameSystem: Unknown current objective id; deriving it from progress.")
		current_id = ""

	var known_completed_ids: Array[String] = []
	for objective_id: Variant in completed_ids:
		if typeof(objective_id) == TYPE_STRING and objective_system.is_known_objective_id(objective_id):
			if not known_completed_ids.has(objective_id):
				known_completed_ids.append(objective_id)

	var schema_version_variant: Variant = state.get("schema_version", 1)
	var schema_version: int = 1
	if typeof(schema_version_variant) == TYPE_INT and schema_version_variant >= 1:
		schema_version = schema_version_variant
	else:
		push_warning("SaveGameSystem: Objective schema version was invalid; using legacy migration.")

	return {
		"schema_version": schema_version,
		"current_id": current_id,
		"completed_ids": known_completed_ids,
	}
