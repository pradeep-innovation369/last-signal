extends Node2D

@onready var power_console: Interactable = $WorldVisuals/DepthSort/PowerConsole
@onready var hud: HUDController = $HUD

var nearby_interactable: Interactable


func _ready() -> void:
	power_console.player_entered.connect(_on_interactable_entered)
	power_console.player_exited.connect(_on_interactable_exited)
	power_console.interaction_requested.connect(hud.show_message)

	for location: LocationArea in $Gameplay/Locations.get_children():
		location.location_entered.connect(hud.set_location)


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
