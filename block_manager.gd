extends Node2D
class_name BlockManager

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
			label.text = "Score: "+str(s)

var color_palette = [
	Color("d90429"), # Paradise Pink
	Color("f94144"), # Imperial Red
	Color("f9844a"), # Mango Tango
	Color("f9c74f"), # Saffron
	Color("90be6d"), # Pistachio
	Color("43aa8b"), # Zomp
	Color("4d908e"), # Queen Blue
	Color("577590"), # Payne's Gray
]

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
	var prev_color = Color.WHEAT
	var row_id = next_row_id
	next_row_id += 1
	for col in range(num_columns):
		var x_pos = spawn_x + col * (block_size.x + horizontal_spacing)
		var block = spawn_block(next_row_id, col, Vector2(x_pos, y_pos), prev_color)
		prev_color = block.color
	
func spawn_block(row_id: int, col_id: int, pos: Vector2, prev_color: Color) -> BlockTemplate:
	var block: BlockTemplate = blockTemplate.instantiate()
	block.position = pos
	block.color = color_palette.pick_random()
	var color: Color
	var available_colors = color_palette.filter(func(c): return c != prev_color)
	if not available_colors.is_empty():
		color = available_colors.pick_random()
	else:
		color = color_palette[0]
	block.color = color
	block.row_id = row_id
	block.col_id = col_id
	block.block_manager = self
	add_child(block)
	blocks.append(block)
	return block

func delete_same_color_adjacent_blocks(row):
	var blocks_this_row: Array[BlockTemplate] = []
	for block in blocks:
		if is_instance_valid(block) and !block.is_being_deleted && block.row_id == row:
			blocks_this_row.append(block)
				
	blocks_this_row.sort_custom(sort_by_col)
	
	var to_destroy = {} # use key set only
	for i in range(blocks_this_row.size()-1):
		if blocks_this_row[i].color == blocks_this_row[i+1].color:
			to_destroy[i] = blocks_this_row[i]
			to_destroy[i+1] = blocks_this_row[i+1]
	
	for k in to_destroy:
		to_destroy[k].destroy()
		

static func sort_by_col(a, b):
	return a.col_id < b.col_id
