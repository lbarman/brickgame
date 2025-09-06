extends Node2D

@export var initial_speed: int = 300 # The speed when movement starts.
@export var max_speed: int = 1000     # The maximum speed the object can reach.
@export var acceleration: int = 1000  # How quickly the speed increases per second.
@export var tilt_angle_degrees: float = 15.0 # The max angle to tilt in degrees.
@export var tilt_in_speed: float = 20.0  # How quickly the object tilts.
@export var tilt_return_speed: float = 5.0  # How quickly the object returns to flat.

@onready var camera_2d: Camera2D = $"../Camera2D"
@onready var color_rect: ColorRect = $CharacterBody2D/ColorRect

var current_speed: float = 0.0
var last_direction: int = 0
var min_max_x: float = 0

func _ready() -> void:
	min_max_x = get_viewport_rect().size.x/2 - color_rect.size.x/2

func _process(delta: float) -> void:
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction != 0 && abs(position.x) != min_max_x:
		current_speed += acceleration * delta
		current_speed = min(current_speed, max_speed)
	else:
		current_speed = initial_speed
		
	var target_rotation = 0.0
	if direction != 0 && abs(position.x) != min_max_x:
		target_rotation = tilt_angle_degrees * direction
		
	if target_rotation != 0.0:
		# When a new direction is pressed, tilt in quickly.
		rotation_degrees = lerp(rotation_degrees, target_rotation, tilt_in_speed * delta)
	else:
		# In all other cases, slowly return to a flat position.
		rotation_degrees = lerp(rotation_degrees, 0.0, tilt_return_speed * delta)
			
	var x = position.x + direction * current_speed * delta
	
	position.x = clamp(x, -min_max_x, min_max_x)
	
