extends RigidBody2D

@export_group("Speed")
@export var min_speed: float = 400.0
@export var acceleration_per_hit: float = 100.0
@export var max_speed: float = 800.0
@export var speed_reset_ration: float = 0.1

@export_group("Color")
@export var start_color: Color = Color.DODGER_BLUE
@export var end_color: Color = Color.MEDIUM_VIOLET_RED

@export_group("Trajectory Line")
@export var trajectory_width: float = 20.0
@export var trajectory_max_length: float = 500.0
@export var trajectory_color_start: Color = Color(1, 1, 1, 0.2)
@export var trajectory_color_end: Color = Color(1, 1, 1, 0)
@export var trajectory_max_bounces: int = 3

@onready var bottom_wall: StaticBody2D = $"../Walls/BottomStaticBody2D"
@onready var ball_sprite: Sprite2D = $BallSprite
@onready var trajectory_line: Line2D = $TrajectoryLine2D

var speed: float = min_speed

func _ready():
	gravity_scale = 0
	contact_monitor = true
	max_contacts_reported = 4
	connect("body_entered", Callable(self, "_on_body_entered"))
	
	var m = PhysicsMaterial.new()
	m.friction = 0
	m.bounce = 1
	physics_material_override = m
	
	# Initial angle is 90° facing up
	linear_velocity = Vector2.RIGHT.rotated(randf_range(0, PI/2)-PI/4) * min_speed
	linear_velocity = Vector2.DOWN.rotated(5*PI/90)

	# Change the ball color with speed.
	if ball_sprite:
		ball_sprite.modulate = start_color
		
	# Configure the trajectory line's appearance.
	if trajectory_line:
		trajectory_line.width = trajectory_width	
		var gradient = Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, 1.0])
		var colors = [trajectory_color_start, trajectory_color_end]
		gradient.colors = PackedColorArray(colors)
		trajectory_line.gradient = gradient

func _on_body_entered(body):
	# Re-set speed to prevent decelerating. Also cap it.
	#speed = min(speed + acceleration_per_hit, max_speed)
	pass

func _physics_process(delta):
	linear_velocity = linear_velocity.normalized() * clamp(speed, min_speed, max_speed)
	speed = lerp(speed, min_speed, delta*speed_reset_ration)
	
	# Set ball color
	if ball_sprite:
		var speed_ratio = inverse_lerp(min_speed, max_speed, linear_velocity.length())
		ball_sprite.modulate = start_color.lerp(end_color, speed_ratio)

	_update_trajectory()

func speed_up(inc: float = acceleration_per_hit):
	speed = min(speed + inc, max_speed)

# Simulates the ball's path and draws it using the Line2D node.
func _update_trajectory():
	if not trajectory_line:
		return

	trajectory_line.clear_points()

	var space_state = get_world_2d().direct_space_state
	var current_pos = global_position
	var current_velocity = linear_velocity
	var time_step = 0.05
	var bounces = 0
	var current_length: float = 0.0
	trajectory_line.add_point(to_local(current_pos))

	# Predict the path for a number of steps. Increased range for more complex paths.
	for i in range(100):
		var next_pos = current_pos + current_velocity * time_step
		var segment_end_pos = next_pos

		var query = PhysicsRayQueryParameters2D.create(current_pos, next_pos)
		query.exclude = [self.get_rid()] # Exclude the ball itself from the query.
		query.collision_mask = 0xFFFFFFFF
		
		var result = space_state.intersect_ray(query)
		
		# cap total line length
		var segment_length = current_pos.distance_to(segment_end_pos)
		if current_length + segment_length > trajectory_max_length:
			var remaining_length = trajectory_max_length - current_length
			var direction = current_pos.direction_to(segment_end_pos)
			var final_point = current_pos + direction * remaining_length
			trajectory_line.add_point(to_local(final_point))
			break # Stop drawing.
		
		# Add the point and update the total length.
		trajectory_line.add_point(to_local(segment_end_pos))
		current_length += segment_length
		
		if result:
			trajectory_line.add_point(to_local(result.position))
			
			# Check if the collided object is the designated bottom wall.
			if bottom_wall and result.collider == bottom_wall:
				break
				
			current_velocity = current_velocity.bounce(result.normal)
			current_pos = result.position + result.normal * 0.1
			
			bounces += 1
			if bounces >= trajectory_max_bounces:
				break
		else:
			
			# If no collision, just add the next point and continue.
			trajectory_line.add_point(to_local(next_pos))
			current_pos = next_pos
