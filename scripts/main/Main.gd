extends Node2D

const POWER_CONSOLE_INTERACTION_DISTANCE: float = 32.0
const COMMUNICATIONS_CONSOLE_INTERACTION_DISTANCE: float = 32.0

@onready var power_console: Interactable = $WorldVisuals/DepthSort/PowerConsole
@onready var communications_console: Interactable = $WorldVisuals/DepthSort/CommunicationsConsole
@onready var hud: HUDController = $HUD
@onready var player: PlayerController = $WorldVisuals/DepthSort/Player
@onready var player_camera: Camera2D = $WorldVisuals/DepthSort/Player/Camera2D
@onready var render_viewport: SubViewport = $WorldRenderViewport
@onready var ship_world: ShipWorld3D = $WorldRenderViewport/ShipWorld3D
@onready var world_texture: Sprite2D = $WorldRenderLayer/WorldTexture

var power_management: PowerManagement = PowerManagement.new()
var life_support: LifeSupport
var nearby_interactable: Interactable
var current_location: String = ""


func _ready() -> void:
	life_support = LifeSupport.new(power_management)
	world_texture.texture = render_viewport.get_texture()
	_sync_world_view(0.0)
	hud.set_life_support(life_support, power_management)
	hud.set_player_position(player.global_position)
	hud.power_console_closed.connect(_on_power_console_closed)
	power_console.player_entered.connect(_on_interactable_entered)
	power_console.player_exited.connect(_on_interactable_exited)
	power_console.interaction_requested.connect(_on_power_console_interaction_requested)
	communications_console.player_entered.connect(_on_interactable_entered)
	communications_console.player_exited.connect(_on_interactable_exited)
	communications_console.interaction_requested.connect(_on_communications_console_interaction_requested)

	for location: LocationArea in $Gameplay/Locations.get_children():
		location.location_entered.connect(_on_location_entered)


func _process(delta: float) -> void:
	_sync_world_view(delta)
	_update_power_console_proximity()
	life_support.update(delta)
	hud.set_player_position(player.global_position)


func _update_power_console_proximity() -> void:
	_update_console_proximity(power_console, POWER_CONSOLE_INTERACTION_DISTANCE)
	_update_console_proximity(communications_console, COMMUNICATIONS_CONSOLE_INTERACTION_DISTANCE)


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
	if hud.is_any_console_open():
		if event.is_action_pressed("ui_cancel"):
			hud.close_open_console()
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("interact") and is_instance_valid(nearby_interactable):
		nearby_interactable.interact()
		get_viewport().set_input_as_handled()


func _on_interactable_entered(interactable: Interactable) -> void:
	nearby_interactable = interactable
	hud.set_interaction_hint(interactable.interaction_hint)


func _on_interactable_exited(interactable: Interactable) -> void:
	if nearby_interactable != interactable:
		return
	if interactable == power_console:
		var distance_to_console := player.global_position.distance_to(power_console.global_position)
		if distance_to_console <= POWER_CONSOLE_INTERACTION_DISTANCE:
			return

	hud.close_power_console()
	hud.close_communications_console()
	nearby_interactable = null
	hud.set_interaction_hint(_get_location_guidance())
	hud.clear_message()


func _on_location_entered(location_name: String) -> void:
	current_location = location_name
	if not is_instance_valid(nearby_interactable):
		hud.set_interaction_hint(_get_location_guidance())


func _get_location_guidance() -> String:
	if current_location == "Engineering Room":
		return "Go right into Engineering; find the cyan-screen console"
	return ""


func _on_power_console_interaction_requested(message: String) -> void:
	hud.open_power_console(power_management, message)
	player.set_physics_process(false)


func _on_communications_console_interaction_requested(_message: String) -> void:
	hud.open_communications_console(power_management)
	player.set_physics_process(false)


func _on_power_console_closed() -> void:
	player.set_physics_process(true)
