extends Area2D
class_name LocationArea

signal location_entered(location_name: String)

@export var location_name: String = "Unknown"


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		location_entered.emit(location_name)
