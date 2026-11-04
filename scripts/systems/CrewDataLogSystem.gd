extends RefCounted
class_name CrewDataLogSystem

signal log_discovered(log_id: String)

const LOG_ENTRIES: Dictionary = {
	"cryo_observation": {
		"id": "cryo_observation",
		"title": "Before First Light",
		"author": "Dr. Mara Venn",
		"location": "Cryo Chamber",
		"text": (
			"I volunteered for the first watch after revival. The sleepers all look peaceful, "
			+ "but one pod keeps fogging from the inside. I asked Engineering to check its seal. "
			+ "They say the readout is clean. I still hear someone counting between the cooling cycles."
		),
	},
	"corridor_event": {
		"id": "corridor_event",
		"title": "A Sound Between Decks",
		"author": "Tomas Rhee, Deck Crew",
		"location": "Main Corridor",
		"text": (
			"At 03:17 the corridor lights dipped for exactly eleven seconds. There was a knock "
			+ "under the deck plates, then three more from farther down the hall. The ship log "
			+ "shows no pressure change and no one on the maintenance level. I have stopped "
			+ "walking this passage alone."
		),
	},
	"engineering_failure": {
		"id": "engineering_failure",
		"title": "Unassigned Load",
		"author": "Chief Engineer Imani Okafor",
		"location": "Engineering",
		"text": (
			"Three systems reported simultaneous faults, but the power ledger shows no spike. "
			+ "A reserve bus drew current while physically isolated; the trace lasted eleven "
			+ "seconds and ended before I could route a diagnostic. This is not a hardware fault. "
			+ "I am logging it here because the official report keeps losing this paragraph."
		),
	},
}

const REQUIRED_LOG_IDS: Array[String] = [
	"cryo_observation",
	"corridor_event",
	"engineering_failure",
]

var _discovered_log_ids: Array[String] = []


func has_log(log_id: String) -> bool:
	return LOG_ENTRIES.has(log_id)


func is_discovered(log_id: String) -> bool:
	return _discovered_log_ids.has(log_id)


func discover_log(log_id: String) -> bool:
	if not has_log(log_id):
		push_warning("CrewDataLogSystem: Unknown log id '%s'." % log_id)
		return false
	if is_discovered(log_id):
		return false

	_discovered_log_ids.append(log_id)
	log_discovered.emit(log_id)
	return true


func get_log(log_id: String) -> Dictionary:
	if not has_log(log_id):
		push_warning("CrewDataLogSystem: Unknown log id '%s'." % log_id)
		return {}

	return LOG_ENTRIES[log_id].duplicate(true)


func get_discovered_logs() -> Array[Dictionary]:
	var discovered_logs: Array[Dictionary] = []
	for log_id: String in _discovered_log_ids:
		discovered_logs.append(LOG_ENTRIES[log_id].duplicate(true))
	return discovered_logs


func get_discovered_log_ids() -> Array[String]:
	return _discovered_log_ids.duplicate()


func are_all_logs_discovered() -> bool:
	for log_id: String in REQUIRED_LOG_IDS:
		if not _discovered_log_ids.has(log_id):
			return false
	return true


func restore_discovered_logs(log_ids: Array) -> void:
	for log_id: Variant in log_ids:
		if typeof(log_id) == TYPE_STRING and has_log(log_id):
			discover_log(log_id)
