extends Node2D


@export_group("Grid")
@export var num_rows: int = 2
@export var block_size: Vector2 = Vector2(80, 40)
@export var horizontal_spacing: float = 10.0
@export var vertical_spacing: float = 10.0
@export var initial_top_offset: float = 20.0
@export var self_destruct_y: float = 200.0
@export var block_move_speed: float = 5.0

@export_group("Block Physics")
@export var block_bounce: float = 0.2
@export var block_friction: float = 0.5
@export var block_mass: float = 10.0
@export var block_linear_damp: float = 10.0

@onready var score_label: Label = $"../Label"
@onready var label: Label = $"../Label"
@onready var shift_timer: Timer = $ShiftTimer

var all_blocks = []
var block_targets = {}
var score: int = 0
var num_columns = 1
var spawn_x = 0
var spawn_y = 0

func set_score(s: int):
	score = s
	label.text = str(s)

func _ready():
	num_columns = floor(get_viewport_rect().size.x / (block_size.x + vertical_spacing))
	num_columns = 7
	spawn_y = -(get_viewport_rect().size.y / 2 - block_size.y/2 - vertical_spacing) + initial_top_offset
	var x_width = num_columns * block_size.x + (num_columns - 1) * horizontal_spacing
	spawn_x = -x_width/2 + block_size.x/2
	for row in range(num_rows):
		spawn_row(spawn_y + row * (block_size.y + vertical_spacing))
	
	shift_timer.connect("timeout", Callable(self, "_on_shift_timer_timeout"))
	
	if score_label:
		score_label.text = "Score: 0"


func spawn_row(y_pos: float = spawn_y):
	for col in range(num_columns):
		var x_pos = spawn_x + col * (block_size.x + horizontal_spacing)
		spawn_block(Vector2(x_pos, y_pos))

# Creates a single block instance.
func spawn_block(pos: Vector2):
	var block = RigidBody2D.new()
	block.gravity_scale = 0
	block.position = pos
	block.mass = block_mass
	block.linear_damp = block_linear_damp

	var color_rect = ColorRect.new()
	color_rect.size = block_size
	color_rect.position = -block_size / 2 # Center the visual on the physics body's origin.
	color_rect.color = Color.from_hsv(randf(), 0.8, 0.9)
	block.add_child(color_rect)

	var collision_shape = CollisionShape2D.new()
	var rectangle_shape = RectangleShape2D.new()
	rectangle_shape.size = block_size
	collision_shape.shape = rectangle_shape
	block.add_child(collision_shape)

	block.contact_monitor = true
	block.max_contacts_reported = 1
	block.connect("body_entered", Callable(self, "_on_block_hit").bind(block))

	add_child(block)
	all_blocks.append(block)


func _physics_process(delta):
	for block in block_targets.keys():
		if not is_instance_valid(block):
			block_targets.erase(block)
			continue
			
		var target_pos = block_targets[block]
		var current_pos = block.position
		
		# If the block is very close to its target, stop it and remove the target.
		if current_pos.distance_squared_to(target_pos) < 1.0:
			block.linear_velocity = Vector2.ZERO
			block.position = target_pos # Snap it to the final position
			block_targets.erase(block)
		else:
			# Calculate the desired velocity. This creates a "lerp" effect - the block
			# moves faster when it's further away and slows down as it approaches.
			var desired_velocity = (target_pos - current_pos) * block_move_speed
			block.linear_velocity = desired_velocity
			
	
	# Check for blocks that have fallen off the screen.
	# Iterate backwards to safely remove items from the array.
	for i in range(all_blocks.size() - 1, -1, -1):
		var block = all_blocks[i]
		if is_instance_valid(block) and block.position.y > self_destruct_y:
			destroy_block(block)
			
func _on_shift_timer_timeout():
	var shift_amount = block_size.y + vertical_spacing
	for block in all_blocks:
		if is_instance_valid(block):
			var current_target = block_targets.get(block, block.position)
			block_targets[block] = Vector2(current_target.x, current_target.y + shift_amount)
	
	
	var spawn_timer = Timer.new()
	spawn_timer.wait_time = 0.5
	spawn_timer.one_shot = true
	spawn_timer.connect("timeout", Callable(self, "spawn_row"))
	# Add the timer to the scene so it's not destroyed if its parent is.
	add_child(spawn_timer)
	spawn_timer.start()
	
func _on_block_hit(body, block):
	if not body.is_in_group("ball"):
		return
		
	set_score(score + 1)
	destroy_block(block)

func destroy_block(block):
	# --- Spawn Particles ---
	var particles = CPUParticles2D.new()
	# Set position to the center of the block that was hit.
	particles.global_position = block.global_position + block_size / 2
	
	# Configure particle properties for a nice explosion effect.
	particles.emitting = true
	particles.amount = 40
	particles.lifetime = 0.8
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.speed_scale = 1.5
	
	particles.direction = Vector2(0, 1) # Downwards
	particles.spread = 90.0
	particles.gravity = Vector2(0, 980)
	particles.initial_velocity_min = 100.0
	particles.initial_velocity_max = 200.0
	
	particles.color = Color.WHITE
	
	# Add particles to the main scene tree so they don't get deleted with the block.
	get_tree().current_scene.add_child(particles)
	
	# Clean up the particles node after it has finished.
	var timer = Timer.new()
	timer.wait_time = particles.lifetime
	timer.one_shot = true
	particles.add_child(timer)
	timer.connect("timeout", Callable(particles, "queue_free"))
	timer.start()

	# --- Destroy the Block ---
	if block_targets.has(block):
		block_targets.erase(block)
	all_blocks.erase(block)
	
	var block_timer = Timer.new()
	block_timer.wait_time = 0.2
	block_timer.one_shot = true
	block_timer.connect("timeout", Callable(block, "queue_free"))
	# Add the timer to the scene so it's not destroyed if its parent is.
	add_child(block_timer)
	block_timer.start()
	
