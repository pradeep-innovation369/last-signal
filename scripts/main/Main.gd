extends Node2D

const POWER_CONSOLE_INTERACTION_DISTANCE: float = 32.0
const COMMUNICATIONS_CONSOLE_INTERACTION_DISTANCE: float = 32.0
const NAVIGATION_CONSOLE_INTERACTION_DISTANCE: float = 32.0
const SECURITY_CONSOLE_INTERACTION_DISTANCE: float = 32.0
const COMMAND_BRIDGE_INTERACTION_DISTANCE: float = 32.0
const SKIP_SAVE_RESTORE_META: String = "last_signal_skip_save_restore_once"
const OPENING_TUTORIAL_TEXT: String = (
	"LIFE SUPPORT UNSTABLE\n"
	+ "Oxygen levels are decreasing.\n"
	+ "Restore power to Life Support to stabilize oxygen."
)

@onready var power_console: Interactable = $WorldVisuals/DepthSort/PowerConsole
@onready var communications_console: Interactable = $WorldVisuals/DepthSort/CommunicationsConsole
@onready var navigation_console: Interactable = $WorldVisuals/DepthSort/NavigationConsole
@onready var security_console: Interactable = $WorldVisuals/DepthSort/SecurityConsole
@onready var command_bridge_terminal: Interactable = $WorldVisuals/DepthSort/CommandBridgeTerminal
@onready var crew_data_logs: Node2D = $WorldVisuals/DepthSort/CrewDataLogs
@onready var hud: HUDController = $HUD
@onready var player: PlayerController = $WorldVisuals/DepthSort/Player
@onready var player_camera: Camera2D = $WorldVisuals/DepthSort/Player/Camera2D
@onready var render_viewport: SubViewport = $WorldRenderViewport
@onready var ship_world: ShipWorld3D = $WorldRenderViewport/ShipWorld3D
@onready var world_texture: Sprite2D = $WorldRenderLayer/WorldTexture

var power_management: PowerManagement = PowerManagement.new()
var life_support: LifeSupport
var crew_data_log_system: CrewDataLogSystem = CrewDataLogSystem.new()
var objective_system: ObjectiveSystem = ObjectiveSystem.new()
var save_game_system: SaveGameSystem = SaveGameSystem.new()
var nearby_interactable: Interactable
var current_location: String = ""
var _pending_console_objective_id: String = ""
var _opening_instruction_dismissed: bool = false
var _is_game_over: bool = false
var _is_restoring_saved_game: bool = false
var _communications_transmission_discovered: bool = false
var _navigation_flight_record_discovered: bool = false
var _security_incident_record_discovered: bool = false
var _command_bridge_evidence_discovered: bool = false
var _ending_id: String = ""
var _is_ending: bool = false


func _ready() -> void:
	life_support = LifeSupport.new(power_management)
	world_texture.texture = render_viewport.get_texture()
	_sync_world_view(0.0)
	hud.set_life_support(life_support, power_management)
	hud.set_crew_data_log_system(crew_data_log_system)
	hud.set_objective_system(objective_system)
	objective_system.objective_changed.connect(_on_current_objective_changed)
	power_management.allocation_changed.connect(_on_power_allocation_changed)
	crew_data_log_system.log_discovered.connect(_on_crew_log_discovered)
	life_support.oxygen_changed.connect(_on_oxygen_changed)
	hud.restart_requested.connect(_restart_game)
	hud.communications_transmission_discovered.connect(
		_on_communications_transmission_discovered
	)
	hud.navigation_flight_record_discovered.connect(
		_on_navigation_flight_record_discovered
	)
	hud.security_incident_record_discovered.connect(
		_on_security_incident_record_discovered
	)
	hud.command_bridge_evidence_discovered.connect(
		_on_command_bridge_evidence_discovered
	)
	hud.command_bridge_ending_confirmed.connect(_on_command_bridge_ending_confirmed)
	var tree_root := get_tree().root
	var skip_save_restore := tree_root.has_meta(SKIP_SAVE_RESTORE_META)
	if skip_save_restore:
		tree_root.remove_meta(SKIP_SAVE_RESTORE_META)
	else:
		_restore_saved_game()
	if player.global_position.x >= -80.0:
		_dismiss_opening_instruction()
	if not _opening_instruction_dismissed and not _is_game_over and not _is_ending:
		hud.show_opening_tutorial(_get_opening_instruction())
	else:
		hud.dismiss_opening_tutorial()
	hud.set_player_position(player.global_position)
	hud.power_console_closed.connect(_on_power_console_closed)
	hud.crew_data_log_opened.connect(_on_crew_data_log_opened)
	hud.save_game_requested.connect(_on_save_game_requested)
	power_console.player_entered.connect(_on_interactable_entered)
	power_console.player_exited.connect(_on_interactable_exited)
	power_console.interaction_requested.connect(_on_power_console_interaction_requested)
	communications_console.player_entered.connect(_on_interactable_entered)
	communications_console.player_exited.connect(_on_interactable_exited)
	communications_console.interaction_requested.connect(_on_communications_console_interaction_requested)
	navigation_console.player_entered.connect(_on_interactable_entered)
	navigation_console.player_exited.connect(_on_interactable_exited)
	navigation_console.interaction_requested.connect(_on_navigation_console_interaction_requested)
	security_console.player_entered.connect(_on_interactable_entered)
	security_console.player_exited.connect(_on_interactable_exited)
	security_console.interaction_requested.connect(_on_security_console_interaction_requested)
	command_bridge_terminal.player_entered.connect(_on_interactable_entered)
	command_bridge_terminal.player_exited.connect(_on_interactable_exited)
	command_bridge_terminal.interaction_requested.connect(
		_on_command_bridge_interaction_requested
	)
	for log_node: Node in crew_data_logs.get_children():
		var log_interactable := log_node as Interactable
		log_interactable.player_entered.connect(_on_interactable_entered)
		log_interactable.player_exited.connect(_on_interactable_exited)
		log_interactable.interaction_requested.connect(_on_crew_data_log_interaction_requested)

	for location: LocationArea in $Gameplay/Locations.get_children():
		location.location_entered.connect(_on_location_entered)
	_sync_objectives_with_player_position()
	if _is_ending:
		player.set_physics_process(false)
		hud.show_ending(_ending_id)


func _process(delta: float) -> void:
	_sync_world_view(delta)
	_update_power_console_proximity()
	if not _opening_instruction_dismissed and player.global_position.x >= -80.0:
		_dismiss_opening_instruction()
	if not _is_game_over and not _is_ending:
		life_support.update(delta)
	hud.set_player_position(player.global_position)


func _update_power_console_proximity() -> void:
	_update_console_proximity(power_console, POWER_CONSOLE_INTERACTION_DISTANCE)
	_update_console_proximity(communications_console, COMMUNICATIONS_CONSOLE_INTERACTION_DISTANCE)
	_update_console_proximity(navigation_console, NAVIGATION_CONSOLE_INTERACTION_DISTANCE)
	_update_console_proximity(security_console, SECURITY_CONSOLE_INTERACTION_DISTANCE)
	_update_console_proximity(command_bridge_terminal, COMMAND_BRIDGE_INTERACTION_DISTANCE)
	for log_node: Node in crew_data_logs.get_children():
		var log_interactable := log_node as Interactable
		_update_console_proximity(log_interactable, 32.0)


func _update_console_proximity(console: Interactable, interaction_distance: float) -> void:
	var distance_to_console := player.global_position.distance_to(console.global_position)
	if distance_to_console <= interaction_distance:
		if not is_instance_valid(nearby_interactable):
			_on_interactable_entered(console)
	elif nearby_interactable == console:
		_on_interactable_exited(console)


func _sync_world_view(delta: float) -> void:
	ship_world.sync_view(
		player_camera.get_screen_center_position(),
		player.global_position,
		player.get_real_velocity(),
		player.sprite.frame_coords.y,
		delta
	)


func _unhandled_input(event: InputEvent) -> void:
	if _is_game_over or _is_ending:
		get_viewport().set_input_as_handled()
		return

	if hud.is_any_console_open():
		if event.is_action_pressed("ui_cancel"):
			hud.close_open_console()
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("interact") and is_instance_valid(nearby_interactable):
		nearby_interactable.interact()
		get_viewport().set_input_as_handled()


func _on_interactable_entered(interactable: Interactable) -> void:
	if _is_game_over or _is_ending:
		return
	nearby_interactable = interactable
	hud.set_interaction_hint(interactable.interaction_hint)


func _on_interactable_exited(interactable: Interactable) -> void:
	if _is_game_over or _is_ending:
		return
	if nearby_interactable != interactable:
		return
	if interactable == power_console:
		var distance_to_console := player.global_position.distance_to(power_console.global_position)
		if distance_to_console <= POWER_CONSOLE_INTERACTION_DISTANCE:
			return

	hud.close_power_console()
	hud.close_communications_console()
	hud.close_navigation_console()
	hud.close_security_console()
	hud.close_command_bridge()
	hud.close_crew_data_log()
	nearby_interactable = null
	hud.set_interaction_hint(_get_location_guidance())
	hud.clear_message()


func _on_location_entered(location_name: String) -> void:
	if _is_game_over:
		return
	current_location = location_name
	if location_name == "Main Corridor":
		_dismiss_opening_instruction()
		objective_system.complete_current_objective("investigate_ship")
	elif location_name == "Engineering Room":
		objective_system.complete_current_objective("reach_engineering")
	if not is_instance_valid(nearby_interactable):
		hud.set_interaction_hint(_get_location_guidance())


func _get_opening_instruction() -> String:
	return OPENING_TUTORIAL_TEXT


func _dismiss_opening_instruction() -> void:
	if _opening_instruction_dismissed:
		return
	_opening_instruction_dismissed = true
	hud.dismiss_opening_tutorial()


func _get_location_guidance() -> String:
	if current_location == "Engineering Room":
		return "Use the cyan power console or north-wall security console"
	if current_location == "Cryo Chamber":
		return "Access the navigation console along the north wall"
	return ""


func _sync_objectives_with_player_position() -> void:
	if player.global_position.x >= -80.0:
		objective_system.complete_current_objective("investigate_ship")
	if player.global_position.x >= 160.0:
		objective_system.complete_current_objective("reach_engineering")


func _on_power_console_interaction_requested(message: String) -> void:
	if _is_game_over or _is_ending:
		return
	hud.open_power_console(power_management, message)
	player.set_physics_process(false)


func _on_communications_console_interaction_requested(_message: String) -> void:
	if _is_game_over or _is_ending:
		return
	_begin_console_objective(
		"investigate_communications",
		power_management.get_system_allocated_power(PowerManagement.COMMUNICATIONS) >= 20
	)
	hud.open_communications_console(
		power_management,
		_communications_transmission_discovered
	)
	player.set_physics_process(false)


func _on_navigation_console_interaction_requested(_message: String) -> void:
	if _is_game_over or _is_ending:
		return
	_begin_console_objective(
		"investigate_navigation",
		power_management.get_system_allocated_power(PowerManagement.NAVIGATION) >= 25
		and _navigation_flight_record_discovered
	)
	hud.open_navigation_console(
		power_management,
		_navigation_flight_record_discovered
	)
	player.set_physics_process(false)


func _on_security_console_interaction_requested(_message: String) -> void:
	if _is_game_over or _is_ending:
		return
	_begin_console_objective(
		"access_security",
		power_management.get_system_allocated_power(PowerManagement.SECURITY) >= 20
		and _security_incident_record_discovered
	)
	hud.open_security_console(
		power_management,
		_security_incident_record_discovered
	)
	player.set_physics_process(false)


func _on_command_bridge_interaction_requested(_message: String) -> void:
	if _is_game_over or _is_ending:
		return
	if (
		objective_system.get_current_objective_id() != "reach_command_bridge"
		and not objective_system.get_completed_objective_ids().has("reach_command_bridge")
	):
		hud.show_message("COMMAND RECORD LOCKED\nComplete the ship investigations first.")
		return
	hud.open_command_bridge(_command_bridge_evidence_discovered)
	player.set_physics_process(false)


func _on_crew_data_log_interaction_requested(log_id: String) -> void:
	if _is_game_over or _is_ending:
		return
	if not crew_data_log_system.has_log(log_id):
		push_error("Main: Crew data log terminal references unknown log '%s'." % log_id)
		return

	crew_data_log_system.discover_log(log_id)
	hud.open_crew_data_log(crew_data_log_system, log_id)


func _on_crew_data_log_opened() -> void:
	player.set_physics_process(false)


func _begin_console_objective(objective_id: String, condition_met: bool = true) -> void:
	_pending_console_objective_id = (
		objective_id
		if condition_met and objective_system.get_current_objective_id() == objective_id
		else ""
	)


func _restore_saved_game() -> void:
	var saved_state := save_game_system.load_game(crew_data_log_system, objective_system)
	if saved_state.is_empty():
		return

	_is_restoring_saved_game = true
	var saved_position: Vector2 = saved_state["player_position"]
	var saved_allocations: Dictionary = saved_state["power_allocations"]
	var saved_oxygen: float = saved_state["oxygen"]
	var saved_log_ids: Array = saved_state["discovered_log_ids"]
	_opening_instruction_dismissed = saved_state["opening_tutorial_dismissed"]
	_communications_transmission_discovered = (
		saved_state["communications_transmission_discovered"]
	)
	_navigation_flight_record_discovered = (
		saved_state["navigation_flight_record_discovered"]
	)
	_security_incident_record_discovered = (
		saved_state["security_incident_record_discovered"]
	)
	_command_bridge_evidence_discovered = (
		saved_state["command_bridge_evidence_discovered"]
	)
	_ending_id = saved_state["ending_id"]
	if not _ending_id.is_empty():
		_command_bridge_evidence_discovered = true
	player.global_position = saved_position
	for system_name: String in PowerManagement.SYSTEM_NAMES:
		if not power_management.set_system_allocation(system_name, 0):
			push_error("Main: Could not prepare power allocations for save restoration.")
			_is_restoring_saved_game = false
			return
	for system_name: String in PowerManagement.SYSTEM_NAMES:
		if not power_management.set_system_allocation(
			system_name,
			saved_allocations[system_name]
		):
			push_error("Main: Could not restore '%s' power allocation." % system_name)
			_is_restoring_saved_game = false
			return

	life_support.restore_oxygen_level(saved_oxygen)
	crew_data_log_system.restore_discovered_logs(saved_log_ids)
	var objective_state := _migrate_objective_state(
		saved_state["objective_state"],
		saved_position
	)
	objective_system.restore_state(objective_state)
	if not _ending_id.is_empty():
		if _all_final_investigation_prerequisites_met() and not _is_game_over:
			_is_ending = true
		else:
			push_warning("Main: Saved ending did not satisfy investigation progress; ignoring it.")
			_ending_id = ""
	_is_restoring_saved_game = false
	_check_current_objective_condition(objective_system.get_current_objective_id())


func _migrate_objective_state(state: Dictionary, saved_position: Vector2) -> Dictionary:
	var completed_ids_variant: Variant = state.get("completed_ids", [])
	var completed_ids: Array = []
	if typeof(completed_ids_variant) == TYPE_ARRAY:
		completed_ids = completed_ids_variant.duplicate()

	var schema_version: int = state.get("schema_version", 1)
	if schema_version < 2 and completed_ids.has("investigate_ship"):
		completed_ids.append("reach_engineering")
	if saved_position.x >= -80.0 and not completed_ids.has("investigate_ship"):
		completed_ids.append("investigate_ship")
	if saved_position.x >= 160.0 and not completed_ids.has("reach_engineering"):
		completed_ids.append("reach_engineering")

	var validated_completed_ids: Array[String] = []
	for objective: Dictionary in ObjectiveSystem.OBJECTIVES:
		var objective_id: String = objective["id"]
		if not completed_ids.has(objective_id):
			break
		if not _objective_completion_is_valid(objective_id):
			break
		validated_completed_ids.append(objective_id)

	return {
		"schema_version": 4,
		"current_id": "",
		"completed_ids": validated_completed_ids,
	}


func _objective_completion_is_valid(objective_id: String) -> bool:
	match objective_id:
		"investigate_communications":
			return _communications_transmission_discovered
		"investigate_navigation":
			return _navigation_flight_record_discovered
		"access_security":
			return _security_incident_record_discovered
		"review_crew_logs":
			return crew_data_log_system.are_all_logs_discovered()
		"reach_command_bridge":
			return _command_bridge_evidence_discovered
	return true


func _on_save_game_requested() -> void:
	if _is_game_over or _is_ending:
		return

	var save_succeeded := _save_current_game()
	hud.show_save_result(save_succeeded)


func _save_current_game() -> bool:
	return save_game_system.save_game(
		player.global_position,
		life_support,
		power_management,
		crew_data_log_system,
		objective_system,
		_opening_instruction_dismissed,
		_communications_transmission_discovered,
		_navigation_flight_record_discovered,
		_security_incident_record_discovered,
		_command_bridge_evidence_discovered,
		_ending_id
	)


func _on_power_allocation_changed(system_name: String, _previous: int, new_allocation: int) -> void:
	if _is_restoring_saved_game:
		return
	if (
		system_name == PowerManagement.COMMUNICATIONS
		and new_allocation >= 20
		and hud.communications_console.visible
		and objective_system.get_current_objective_id() == "investigate_communications"
	):
		_pending_console_objective_id = "investigate_communications"
	if (
		system_name == PowerManagement.NAVIGATION
		and new_allocation >= 25
		and hud.navigation_console.visible
		and _navigation_flight_record_discovered
		and objective_system.get_current_objective_id() == "investigate_navigation"
	):
		_pending_console_objective_id = "investigate_navigation"
	if (
		system_name == PowerManagement.SECURITY
		and new_allocation >= 20
		and hud.security_console.visible
		and _security_incident_record_discovered
		and objective_system.get_current_objective_id() == "access_security"
	):
		_pending_console_objective_id = "access_security"
	if (
		system_name == PowerManagement.LIFE_SUPPORT
		and new_allocation >= LifeSupport.MINIMUM_STABLE_ALLOCATION
		and objective_system.get_current_objective_id() == "restore_life_support"
	):
		objective_system.complete_current_objective("restore_life_support")


func _on_communications_transmission_discovered() -> void:
	_communications_transmission_discovered = true
	if (
		not _is_game_over
		and objective_system.get_current_objective_id() == "investigate_communications"
	):
		_pending_console_objective_id = "investigate_communications"


func _on_navigation_flight_record_discovered() -> void:
	_navigation_flight_record_discovered = true
	if (
		not _is_game_over
		and objective_system.get_current_objective_id() == "investigate_navigation"
	):
		_pending_console_objective_id = "investigate_navigation"


func _on_security_incident_record_discovered() -> void:
	_security_incident_record_discovered = true
	if (
		not _is_game_over
		and objective_system.get_current_objective_id() == "access_security"
	):
		_pending_console_objective_id = "access_security"


func _on_command_bridge_evidence_discovered() -> void:
	if _command_bridge_evidence_discovered:
		return
	_command_bridge_evidence_discovered = true
	if objective_system.get_current_objective_id() == "reach_command_bridge":
		objective_system.complete_current_objective("reach_command_bridge")


func _on_command_bridge_ending_confirmed(ending_id: String) -> void:
	if (
		_is_game_over
		or _is_ending
		or not hud.command_bridge_panel.visible
		or not _all_final_investigation_prerequisites_met()
	):
		return
	if not objective_system.get_completed_objective_ids().has("reach_command_bridge"):
		return
	if ending_id != "response" and ending_id != "silence":
		push_error("Main: Refusing unknown ending id '%s'." % ending_id)
		return

	_ending_id = ending_id
	_is_ending = true
	player.set_physics_process(false)
	_save_current_game()
	hud.show_ending(_ending_id)


func _all_final_investigation_prerequisites_met() -> bool:
	var completed_ids := objective_system.get_completed_objective_ids()
	for required_id: String in [
		"restore_life_support",
		"investigate_communications",
		"investigate_navigation",
		"access_security",
		"review_crew_logs",
		"reach_command_bridge",
	]:
		if not completed_ids.has(required_id):
			return false
	return (
		_communications_transmission_discovered
		and _navigation_flight_record_discovered
		and _security_incident_record_discovered
		and _command_bridge_evidence_discovered
		and crew_data_log_system.are_all_logs_discovered()
	)


func _on_oxygen_changed(oxygen_level: float) -> void:
	if oxygen_level <= 0.0:
		_trigger_game_over()


func _trigger_game_over() -> void:
	if _is_game_over or _is_ending:
		return
	_is_game_over = true
	_pending_console_objective_id = ""
	hud.close_power_console()
	hud.close_communications_console()
	hud.close_navigation_console()
	hud.close_security_console()
	hud.close_command_bridge()
	hud.close_crew_data_log()
	player.set_physics_process(false)
	nearby_interactable = null
	hud.show_game_over()


func _restart_game() -> void:
	if not _is_game_over and not _is_ending:
		return

	if not save_game_system.clear_save():
		return
	var tree_root := get_tree().root
	tree_root.set_meta(SKIP_SAVE_RESTORE_META, true)
	var reload_error := get_tree().reload_current_scene()
	if reload_error != OK:
		tree_root.remove_meta(SKIP_SAVE_RESTORE_META)
		push_error("Main: Could not restart the game (error %d)." % reload_error)


func _on_crew_log_discovered(_log_id: String) -> void:
	if _is_restoring_saved_game:
		return
	_check_current_objective_condition(objective_system.get_current_objective_id())


func _on_current_objective_changed(objective_id: String, _title: String, _description: String) -> void:
	if _is_restoring_saved_game:
		return
	_check_current_objective_condition(objective_id)


func _check_current_objective_condition(objective_id: String) -> void:
	if (
		objective_id == "restore_life_support"
		and power_management.get_system_allocated_power(PowerManagement.LIFE_SUPPORT)
		>= LifeSupport.MINIMUM_STABLE_ALLOCATION
	):
		objective_system.complete_current_objective(objective_id)
	elif objective_id == "review_crew_logs" and crew_data_log_system.are_all_logs_discovered():
		objective_system.complete_current_objective(objective_id)
	elif objective_id == "investigate_navigation" and _navigation_flight_record_discovered:
		objective_system.complete_current_objective(objective_id)
	elif objective_id == "access_security" and _security_incident_record_discovered:
		objective_system.complete_current_objective(objective_id)
	elif objective_id == "reach_command_bridge" and _command_bridge_evidence_discovered:
		objective_system.complete_current_objective(objective_id)


func _on_power_console_closed() -> void:
	if _is_game_over:
		_pending_console_objective_id = ""
		player.set_physics_process(false)
		return

	var completed_objective_id := _pending_console_objective_id
	_pending_console_objective_id = ""
	match completed_objective_id:
		"investigate_communications":
			if power_management.get_system_allocated_power(PowerManagement.COMMUNICATIONS) >= 20:
				objective_system.complete_current_objective(completed_objective_id)
		"investigate_navigation":
			if power_management.get_system_allocated_power(PowerManagement.NAVIGATION) >= 25:
				objective_system.complete_current_objective(completed_objective_id)
		"access_security":
			if power_management.get_system_allocated_power(PowerManagement.SECURITY) >= 20:
				objective_system.complete_current_objective(completed_objective_id)

	player.set_physics_process(true)
