extends Node2D


@export_group("Grid")
@export var num_rows: int = 2
@export var block_size: Vector2 = Vector2(80, 40)
@export var horizontal_spacing: float = 10.0
@export var vertical_spacing: float = 10.0
@export var initial_top_offset: float = 20.0

@onready var score_label: Label = $"../Label"
@onready var label: Label = $"../Label"
@onready var shift_timer: Timer = $ShiftTimer

const blockTemplate = preload("res://block_template.tscn")

var blocks: Array[BlockTemplate] = []
var num_columns: int = 1
var spawn_x: float = 0
var spawn_y: float = 0
var next_row_id: int = 0

var score: int = 0:
	set(s):
		score = s
		if label:
			label.text = str(s)

func inc_score(d):
	score += d

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


func _on_shift_timer_timeout():
	var shift_amount = block_size.y + vertical_spacing
	for block in blocks:
		if is_instance_valid(block):
			block.move_by(Vector2(0, shift_amount))

	var spawn_timer = Timer.new()
	spawn_timer.wait_time = 0.5
	spawn_timer.one_shot = true
	spawn_timer.connect("timeout", Callable(self, "spawn_row"))
	add_child(spawn_timer)
	spawn_timer.start()
	
func spawn_row(y_pos: float = spawn_y):
	var row_id = next_row_id
	next_row_id += 1
	for col in range(num_columns):
		var x_pos = spawn_x + col * (block_size.x + horizontal_spacing)
		spawn_block(next_row_id, Vector2(x_pos, y_pos))
	
func spawn_block(row_id: int, pos: Vector2):
	var block: BlockTemplate = blockTemplate.instantiate()
	block.position = pos
	block.color = Color.WHITE
	block.row_id = row_id
	block.block_manager = self
	add_child(block)
	blocks.append(block)

func delete_same_color_adjacent_blocks():	
	if blocks.size() < 2:
		return

	var blocks_to_destroy = []
	var match_group = [blocks[0]]

	for i in range(1, blocks.size()):
		var current_block = blocks[i]
		var last_block_in_group = match_group.back()

		var current_color = current_block.get_node("ColorRect").color
		var last_color = last_block_in_group.get_node("ColorRect").color

		if current_color == last_color:
			match_group.append(current_block)
		else:
			if match_group.size() >= 2:
				blocks_to_destroy.append_array(match_group)
			match_group = [current_block]

	if match_group.size() >= 2:
		blocks_to_destroy.append_array(match_group)

	for block in blocks_to_destroy:
		if is_instance_valid(block):
			block.destroy()
