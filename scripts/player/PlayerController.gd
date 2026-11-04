extends CharacterBody2D
class_name PlayerController

@export var move_speed: float = 72.0

@onready var sprite: Sprite2D = $Sprite2D

var facing_row: int = 0
var animation_time: float = 0.0
var idle_frame: int = 0
var walk_frame: int = 0
var is_walking: bool = false


func _physics_process(delta: float) -> void:
	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_direction * move_speed
	move_and_slide()
	_update_sprite(delta, input_direction, get_real_velocity().length_squared() > 0.01)


func _update_sprite(delta: float, input_direction: Vector2, walking: bool) -> void:
	if walking != is_walking:
		animation_time = 0.0
		idle_frame = 0
		walk_frame = 0
		is_walking = walking

	if not input_direction.is_zero_approx():
		if absf(input_direction.x) > absf(input_direction.y):
			facing_row = 2 if input_direction.x > 0.0 else 1
		else:
			facing_row = 0 if input_direction.y > 0.0 else 3

	animation_time += delta
	var frame_interval := 0.12 if walking else 0.55
	var elapsed_frames := floori(animation_time / frame_interval)
	if elapsed_frames > 0:
		animation_time = fmod(animation_time, frame_interval)
		if elapsed_frames % 2 == 1:
			if walking:
				walk_frame = 1 - walk_frame
			else:
				idle_frame = 1 - idle_frame

	if not walking:
		sprite.frame_coords = Vector2i(idle_frame, facing_row)
	else:
		sprite.frame_coords = Vector2i(2 + walk_frame, facing_row)
