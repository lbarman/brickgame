extends RigidBody2D
class_name BlockTemplate


@export_group("Block Physics")
@export var block_bounce: float = 0.2
@export var block_friction: float = 0.5
@export var block_mass: float = 10.0
@export var block_linear_damp: float = 10.0
@export var self_destruct_y: float = 200.0
@export var block_move_speed: float = 5.0

@onready var cpu_particles_2d: CPUParticles2D = $CPUParticles2D
@onready var color_rect: ColorRect = $ColorRect

var color: Color = Color.WHITE:
	set(new_color):
		color = new_color
		if color_rect:
			color_rect.color = color
			
var row_id: int = 0
var col_id: int = 0
var target_pos: Vector2 = Vector2.ZERO
var is_being_deleted: bool = false
var block_manager: BlockManager

func get_target():
	if target_pos:
		return target_pos
	return position
	
func move_by(inc: Vector2):
	target_pos = get_target() + inc

func _ready() -> void:
	gravity_scale = 0
	mass = block_mass
	linear_damp = block_linear_damp
	contact_monitor = true
	max_contacts_reported = 1
	color_rect.color = color
	cpu_particles_2d.emitting = false

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("ball"):
		return
	
	destroy()
	if block_manager:
		block_manager.inc_score(1)
		block_manager.delete_same_color_adjacent_blocks(row_id)
	


func _physics_process(delta):
	var target_pos = get_target()
	var current_pos = position

	# If the block is very close to its target, stop it and remove the target.
	if current_pos.distance_squared_to(target_pos) < 1.0:
		linear_velocity = Vector2.ZERO
		position = target_pos # Snap it to the final position
	else:
		# Calculate the desired velocity. This creates a "lerp" effect - the block
		# moves faster when it's further away and slows down as it approaches.
		var desired_velocity = (target_pos - current_pos) * block_move_speed
		linear_velocity = desired_velocity	
	
	if position.y > self_destruct_y:
		destroy()


func destroy():
	is_being_deleted = true
	# --- Spawn Particles ---
	var particles = cpu_particles_2d.duplicate()
	particles.global_position = global_position
	particles.color = color
	particles.emitting = true
	get_tree().current_scene.add_child(particles)
	
	# Clean up the particles node after it has finished.
	var timer = Timer.new()
	timer.wait_time = particles.lifetime
	timer.one_shot = true
	particles.add_child(timer)
	timer.connect("timeout", Callable(particles, "queue_free"))
	timer.start()
	
	var block_timer = Timer.new()
	block_timer.wait_time = 0.2
	block_timer.one_shot = true
	block_timer.connect("timeout", Callable(self, "queue_free"))
	# Add the timer to the scene so it's not destroyed if its parent is.
	add_child(block_timer)
	block_timer.start()
	
