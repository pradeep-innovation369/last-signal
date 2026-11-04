extends Node2D

@onready var power_console: Interactable = $WorldVisuals/DepthSort/PowerConsole
@onready var hud: HUDController = $HUD
@onready var player: PlayerController = $WorldVisuals/DepthSort/Player
@onready var player_camera: Camera2D = $WorldVisuals/DepthSort/Player/Camera2D
@onready var render_viewport: SubViewport = $WorldRenderViewport
@onready var ship_world: ShipWorld3D = $WorldRenderViewport/ShipWorld3D
@onready var world_texture: Sprite2D = $WorldRenderLayer/WorldTexture

var nearby_interactable: Interactable


func _ready() -> void:
	world_texture.texture = render_viewport.get_texture()
	_sync_world_view()
	power_console.player_entered.connect(_on_interactable_entered)
	power_console.player_exited.connect(_on_interactable_exited)
	power_console.interaction_requested.connect(hud.show_message)

	for location: LocationArea in $Gameplay/Locations.get_children():
		location.location_entered.connect(hud.set_location)


func _process(_delta: float) -> void:
	_sync_world_view()


func _sync_world_view() -> void:
	ship_world.sync_view(
		player_camera.get_screen_center_position(),
		player.global_position,
		player.sprite.frame_coords
	)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and is_instance_valid(nearby_interactable):
		nearby_interactable.interact()
		get_viewport().set_input_as_handled()


func _on_interactable_entered(interactable: Interactable) -> void:
	nearby_interactable = interactable
	hud.set_interaction_hint(interactable.interaction_hint)


func _on_interactable_exited(interactable: Interactable) -> void:
	if nearby_interactable != interactable:
		return

	nearby_interactable = null
	hud.set_interaction_hint("")
	hud.clear_message()
