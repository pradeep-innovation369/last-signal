extends Node2D

const POWER_CONSOLE_INTERACTION_DISTANCE: float = 32.0
const COMMUNICATIONS_CONSOLE_INTERACTION_DISTANCE: float = 32.0
const NAVIGATION_CONSOLE_INTERACTION_DISTANCE: float = 32.0
const SECURITY_CONSOLE_INTERACTION_DISTANCE: float = 32.0
const OPENING_OXYGEN_GRACE_SECONDS: float = 60.0
const SKIP_SAVE_RESTORE_META: String = "last_signal_skip_save_restore_once"

@onready var power_console: Interactable = $WorldVisuals/DepthSort/PowerConsole
@onready var communications_console: Interactable = $WorldVisuals/DepthSort/CommunicationsConsole
@onready var navigation_console: Interactable = $WorldVisuals/DepthSort/NavigationConsole
@onready var security_console: Interactable = $WorldVisuals/DepthSort/SecurityConsole
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
var _opening_oxygen_grace_remaining: float = OPENING_OXYGEN_GRACE_SECONDS
var _is_game_over: bool = false


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
	var tree_root := get_tree().root
	var skip_save_restore := tree_root.has_meta(SKIP_SAVE_RESTORE_META)
	if skip_save_restore:
		tree_root.remove_meta(SKIP_SAVE_RESTORE_META)
	else:
		_restore_saved_game()
	if player.global_position.x >= -80.0:
		_dismiss_opening_instruction()
	if not _opening_instruction_dismissed and not _is_game_over:
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
	for log_node: Node in crew_data_logs.get_children():
		var log_interactable := log_node as Interactable
		log_interactable.player_entered.connect(_on_interactable_entered)
		log_interactable.player_exited.connect(_on_interactable_exited)
		log_interactable.interaction_requested.connect(_on_crew_data_log_interaction_requested)

	for location: LocationArea in $Gameplay/Locations.get_children():
		location.location_entered.connect(_on_location_entered)


func _process(delta: float) -> void:
	_sync_world_view(delta)
	_update_power_console_proximity()
	if not _opening_instruction_dismissed and player.global_position.x >= -80.0:
		_dismiss_opening_instruction()
	if not _is_game_over:
		if _opening_oxygen_grace_remaining > 0.0:
			_opening_oxygen_grace_remaining = maxf(
				0.0,
				_opening_oxygen_grace_remaining - delta
			)
		else:
			life_support.update(delta)
	hud.set_player_position(player.global_position)


func _update_power_console_proximity() -> void:
	_update_console_proximity(power_console, POWER_CONSOLE_INTERACTION_DISTANCE)
	_update_console_proximity(communications_console, COMMUNICATIONS_CONSOLE_INTERACTION_DISTANCE)
	_update_console_proximity(navigation_console, NAVIGATION_CONSOLE_INTERACTION_DISTANCE)
	_update_console_proximity(security_console, SECURITY_CONSOLE_INTERACTION_DISTANCE)
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
	if _is_game_over:
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
	if _is_game_over:
		return
	nearby_interactable = interactable
	hud.set_interaction_hint(interactable.interaction_hint)


func _on_interactable_exited(interactable: Interactable) -> void:
	if _is_game_over:
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
	elif location_name == "Engineering Room":
		objective_system.complete_current_objective("investigate_ship")
	if not is_instance_valid(nearby_interactable):
		hud.set_interaction_hint(_get_location_guidance())


func _get_opening_instruction() -> String:
	return "MOVE: WASD / ARROWS  -  REACH ENGINEERING VIA MAIN CORRIDOR"


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


func _on_power_console_interaction_requested(message: String) -> void:
	if _is_game_over:
		return
	_begin_console_objective("inspect_power_console")
	hud.open_power_console(power_management, message)
	player.set_physics_process(false)


func _on_communications_console_interaction_requested(_message: String) -> void:
	if _is_game_over:
		return
	_begin_console_objective(
		"investigate_communications",
		power_management.get_system_allocated_power(PowerManagement.COMMUNICATIONS) >= 20
	)
	hud.open_communications_console(power_management)
	player.set_physics_process(false)


func _on_navigation_console_interaction_requested(_message: String) -> void:
	if _is_game_over:
		return
	_begin_console_objective(
		"investigate_navigation",
		power_management.get_system_allocated_power(PowerManagement.NAVIGATION) >= 25
	)
	hud.open_navigation_console(power_management)
	player.set_physics_process(false)


func _on_security_console_interaction_requested(_message: String) -> void:
	if _is_game_over:
		return
	_begin_console_objective(
		"access_security",
		power_management.get_system_allocated_power(PowerManagement.SECURITY) >= 20
	)
	hud.open_security_console(power_management)
	player.set_physics_process(false)


func _on_crew_data_log_interaction_requested(log_id: String) -> void:
	if _is_game_over:
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

	var saved_position: Vector2 = saved_state["player_position"]
	var saved_allocations: Dictionary = saved_state["power_allocations"]
	var saved_oxygen: float = saved_state["oxygen"]
	var saved_log_ids: Array = saved_state["discovered_log_ids"]
	_opening_instruction_dismissed = saved_state["opening_tutorial_dismissed"]
	player.global_position = saved_position
	for system_name: String in PowerManagement.SYSTEM_NAMES:
		if not power_management.set_system_allocation(system_name, 0):
			push_error("Main: Could not prepare power allocations for save restoration.")
			return
	for system_name: String in PowerManagement.SYSTEM_NAMES:
		if not power_management.set_system_allocation(
			system_name,
			saved_allocations[system_name]
		):
			push_error("Main: Could not restore '%s' power allocation." % system_name)
			return

	life_support.restore_oxygen_level(saved_oxygen)
	crew_data_log_system.restore_discovered_logs(saved_log_ids)
	var objective_state: Dictionary = saved_state["objective_state"]
	objective_system.restore_state(objective_state)
	_check_current_objective_condition(objective_system.get_current_objective_id())


func _on_save_game_requested() -> void:
	if _is_game_over:
		return
	var save_succeeded := save_game_system.save_game(
		player.global_position,
		life_support,
		power_management,
		crew_data_log_system,
		objective_system,
		_opening_instruction_dismissed
	)
	hud.show_save_result(save_succeeded)


func _on_power_allocation_changed(system_name: String, _previous: int, new_allocation: int) -> void:
	if (
		system_name == PowerManagement.LIFE_SUPPORT
		and new_allocation >= LifeSupport.MINIMUM_STABLE_ALLOCATION
	):
		_opening_oxygen_grace_remaining = 0.0
	if (
		system_name == PowerManagement.LIFE_SUPPORT
		and new_allocation >= LifeSupport.MINIMUM_STABLE_ALLOCATION
		and objective_system.get_current_objective_id() == "restore_life_support"
	):
		objective_system.complete_current_objective("restore_life_support")


func _on_oxygen_changed(oxygen_level: float) -> void:
	if oxygen_level <= 0.0:
		_trigger_game_over()


func _trigger_game_over() -> void:
	if _is_game_over:
		return
	_is_game_over = true
	_pending_console_objective_id = ""
	hud.close_power_console()
	hud.close_communications_console()
	hud.close_navigation_console()
	hud.close_security_console()
	hud.close_crew_data_log()
	player.set_physics_process(false)
	nearby_interactable = null
	hud.show_game_over()


func _restart_game() -> void:
	if not _is_game_over:
		return

	var tree_root := get_tree().root
	tree_root.set_meta(SKIP_SAVE_RESTORE_META, true)
	var reload_error := get_tree().reload_current_scene()
	if reload_error != OK:
		tree_root.remove_meta(SKIP_SAVE_RESTORE_META)
		push_error("Main: Could not restart the game (error %d)." % reload_error)


func _on_crew_log_discovered(_log_id: String) -> void:
	_check_current_objective_condition(objective_system.get_current_objective_id())


func _on_current_objective_changed(objective_id: String, _title: String, _description: String) -> void:
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


func _on_power_console_closed() -> void:
	if _is_game_over:
		_pending_console_objective_id = ""
		player.set_physics_process(false)
		return

	var completed_objective_id := _pending_console_objective_id
	_pending_console_objective_id = ""
	match completed_objective_id:
		"inspect_power_console":
			objective_system.complete_current_objective(completed_objective_id)
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
