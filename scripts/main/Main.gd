extends Node2D

@onready var power_console: Interactable = $WorldVisuals/DepthSort/PowerConsole
@onready var hud: HUDController = $HUD
@onready var player: PlayerController = $WorldVisuals/DepthSort/Player
@onready var player_camera: Camera2D = $WorldVisuals/DepthSort/Player/Camera2D
@onready var render_viewport: SubViewport = $WorldRenderViewport
@onready var ship_world: ShipWorld3D = $WorldRenderViewport/ShipWorld3D
@onready var world_texture: Sprite2D = $WorldRenderLayer/WorldTexture

var power_management: PowerManagement = PowerManagement.new()
var nearby_interactable: Interactable


func _ready() -> void:
	world_texture.texture = render_viewport.get_texture()
	_sync_world_view(0.0)
	hud.power_console_closed.connect(_on_power_console_closed)
	power_console.player_entered.connect(_on_interactable_entered)
	power_console.player_exited.connect(_on_interactable_exited)
	power_console.interaction_requested.connect(_on_power_console_interaction_requested)

	for location: LocationArea in $Gameplay/Locations.get_children():
		location.location_entered.connect(hud.set_location)


func _process(delta: float) -> void:
	_sync_world_view(delta)


func _sync_world_view(delta: float) -> void:
	ship_world.sync_view(
		player_camera.get_screen_center_position(),
		player.global_position,
		player.get_real_velocity(),
		player.sprite.frame_coords.y,
		delta
	)


func _unhandled_input(event: InputEvent) -> void:
	if hud.is_power_console_open():
		if event.is_action_pressed("ui_cancel"):
			hud.close_power_console()
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

	hud.close_power_console()
	nearby_interactable = null
	hud.set_interaction_hint("")
	hud.clear_message()


func _on_power_console_interaction_requested(message: String) -> void:
	hud.open_power_console(power_management, message)
	player.set_physics_process(false)


func _on_power_console_closed() -> void:
	player.set_physics_process(true)
