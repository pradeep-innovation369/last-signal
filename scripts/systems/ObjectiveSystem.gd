extends RefCounted
class_name ObjectiveSystem

signal objective_changed(objective_id: String, title: String, description: String)
signal objective_completed(title: String, next_title: String)

const OBJECTIVES: Array[Dictionary] = [
	{
		"id": "investigate_ship",
		"title": "Reach Main Corridor",
		"description": "Leave the Cryo Chamber and enter the Main Corridor.",
	},
	{
		"id": "reach_engineering",
		"title": "Reach Engineering",
		"description": "Cross the Main Corridor and locate the Power Console.",
	},
	{
		"id": "restore_life_support",
		"title": "Restore Life Support",
		"description": "At the Power Console, manually allocate at least 35 of 100 power units to Life Support.",
	},
	{
		"id": "investigate_communications",
		"title": "Investigate Communications",
		"description": "Read the transmission, then close the console.",
	},
	{
		"id": "investigate_navigation",
		"title": "Investigate Navigation",
		"description": "Access the flight record, then close the Navigation Console.",
	},
	{
		"id": "access_security",
		"title": "Access Security Console",
		"description": "Access the incident record, then close the Security Console.",
	},
	{
		"id": "review_crew_logs",
		"title": "Review Crew Data Logs",
		"description": "Recover all three crew logs around the ship.",
	},
	{
		"id": "reach_command_bridge",
		"title": "Reach Command Bridge",
		"description": "Bring the evidence together and investigate the ship's final command records.",
	},
]

var _completed_objective_ids: Array[String] = []
var _current_objective_index: int = 0


func get_current_objective_id() -> String:
	if _current_objective_index >= OBJECTIVES.size():
		return ""
	return OBJECTIVES[_current_objective_index]["id"]


func get_current_objective() -> Dictionary:
	if _current_objective_index >= OBJECTIVES.size():
		return {}
	return OBJECTIVES[_current_objective_index].duplicate(true)


func get_completed_objective_ids() -> Array[String]:
	return _completed_objective_ids.duplicate()


func is_known_objective_id(objective_id: String) -> bool:
	for objective: Dictionary in OBJECTIVES:
		if objective["id"] == objective_id:
			return true
	return false


func complete_current_objective(objective_id: String) -> bool:
	if objective_id != get_current_objective_id():
		return false
	if _completed_objective_ids.has(objective_id):
		return false

	var completed_objective: Dictionary = OBJECTIVES[_current_objective_index]
	_completed_objective_ids.append(objective_id)
	_current_objective_index += 1

	var next_objective := get_current_objective()
	var next_title: String = next_objective.get("title", "MISSION OBJECTIVES COMPLETE")
	objective_completed.emit(completed_objective["title"], next_title)
	_emit_current_objective()
	return true


func get_save_data() -> Dictionary:
	return {
		"schema_version": 4,
		"current_id": get_current_objective_id(),
		"completed_ids": get_completed_objective_ids(),
	}


func restore_state(state: Dictionary) -> void:
	var completed_variant: Variant = state.get("completed_ids", [])
	var current_variant: Variant = state.get("current_id", "")
	var state_version_variant: Variant = state.get("schema_version", 1)
	var state_version: int = 1
	if typeof(state_version_variant) == TYPE_INT:
		state_version = state_version_variant
	if typeof(completed_variant) != TYPE_ARRAY:
		push_warning("ObjectiveSystem: Invalid completed objective list; starting objectives anew.")
		_reset_progress()
		return
	if typeof(current_variant) != TYPE_STRING:
		push_warning("ObjectiveSystem: Invalid current objective id; deriving it from completed objectives.")
		current_variant = ""
	elif current_variant != "" and not is_known_objective_id(current_variant):
		push_warning("ObjectiveSystem: Unknown current objective id; deriving it from completed objectives.")
		current_variant = ""

	var saved_completed_ids: Array[String] = []
	for objective_id: Variant in completed_variant:
		if typeof(objective_id) == TYPE_STRING and is_known_objective_id(objective_id):
			if not saved_completed_ids.has(objective_id):
				saved_completed_ids.append(objective_id)

	if state_version < 2 and saved_completed_ids.has("investigate_ship"):
		saved_completed_ids.append("reach_engineering")

	_completed_objective_ids.clear()
	_current_objective_index = 0
	for objective: Dictionary in OBJECTIVES:
		var objective_id: String = objective["id"]
		if not saved_completed_ids.has(objective_id):
			break
		_completed_objective_ids.append(objective_id)
		_current_objective_index += 1

	var derived_current_id := get_current_objective_id()
	if current_variant != "" and current_variant != derived_current_id:
		push_warning("ObjectiveSystem: Current objective did not match progress; using ordered progress.")
	_emit_current_objective()


func _reset_progress() -> void:
	_completed_objective_ids.clear()
	_current_objective_index = 0
	_emit_current_objective()


func _emit_current_objective() -> void:
	var objective := get_current_objective()
	objective_changed.emit(
		str(objective.get("id", "")),
		str(objective.get("title", "MISSION OBJECTIVES COMPLETE")),
		str(objective.get("description", "All current mission objectives are complete."))
	)
