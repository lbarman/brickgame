extends Area2D

@export var slowdown_factor: float = 0.5
@export var slowdown_speed: float = 20.0
@export var speedup_speed: float = 20.0


var _target_time_scale: float = 1.0


func _ready():
	_target_time_scale = Engine.time_scale

func _process(delta: float):
	if Engine.time_scale > _target_time_scale:
		Engine.time_scale = lerp(Engine.time_scale, _target_time_scale, slowdown_speed * delta)
	else:
		Engine.time_scale = lerp(Engine.time_scale, _target_time_scale, speedup_speed * delta)


func _on_body_entered(body):
	print("Body entered ", body)
	if body.is_in_group("ball"):
		print("Ball entered")
		_target_time_scale = slowdown_factor


func _on_body_exited(body):
	if body.is_in_group("ball"):
		_target_time_scale = 1.0
