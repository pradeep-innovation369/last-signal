extends CanvasLayer
class_name HUDController

@onready var location_label: Label = $Root/LocationLabel
@onready var interaction_hint: Label = $Root/InteractionHint
@onready var message_frame: ColorRect = $Root/MessageFrame
@onready var message_panel: ColorRect = $Root/MessagePanel
@onready var message_label: Label = $Root/MessageLabel


func set_location(location_name: String) -> void:
	location_label.text = location_name


func set_interaction_hint(hint: String) -> void:
	interaction_hint.text = hint
	interaction_hint.visible = not hint.is_empty()


func show_message(message: String) -> void:
	message_label.text = message
	message_label.visible = true
	message_frame.visible = true
	message_panel.visible = true


func clear_message() -> void:
	message_label.visible = false
	message_frame.visible = false
	message_panel.visible = false
