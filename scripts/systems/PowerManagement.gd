extends RefCounted
class_name PowerManagement

# Reusable power allocation state with no scene or UI dependencies.
signal allocation_changed(system_name: String, previous_allocation: int, new_allocation: int)

const TOTAL_AVAILABLE_POWER: int = 100

const LIFE_SUPPORT: String = "Life Support"
const NAVIGATION: String = "Navigation"
const SECURITY: String = "Security"
const COMMUNICATIONS: String = "Communications"

const SYSTEM_NAMES: Array[String] = [
	LIFE_SUPPORT,
	NAVIGATION,
	SECURITY,
	COMMUNICATIONS,
]

const INITIAL_ALLOCATIONS: Dictionary = {
	"Life Support": 35,
	"Navigation": 25,
	"Security": 20,
	"Communications": 20,
}

var _allocations: Dictionary


func _init() -> void:
	_allocations = INITIAL_ALLOCATIONS.duplicate()


func get_available_power() -> int:
	return TOTAL_AVAILABLE_POWER - get_total_allocated_power()


func get_system_allocated_power(system_name: String) -> int:
	if not _allocations.has(system_name):
		push_warning("PowerManagement: Unknown system name '%s'." % system_name)
		# A negative result distinguishes an invalid name from a valid zero allocation.
		return -1

	return _allocations[system_name]


func set_system_allocation(system_name: String, allocation: int) -> bool:
	if not _allocations.has(system_name):
		push_warning("PowerManagement: Cannot allocate power to unknown system '%s'." % system_name)
		return false
	if allocation < 0:
		push_warning("PowerManagement: Allocation for '%s' cannot be negative." % system_name)
		return false

	var current_allocation: int = _allocations[system_name]
	var total_without_system: int = get_total_allocated_power() - current_allocation
	if total_without_system + allocation > TOTAL_AVAILABLE_POWER:
		push_warning("PowerManagement: Allocation for '%s' exceeds available ship power." % system_name)
		return false

	# A no-op is valid, but doesn't emit a change signal.
	if allocation == current_allocation:
		return true

	_allocations[system_name] = allocation
	allocation_changed.emit(system_name, current_allocation, allocation)
	return true


func get_total_allocated_power() -> int:
	var total: int = 0
	for allocation: int in _allocations.values():
		total += allocation
	return total


func are_allocations_valid() -> bool:
	if _allocations.size() != SYSTEM_NAMES.size():
		return false

	var total: int = 0
	for system_name: String in SYSTEM_NAMES:
		if not _allocations.has(system_name):
			return false

		var allocation: int = _allocations[system_name]
		if allocation < 0:
			return false
		total += allocation

	return total <= TOTAL_AVAILABLE_POWER
