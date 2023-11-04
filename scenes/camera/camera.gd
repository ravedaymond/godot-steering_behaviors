class_name Camera
extends Camera2D


@export var camera_move_speed: float = 5.0
@export var camera_move_smoothing: float = 0.05
@export var camera_zoom_increment: float  = 1.0
@export var camera_zoom_min: float  = 1.0
@export var camera_zoom_max: float  = 5.0
var camera_move_position: Vector2
var camera_move_velocity: Vector2
var follow_targets: Array[Node2D] = []
var follow_target: Node2D


func _init():
	if(Main.CAMERA):
		Main.CAMERA.queue_free()
	Main.CAMERA = self


func _process(delta):
	camera_zoom()
	camera_rotate()
	if(follow_target):
		camera_follow()
	else:
		camera_free()
	# Cursor Control
	var frame_mouse_position = get_global_mouse_position()
	$Area2D.global_position = frame_mouse_position
	# Left mouse button input with modifiers
	if(Input.is_action_just_pressed("mouse_left_shift")):
		Main.create_beacon(frame_mouse_position, Beacon.Type.ATTRACTOR)
	elif(Input.is_action_just_pressed("mouse_left_ctrl")):
		Main.create_beacon(frame_mouse_position, Beacon.Type.NEUTRAL)
	elif(Input.is_action_just_pressed("mouse_left_alt")):
		Main.create_beacon(frame_mouse_position, Beacon.Type.DETRACTOR)
	elif(Input.is_action_just_pressed("mouse_left")):
		if(follow_targets.size() > 1):
			sort_follow_targets()
		if(follow_targets.size() > 0):
			for i in follow_targets:
				if(!(i is Beacon)):
					follow_target = i
		elif(follow_target):
			camera_move_position = follow_target.position
			follow_target = null
	# Right mouse button input with modifiers
	if(Input.is_action_just_pressed("mouse_right_shift")):
		Main.create_quarry(frame_mouse_position)
		pass
	elif(Input.is_action_just_pressed("mouse_right_ctrl")):
		pass
	elif(Input.is_action_just_pressed("mouse_right_alt")):
		pass
	elif(Input.is_action_just_pressed("mouse_right")):
		if(follow_targets.size() > 1):
			sort_follow_targets()
		if(follow_targets.size() > 0):
			if(follow_target == follow_targets[0]):
				camera_move_position = follow_target.position
				follow_target = null
			print_debug(follow_targets)
			follow_targets[0].queue_free()
	# Middle mouse button input with modifiers
	if(Input.is_action_just_pressed("mouse_middle_shift")):
		pass
	elif(Input.is_action_just_pressed("mouse_middle_ctrl")):
		pass
	elif(Input.is_action_just_pressed("mouse_middle_alt")):
		pass
	elif(Input.is_action_just_pressed("mouse_middle")):
		Main.create_boid(frame_mouse_position)
		pass


func _on_area_2d_body_entered(body):
	if((body is Boid) || (body is Quarry) || (body is Beacon)):
		follow_targets.append(body)


func _on_area_2d_body_exited(body):
	if((body is Boid) || (body is Quarry) || (body is Beacon)):
		follow_targets.erase(body)


func camera_free():
	camera_move_velocity.x = Input.get_action_strength("camera_move_right") - Input.get_action_strength("camera_move_left")
	camera_move_velocity.y = Input.get_action_strength("camera_move_down") - Input.get_action_strength("camera_move_up")
	camera_move_position += camera_move_velocity.normalized() * camera_move_speed
	position = position.lerp(camera_move_position, camera_move_smoothing)


func camera_follow():
	position = position.lerp(follow_target.position, camera_move_smoothing)


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

