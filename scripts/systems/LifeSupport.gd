extends RefCounted
class_name LifeSupport

signal oxygen_changed(new_oxygen_level: float)

const MINIMUM_STABLE_ALLOCATION: int = 35
const OXYGEN_DEPLETION_RATE: float = 1.0
const LIFE_SUPPORT_SYSTEM_NAME: String = "Life Support"

var _power_management: PowerManagement
var _oxygen_level: float = 100.0


func _init(power_management: PowerManagement) -> void:
	_power_management = power_management


func get_oxygen_level() -> float:
	return _oxygen_level


func update(delta: float) -> void:
	if delta <= 0.0:
		return

	var allocation := _power_management.get_system_allocated_power(LIFE_SUPPORT_SYSTEM_NAME)
	if allocation >= MINIMUM_STABLE_ALLOCATION:
		return

	var new_oxygen_level := maxf(0.0, _oxygen_level - OXYGEN_DEPLETION_RATE * delta)
	if is_equal_approx(new_oxygen_level, _oxygen_level):
		return

	_oxygen_level = new_oxygen_level
	oxygen_changed.emit(_oxygen_level)
