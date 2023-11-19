class_name Camera
extends Camera2D

signal signal_toggle_seek_flee
signal signal_toggle_pursuit_evasion

@export var camera_move_speed: float = 5.0
@export var camera_move_smoothing: float = 0.05
@export var camera_zoom_increment: float  = 0.1
@export var camera_zoom_min: float  = 1.0
@export var camera_zoom_max: float  = 5.0
var camera_zoom_def: float = 1.2
var camera_move_position: Vector2
var camera_move_velocity: Vector2
var follow_targets: Array[Node2D] = []
var follow_target: Node2D

var input_callable: Callable

func _init():
	if(is_instance_valid(Global.CAMERA)):
		Global.CAMERA.queue_free()
	Global.CAMERA = self
	zoom = Vector2(camera_zoom_def, camera_zoom_def)


func _ready():
	for i in Global.Demos:
		if(i == get_parent().name):
			input_callable = Callable(self, "input_"+str(i))
	if(!input_callable):
		input_callable = Callable(self, "input_sandbox")


func _process(_delta):
	var frame_mouse_position = get_global_mouse_position()
	$Area2D.global_position = frame_mouse_position
	
	input_callable.call(frame_mouse_position)
	if(Input.is_action_just_pressed("mouse_left")):
		if(follow_targets.size() > 1):
			sort_follow_targets()
		if(follow_targets.size() > 0):
			for i in follow_targets:
				follow_target = i
		elif(follow_target):
			follow_target = null


func _physics_process(_delta):
	camera_zoom()
	camera_rotate()
	if(follow_target):
		camera_follow()
	else:
		camera_free()


func _on_area_2d_body_entered(body):
	if((body is Boid) || (body is Quarry)):
		follow_targets.append(body)


func _on_area_2d_body_exited(body):
	if((body is Boid) || (body is Quarry)):
		follow_targets.erase(body)


func camera_free():
	camera_move_velocity.x = Input.get_action_strength("camera_move_right") - Input.get_action_strength("camera_move_left")
	camera_move_velocity.y = Input.get_action_strength("camera_move_down") - Input.get_action_strength("camera_move_up")
	camera_move_position += camera_move_velocity.normalized() * camera_move_speed
	global_position = global_position.lerp(camera_move_position, camera_move_smoothing)


func camera_follow():
	camera_move_position = follow_target.global_position
	global_position = global_position.lerp(camera_move_position, camera_move_smoothing)


func camera_zoom():
	var dir = int(Input.is_action_just_released("camera_zoom_in")) - int(Input.is_action_just_released("camera_zoom_out"))
	if(dir != 0):
		zoom.x = clamp(zoom.x + (camera_zoom_increment * dir), camera_zoom_min, camera_zoom_max)
		zoom.y = clamp(zoom.y + (camera_zoom_increment * dir), camera_zoom_min, camera_zoom_max)
		align()


func camera_rotate():
	var dir = int(Input.get_action_strength("camera_rotate_right") - Input.get_action_strength("camera_rotate_left"))
	rotation = lerpf(rotation, rotation+(0.1*dir), camera_move_smoothing)
	if(Input.is_action_just_pressed("camera_reset")):
		rotation = 0.0
		if(!follow_target):
			camera_move_position = Vector2.ZERO


func sort_follow_targets():
	if(follow_targets.size() < 2): return
	for i in range(follow_targets.size()-1):
		var curr = follow_targets[i]
		var next = follow_targets[i+1]
		var curr_dis = abs(($Area2D.global_position - curr.global_position).length())
		var next_dis = abs(($Area2D.global_position - next.global_position).length())
		if(next_dis < curr_dis):
			follow_targets[i] = next
			follow_targets[i+1] = curr


func input_demo_seek_flee(frame_mouse_position: Vector2):
	if(Input.is_action_just_pressed("spacebar")):
		emit_signal("signal_toggle_seek_flee")


func input_demo_pursuit_evasion(frame_mouse_position: Vector2):
	if(Input.is_action_just_pressed("spacebar")):
		emit_signal("signal_toggle_pursuit_evasion")


func input_demo_offset_pursuit(frame_mouse_position: Vector2):
	pass


func input_demo_arrival(frame_mouse_position: Vector2):
	pass


func input_demo_wander(frame_mouse_position: Vector2):
	pass


func input_sandbox(frame_mouse_position: Vector2):
	pass
