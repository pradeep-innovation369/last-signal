extends CanvasLayer
class_name HUDController

signal power_console_closed
signal crew_data_log_opened
signal save_game_requested
signal restart_requested
signal communications_transmission_discovered
signal navigation_flight_record_discovered
signal security_incident_record_discovered
signal command_bridge_evidence_discovered
signal command_bridge_ending_confirmed(ending_id: String)
signal return_to_title_requested
signal new_game_requested

@onready var interaction_hint: Label = $Root/InteractionHint
@onready var message_frame: ColorRect = $Root/MessageFrame
@onready var message_panel: ColorRect = $Root/MessagePanel
@onready var message_label: Label = $Root/MessageLabel
@onready var power_console: PowerConsoleController = $PowerConsolePanel
@onready var communications_console: CommunicationsConsoleController = $CommunicationsConsolePanel
@onready var navigation_console: NavigationConsoleController = $NavigationConsolePanel
@onready var security_console: SecurityConsoleController = $SecurityConsolePanel
@onready var crew_data_log_panel: CrewDataLogController = $CrewDataLogPanel
@onready var command_bridge_panel: CommandBridgeController = $CommandBridgePanel
@onready var log_archive_button: Button = $Root/LogArchiveButton
@onready var save_game_button: Button = $Root/SaveGameButton
@onready var objective_title: Label = $Root/ObjectiveTitle
@onready var objective_description: Label = $Root/ObjectiveDescription
@onready var opening_tutorial_frame: ColorRect = $Root/OpeningTutorialFrame
@onready var opening_tutorial_panel: ColorRect = $Root/OpeningTutorialPanel
@onready var opening_tutorial_label: Label = $Root/OpeningTutorialLabel
@onready var oxygen_value: Label = $Root/OxygenValue
@onready var oxygen_bar: ProgressBar = $Root/OxygenBar
@onready var ship_minimap: ShipMinimap = $Root/ShipMinimap
@onready var game_over_overlay: Control = $GameOverOverlay
@onready var restart_button: Button = $GameOverOverlay/GameOverPanel/RestartButton

var _life_support: LifeSupport
var _power_management: PowerManagement
var _crew_data_log_system: CrewDataLogSystem
var _objective_system: ObjectiveSystem


func _ready() -> void:
	power_console.closed.connect(_on_power_console_closed)
	communications_console.closed.connect(_on_power_console_closed)
	communications_console.transmission_discovered.connect(
		_on_communications_transmission_discovered
	)
	navigation_console.flight_record_discovered.connect(
		_on_navigation_flight_record_discovered
	)
	security_console.incident_record_discovered.connect(
		_on_security_incident_record_discovered
	)
	command_bridge_panel.closed.connect(_on_power_console_closed)
	command_bridge_panel.evidence_discovered.connect(_on_command_bridge_evidence_discovered)
	command_bridge_panel.ending_confirmed.connect(_on_command_bridge_ending_confirmed)
	command_bridge_panel.return_to_title_requested.connect(_on_return_to_title_requested)
	command_bridge_panel.new_game_requested.connect(_on_new_game_requested)
	navigation_console.closed.connect(_on_power_console_closed)
	security_console.closed.connect(_on_power_console_closed)
	crew_data_log_panel.closed.connect(_on_power_console_closed)
	crew_data_log_panel.opened.connect(_on_crew_data_log_panel_opened)
	log_archive_button.pressed.connect(_on_log_archive_button_pressed)
	save_game_button.pressed.connect(_on_save_game_button_pressed)
	restart_button.pressed.connect(_on_restart_button_pressed)
	log_archive_button.add_theme_color_override("font_color", Color(0.84, 0.91, 0.92, 1.0))
	log_archive_button.add_theme_font_size_override("font_size", 8)
	log_archive_button.add_theme_stylebox_override(
		"normal",
		_make_button_style(Color(0.025, 0.043, 0.060, 0.95))
	)
	log_archive_button.add_theme_stylebox_override(
		"hover",
		_make_button_style(Color(0.075, 0.14, 0.16, 1.0))
	)
	save_game_button.add_theme_color_override("font_color", Color(0.84, 0.91, 0.92, 1.0))
	save_game_button.add_theme_font_size_override("font_size", 7)
	save_game_button.add_theme_stylebox_override(
		"normal",
		_make_button_style(Color(0.025, 0.043, 0.060, 0.95))
	)
	save_game_button.add_theme_stylebox_override(
		"hover",
		_make_button_style(Color(0.075, 0.14, 0.16, 1.0))
	)
	save_game_button.add_theme_stylebox_override(
		"pressed",
		_make_button_style(Color(0.055, 0.10, 0.12, 1.0))
	)
	restart_button.add_theme_color_override("font_color", Color(0.84, 0.91, 0.92, 1.0))
	restart_button.add_theme_font_size_override("font_size", 8)
	restart_button.add_theme_stylebox_override(
		"normal",
		_make_button_style(Color(0.025, 0.043, 0.060, 0.95))
	)
	restart_button.add_theme_stylebox_override(
		"hover",
		_make_button_style(Color(0.075, 0.14, 0.16, 1.0))
	)
	oxygen_bar.max_value = 100.0
	oxygen_bar.add_theme_stylebox_override("background", _make_oxygen_style(Color(0.07, 0.13, 0.16, 1.0)))
	oxygen_bar.add_theme_stylebox_override("fill", _make_oxygen_style(Color(0.28, 0.79, 0.84, 1.0)))


func set_life_support(life_support: LifeSupport, power_management: PowerManagement) -> void:
	_life_support = life_support
	_power_management = power_management
	if not _life_support.oxygen_changed.is_connected(_on_oxygen_changed):
		_life_support.oxygen_changed.connect(_on_oxygen_changed)
	if not _power_management.allocation_changed.is_connected(_on_power_allocation_changed):
		_power_management.allocation_changed.connect(_on_power_allocation_changed)
	_update_oxygen_display(_life_support.get_oxygen_level())


func set_crew_data_log_system(log_system: CrewDataLogSystem) -> void:
	_crew_data_log_system = log_system


func set_objective_system(objective_system: ObjectiveSystem) -> void:
	_objective_system = objective_system
	if not _objective_system.objective_changed.is_connected(_on_objective_changed):
		_objective_system.objective_changed.connect(_on_objective_changed)
	if not _objective_system.objective_completed.is_connected(_on_objective_completed):
		_objective_system.objective_completed.connect(_on_objective_completed)
	var objective := _objective_system.get_current_objective()
	_update_objective_display(
		str(objective.get("title", "MISSION OBJECTIVES COMPLETE")),
		str(objective.get("description", "All current mission objectives are complete."))
	)


func set_player_position(world_position: Vector2) -> void:
	ship_minimap.set_player_position(world_position)


func set_interaction_hint(hint: String) -> void:
	interaction_hint.text = hint
	interaction_hint.visible = not hint.is_empty()


func show_opening_tutorial(instruction: String) -> void:
	opening_tutorial_label.text = instruction
	opening_tutorial_frame.visible = true
	opening_tutorial_panel.visible = true
	opening_tutorial_label.visible = true


func dismiss_opening_tutorial() -> void:
	opening_tutorial_frame.visible = false
	opening_tutorial_panel.visible = false
	opening_tutorial_label.visible = false


func clear_interaction_hint() -> void:
	interaction_hint.text = ""
	interaction_hint.visible = false


func show_game_over() -> void:
	clear_interaction_hint()
	save_game_button.disabled = true
	log_archive_button.disabled = true
	game_over_overlay.visible = true


func show_message(message: String) -> void:
	message_label.text = message
	message_label.visible = true
	message_frame.visible = true
	message_panel.visible = true


func clear_message() -> void:
	message_label.visible = false
	message_frame.visible = false
	message_panel.visible = false


func open_power_console(power_management: PowerManagement, status_message: String) -> void:
	power_console.open(power_management, status_message)


func close_power_console() -> void:
	power_console.close()


func open_communications_console(
	power_management: PowerManagement,
	transmission_discovered: bool
) -> void:
	communications_console.open(power_management, transmission_discovered)


func close_communications_console() -> void:
	communications_console.close()


func open_navigation_console(
	power_management: PowerManagement,
	flight_record_discovered: bool
) -> void:
	navigation_console.open(power_management, flight_record_discovered)


func close_navigation_console() -> void:
	navigation_console.close()


func open_security_console(
	power_management: PowerManagement,
	incident_record_discovered: bool
) -> void:
	security_console.open(power_management, incident_record_discovered)


func close_security_console() -> void:
	security_console.close()


func open_command_bridge(evidence_discovered: bool) -> void:
	command_bridge_panel.open(evidence_discovered)


func close_command_bridge() -> void:
	command_bridge_panel.close()


func show_ending(ending_id: String) -> void:
	command_bridge_panel.show_ending(ending_id)


func open_crew_data_log(log_system: CrewDataLogSystem, log_id: String) -> void:
	_crew_data_log_system = log_system
	crew_data_log_panel.open_log(log_system, log_id)


func open_crew_data_log_archive(log_system: CrewDataLogSystem) -> void:
	_crew_data_log_system = log_system
	crew_data_log_panel.open_archive(log_system)


func close_crew_data_log() -> void:
	crew_data_log_panel.close()


func show_save_result(succeeded: bool) -> void:
	var result_message := "GAME SAVED" if succeeded else "SAVE FAILED"
	show_message(result_message)
	await get_tree().create_timer(2.0).timeout
	if message_label.text == result_message:
		clear_message()


func is_power_console_open() -> bool:
	return power_console.visible


func is_any_console_open() -> bool:
	return (
		power_console.visible
		or communications_console.visible
		or navigation_console.visible
		or security_console.visible
		or command_bridge_panel.visible
		or crew_data_log_panel.visible
	)


func close_open_console() -> void:
	if power_console.visible:
		power_console.close()
	elif communications_console.visible:
		communications_console.close()
	elif navigation_console.visible:
		navigation_console.close()
	elif security_console.visible:
		security_console.close()
	elif command_bridge_panel.visible:
		command_bridge_panel.close()
	elif crew_data_log_panel.visible:
		crew_data_log_panel.close()


func _on_log_archive_button_pressed() -> void:
	if _crew_data_log_system == null:
		push_error("HUDController: Crew data log system has not been initialized.")
		return

	open_crew_data_log_archive(_crew_data_log_system)


func _on_save_game_button_pressed() -> void:
	save_game_requested.emit()


func _on_communications_transmission_discovered() -> void:
	communications_transmission_discovered.emit()


func _on_navigation_flight_record_discovered() -> void:
	navigation_flight_record_discovered.emit()


func _on_security_incident_record_discovered() -> void:
	security_incident_record_discovered.emit()


func _on_command_bridge_evidence_discovered() -> void:
	command_bridge_evidence_discovered.emit()


func _on_command_bridge_ending_confirmed(ending_id: String) -> void:
	command_bridge_ending_confirmed.emit(ending_id)


func _on_return_to_title_requested() -> void:
	return_to_title_requested.emit()


func _on_new_game_requested() -> void:
	new_game_requested.emit()


func _on_restart_button_pressed() -> void:
	restart_requested.emit()


func _on_objective_changed(_objective_id: String, title: String, description: String) -> void:
	_update_objective_display(title, description)


func _on_objective_completed(title: String, next_title: String) -> void:
	if title == "Restore Life Support":
		show_message("LIFE SUPPORT STABILIZED\nNEXT: %s" % next_title)
	else:
		show_message("OBJECTIVE COMPLETE: %s\nNEXT: %s" % [title, next_title])
	var completion_message := message_label.text
	await get_tree().create_timer(3.0).timeout
	if message_label.text == completion_message:
		clear_message()


func _update_objective_display(title: String, description: String) -> void:
	objective_title.text = "OBJECTIVE: %s" % title.to_upper()
	objective_description.text = description


func _on_crew_data_log_panel_opened() -> void:
	crew_data_log_opened.emit()


func _on_oxygen_changed(oxygen_level: float) -> void:
	_update_oxygen_display(oxygen_level)


func _on_power_allocation_changed(system_name: String, _previous_allocation: int, _new_allocation: int) -> void:
	if system_name == LifeSupport.LIFE_SUPPORT_SYSTEM_NAME and _life_support != null:
		_update_oxygen_display(_life_support.get_oxygen_level())


func _update_oxygen_display(oxygen_level: float) -> void:
	var clamped_oxygen := clampf(oxygen_level, 0.0, 100.0)
	oxygen_value.text = "%d%%" % roundi(clamped_oxygen)
	oxygen_bar.value = clamped_oxygen

	var is_depleting := (
		_power_management.get_system_allocated_power(LifeSupport.LIFE_SUPPORT_SYSTEM_NAME)
		< LifeSupport.MINIMUM_STABLE_ALLOCATION
	)
	var indicator_color := Color(0.96, 0.57, 0.32, 1.0) if is_depleting or clamped_oxygen <= 25.0 else Color(0.36, 0.85, 0.88, 1.0)
	oxygen_value.add_theme_color_override("font_color", indicator_color)
	oxygen_bar.add_theme_stylebox_override("fill", _make_oxygen_style(indicator_color))


func _on_power_console_closed() -> void:
	power_console_closed.emit()


func _make_oxygen_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(1)
	return style


func _make_button_style(background: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = Color(0.14, 0.25, 0.29, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 3.0
	style.content_margin_right = 3.0
	return style
