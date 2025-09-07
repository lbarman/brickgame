extends CharacterBody2D

@export_group("Horizontal Movement")
@export var initial_speed: int = 300 # The speed when movement starts.
@export var max_speed: int = 1000     # The maximum speed the object can reach.
@export var acceleration: int = 1000  # How quickly the speed increases per second.

@export_group("Tilting")
@export var tilt_angle_degrees: float = 15.0 # The max angle to tilt in degrees.
@export var tilt_in_speed: float = 20.0  # How quickly the object tilts.
@export var tilt_return_speed: float = 5.0  # How quickly the object returns to flat.

@export_group("Vertical Movement")
@export var vertical_speed: float = 500.0   # How fast the platform moves up.
@export var max_y_offset: float = 200.0     # How high it can go from its start position.
@export var return_y_speed: float = 5.0     # How quickly it returns to its start position.

@export_group("Ball Collision")
@export var hit_debounce_delay: float = 0.5 # Seconds between allowed hits (e.g., 0.5 = 2 times per sec)

@onready var camera_2d: Camera2D = $"../Camera2D"
@onready var color_rect: ColorRect = $ColorRect
@onready var ball: RigidBody2D = $"../Ball"

var current_speed: float = 0.0
var last_direction: int = 0
var min_max_x: float = 0
var initial_y: float = 0.0
var last_hit_time: int = 0
var is_rising: bool = false

func _ready() -> void:
	min_max_x = get_viewport_rect().size.x/2 - color_rect.size.x/2
	initial_y = position.y

func _physics_process(delta: float) -> void:
	
	var target_velocity = Vector2.ZERO
	
	# Horizontal movement
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction != 0 && abs(position.x) != min_max_x:
		current_speed += acceleration * delta
		current_speed = min(current_speed, max_speed)
		target_velocity.x = direction * current_speed

	else:
		current_speed = initial_speed		
		target_velocity.x = move_toward(velocity.x, 0, acceleration * delta)

	if position.x <= -min_max_x and target_velocity.x < 0:
		target_velocity.x = 0
	if position.x >= min_max_x and target_velocity.x > 0:
		target_velocity.x = 0
	
	# Vertical movement
	# "ui_accept" is the default mapping for the Spacebar.
	if Input.is_action_pressed("ui_accept"):
		is_rising = true
		if position.y > initial_y - max_y_offset:
			target_velocity.y = -vertical_speed
		else:
			target_velocity.y = 0
	else:
		# Smoothly return to the initial Y position
		target_velocity.y = (initial_y - position.y) * return_y_speed
		is_rising = false
	
	velocity = target_velocity
	move_and_slide()
	
	# Tilting
	var target_rotation = 0.0
	if direction != 0:
		target_rotation = tilt_angle_degrees * direction
		
	if target_rotation != 0.0:
		# When a new direction is pressed, tilt in quickly.
		rotation_degrees = lerp(rotation_degrees, target_rotation, tilt_in_speed * delta)
	else:
		# In all other cases, slowly return to a flat position.
		rotation_degrees = lerp(rotation_degrees, 0.0, tilt_return_speed * delta)
		
	# Collision Detection
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if collision.get_collider().is_in_group("ball"):
			ball_collision()
	
func ball_collision():
	var current_time = Time.get_ticks_msec()
	if last_hit_time == -1 || current_time - last_hit_time > hit_debounce_delay * 1000:
		last_hit_time = current_time
		ball_collision_debounced()
		
func ball_collision_debounced():
	if is_rising:
		ball.speed_up()
