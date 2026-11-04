extends Area2D
class_name Interactable

signal player_entered(interactable: Interactable)
signal player_exited(interactable: Interactable)
signal interaction_requested(message: String)

@export var interaction_hint: String = "E - Interact"
@export_multiline var interaction_message: String


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func interact() -> void:
	interaction_requested.emit(interaction_message)


func _on_body_entered(body: Node2D) -> void:
	# TEMP DEBUG: remove this line after testing.
	print(
		"PowerConsole debug | body_entered body=%s layer=%d groups=%s"
		% [body.name, body.collision_layer, body.get_groups()]
	)
	if body.is_in_group("player"):
		player_entered.emit(self)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_exited.emit(self)
