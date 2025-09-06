extends RigidBody2D

@export_group("Speed")
@export var min_speed: float = 400.0
@export var acceleration_per_hit: float = 0.0
@export var max_speed: float = 1200.0

@export_group("Color")
@export var start_color: Color = Color.DODGER_BLUE
@export var end_color: Color = Color.MEDIUM_VIOLET_RED

@onready var bottom_wall: StaticBody2D = $"../../Walls/BottomStaticBody2D"
@onready var ball_sprite: Sprite2D = $BallSprite
@onready var trajectory_line: Line2D = $TrajectoryLine2D

var speed: float = min_speed

func _ready():
	gravity_scale = 0
	contact_monitor = true
	max_contacts_reported = 4 # Report multiple contacts if needed.
	connect("body_entered", Callable(self, "_on_body_entered"))
	
	var m = PhysicsMaterial.new()
	m.friction = 0
	m.bounce = 1
	physics_material_override = m
	
	linear_velocity = Vector2.RIGHT.rotated(randf_range(0, PI/2)-PI/4) * min_speed

	if ball_sprite:
		ball_sprite.modulate = start_color
		
	# Configure the trajectory line's appearance.
	if trajectory_line:
		trajectory_line.width = 20.0
		trajectory_line.default_color = Color(1.0, 1.0, 1.0, 0.1) # Semi-transparent white
		
		var gradient = Gradient.new()
		# Define the points on the gradient (0.0 is the start, 1.0 is the end).
		gradient.offsets = PackedFloat32Array([0.0, 1.0])
		# Define the colors at those points.
		# It will start semi-transparent and end fully transparent.
		gradient.colors = PackedColorArray([Color(1, 1, 1, 0.2), Color(1, 1, 1, 0)])
		
		# Apply the gradient to the line.
		trajectory_line.gradient = gradient


func _physics_process(delta):
	linear_velocity = linear_velocity.normalized() * clamp(speed, min_speed, max_speed)

	if ball_sprite:
		var speed_ratio = inverse_lerp(min_speed, max_speed, linear_velocity.length())
		ball_sprite.modulate = start_color.lerp(end_color, speed_ratio)

	_update_trajectory()

func _on_body_entered(body):
	speed = min(speed + acceleration_per_hit, max_speed)



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
	var max_bounces = 3
	trajectory_line.add_point(to_local(current_pos))

	# Predict the path for a number of steps. Increased range for more complex paths.
	for i in range(100):
		var next_pos = current_pos + current_velocity * time_step
		
		var query = PhysicsRayQueryParameters2D.create(current_pos, next_pos)
		query.exclude = [self.get_rid()] # Exclude the ball itself from the query.
		query.collision_mask = 0xFFFFFFFF
		var result = space_state.intersect_ray(query)
		
		if result:
			# If the ray hits something, draw the line to the collision point.
			trajectory_line.add_point(to_local(result.position))
			
			# Check if the collided object is the designated bottom wall.
			if bottom_wall and result.collider == bottom_wall:
				break
				
			current_velocity = current_velocity.bounce(result.normal)
			current_pos = result.position + result.normal * 0.1
			
			bounces += 1
			if bounces >= max_bounces:
				break
		else:
			# If no collision, just add the next point and continue.
			trajectory_line.add_point(to_local(next_pos))
			current_pos = next_pos
