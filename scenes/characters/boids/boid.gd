class_name Boid
extends CharacterBody2D


enum Behavior { 
	STATIC=0,
	SEEK,
	FLEE,
	PURSUIT,
	EVASION,
	PURSUIT_OFFSET,
	ARRIVAL,
	OBSTACLE_AVOIDANCE,
	WANDER_RANDOM,
	WANDER_REYNOLDS,
	WANDER_EXPLORRE,
	WANDER_FORAGE,
	PATH_FOLLOWING,
	WALL_FOLLOWING,
	CONTAINMENT,
	FLOW_FIELD,
}

enum ObstacleAvoidance {
	NONE,
	AREA2D,
	RAYCAST,
}

enum Type {
	NEUTRAL,
	PASSIVE,
	AGGRESSIVE,
	DEFENSIVE,
}

@export var behavior: Behavior = Behavior.STATIC
@export var obstacle_avoidance: ObstacleAvoidance = ObstacleAvoidance.NONE
@export var use_mouse_as_target: bool = false
@export var use_intervals: bool = false
@export var velocity_speed: float = 0.0
@export var velocity_speed_max: float = 50.0
@export var velocity_acceleration: float = 0.1
var velocity_desired: Vector2 = Vector2.ZERO
var velocity_steered: Vector2 = Vector2.ZERO
@export var steering_force: float = 0.0
@export var steering_force_max: float = 2.0
@export var steering_intensity: float = 0.01
var steering_vector: Vector2 = Vector2.ZERO
@export_subgroup("Pursue", "pursue_")
@export var pursuit_future_multiplier: float = 1.0
@export var pursuit_offset: float = 1
var pursuit_vector: Vector2 = Vector2.ZERO
var pursuit_vector_offset: Vector2 = Vector2.ZERO
@export_subgroup("Evade", "evade_")
@export var evasion_future_multiplier: float = 1.0
var evasion_vector: Vector2 = Vector2.ZERO
@export_subgroup("Arrival", "arrival_")
@export var arrival_slowing_distance: float = 50.0
var arrival_distance_vector: Vector2 = Vector2.ZERO
var arrival_distance_length: float
var arrival_ramped_speed: float
var arrival_clipped_speed: float
@export_subgroup("Obstacle Avoidance", "avoidance_")
var avoidance_area: Area2D
var avoidance_target: CollisionObject2D
var avoidance_left_position: Vector2 = Vector2.ZERO
var avoidance_right_position: Vector2 = Vector2.ZERO
var avoidance_left_vector: Vector2
var avoidance_right_vector: Vector2
var avoidance_center_vector: Vector2
var avoidance_area_multiplier: float = 4.0
var avoidance_magnitude: float
var avoidance_angle: Vector2
@export_subgroup("Wander", "wander_")
@export var wander_interval: float = 0.20
@export var wander_distance: float = 50.0
@export var wander_strength: float = 20.0
@export var wander_displacement: float = 15
var wander_angle: float = 0.0
var wander_area: Vector2 = Vector2.ZERO
var wander_target: Vector2 = Vector2.ZERO
var wander_timer: Timer = add_wander_timer()
@export_subgroup("Debugging", "debug_")
@export var debug_enabled: bool = true
@export var debug_draw_vectors: bool = true
@export var debug_draw_labels: bool = false

var target: Node2D
var type: Type

func _init():
	add_to_group(Main.Groups.BOIDS)


# Called when the node enters the scene tree for the first time.
func _ready():
	if(!use_intervals):
		velocity_speed = velocity_speed_max
		steering_force = steering_force_max
	if(behavior == Behavior.STATIC):
#		var x = randf()*sign(randi_range(-1, 1))
#		var y = randf()*sign(randi_range(-1, 1))
#		velocity = Vector2(x, y).normalized()*velocity_speed_max
		pass
	elif(behavior == Behavior.OBSTACLE_AVOIDANCE):
		velocity = Vector2(50, 0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	$AnimatedSprite2D.animation = str(behavior)


func _physics_process(_delta):
	if(use_intervals && behavior != Behavior.STATIC):
		velocity_speed = clampf(velocity_speed+velocity_acceleration, 0, velocity_speed_max)
		steering_force = clampf(steering_force+steering_intensity, 0, steering_force_max)
	decide_on_target()
	match(behavior):
		Behavior.SEEK:
			velocity_steered += behavior_seek(target.global_position)
		Behavior.FLEE:
			velocity_steered += behavior_flee(target.global_position)
		Behavior.PURSUIT:
			velocity_steered += behavior_pursuit(target, pursuit_future_multiplier)
		Behavior.PURSUIT_OFFSET:
			velocity_steered += behavior_pursuit_offset(target, pursuit_future_multiplier, pursuit_offset)
		Behavior.EVASION:
			velocity_steered += behavior_evasion(target, pursuit_future_multiplier)
		Behavior.ARRIVAL:
			velocity_steered += behavior_arrival(target.global_position)
		Behavior.OBSTACLE_AVOIDANCE:
			if(obstacle_avoidance == ObstacleAvoidance.AREA2D):
				velocity_steered += behavior_obstacle_avoidance_area2d()
			if(obstacle_avoidance == ObstacleAvoidance.RAYCAST):
				velocity_steered += behavior_obstacle_avoidance_raycast()
		Behavior.WANDER_RANDOM:
			if(!find_child(wander_timer.name, false, false)):
				add_child(wander_timer)
			velocity_steered += behavior_wander_random(wander_interval)
		Behavior.WANDER_REYNOLDS:
			if(!find_child(wander_timer.name, false, false)):
				add_child(wander_timer)
			velocity_steered += behavior_wander_reynolds(wander_interval)
		_:
			behavior = Behavior.STATIC
	velocity += velocity_steered
	move_and_slide()
	velocity_steered = Vector2.ZERO
	
	queue_redraw()
	# Rotate with velocity direction
	rotation = position.angle_to_point(position+velocity)
#	rotation = position.angle_to_point(get_global_mouse_position())
	debug_labels(rotation)


func _draw():
	if(!debug_draw_vectors): return
	if(behavior in [Behavior.SEEK, Behavior.FLEE, Behavior.PURSUIT, Behavior.PURSUIT_OFFSET, Behavior.EVASION, Behavior.ARRIVAL, Behavior.WANDER_RANDOM, Behavior.OBSTACLE_AVOIDANCE, ]):
		if(target):
			if(behavior == Behavior.PURSUIT):
				draw_line(Vector2.ZERO, to_local(pursuit_vector), Color.DIM_GRAY, 1.0, false)
			if(behavior == Behavior.EVASION):
				draw_line(Vector2.ZERO, to_local(evasion_vector), Color.DIM_GRAY, 1.0, false)
			if(behavior == Behavior.PURSUIT_OFFSET):
				draw_line(to_local(pursuit_vector), to_local(pursuit_vector_offset), Color.DIM_GRAY, 1.0, false)
				draw_line(Vector2.ZERO, to_local(pursuit_vector_offset), Color.DIM_GRAY, 1.0, false)
			if(obstacle_avoidance == ObstacleAvoidance.AREA2D):
				if(avoidance_target):
					draw_line(Vector2.ZERO, to_local(avoidance_target.global_position), Color.DIM_GRAY, 1.0, false)
			else:
				draw_line(Vector2.ZERO, to_local(target.global_position), Color.DIM_GRAY, 1.0, false)
		draw_line(velocity.rotated(-rotation), velocity_desired.rotated(-rotation), Color.DIM_GRAY, 1.0, false)
		draw_line(Vector2.ZERO, velocity_desired.rotated(-rotation), Color.RED, 1.0, false)
		draw_line(velocity.rotated(-rotation), (velocity+steering_vector).rotated(-rotation), Color.MEDIUM_BLUE, 1.0, false)
		draw_line(Vector2.ZERO, velocity.rotated(-rotation), Color.DARK_GREEN, 1.0, false)
	elif(obstacle_avoidance in [ObstacleAvoidance.RAYCAST, ]):
		draw_arc(to_local(avoidance_left_position), 1, 0, 360, 25, Color.DIM_GRAY, 1.0, false)
		draw_arc(to_local(avoidance_right_position), 1, 0, 360, 25, Color.DIM_GRAY, 1.0, false)
		draw_arc(to_local(avoidance_left_vector), 1, 0, 360, 25, Color.DIM_GRAY, 1.0, false)
		draw_arc(to_local(avoidance_right_vector), 1, 0, 360, 25, Color.DIM_GRAY, 1.0, false)
		draw_arc(to_local(avoidance_center_vector), 1, 0, 360, 25, Color.DIM_GRAY, 1.0, false)
		draw_line(to_local(avoidance_left_position), to_local(avoidance_left_vector), Color.DIM_GRAY, 1.0, false)
		draw_line(to_local(avoidance_right_position), to_local(avoidance_right_vector), Color.DIM_GRAY, 1.0, false)
		draw_line(to_local(global_position), to_local(avoidance_center_vector), Color.DIM_GRAY, 1.0, false)
		draw_line(Vector2.ZERO, velocity.rotated(-rotation), Color.DIM_GRAY, 1.0, false)
	elif(behavior in [Behavior.WANDER_REYNOLDS, ]):
		draw_circle(to_local(wander_area), wander_strength, Color.DIM_GRAY)
		draw_line(Vector2.ZERO, to_local(wander_target), Color.RED, 1.0, false)
		draw_line(to_local(wander_area), to_local(wander_target), Color.RED, 1.0, false)
		draw_arc(to_local(wander_target), 1, 0, 360, 25, Color.RED, 1.0, false)
		draw_line(velocity.rotated(-rotation), velocity_desired.rotated(-rotation), Color.DIM_GRAY, 1.0, false)
#		draw_line(Vector2.ZERO, velocity_desired.rotated(-rotation), Color.RED, 1.0, false)
		draw_line(velocity.rotated(rotation), (velocity+steering_vector).rotated(-rotation), Color.MEDIUM_BLUE, 1.0, false)
		draw_line(Vector2.ZERO, velocity.rotated(rotation), Color.DARK_GREEN, 1.0, false)



func debug_labels(rotval: float):
	if(debug_draw_labels):
		$VectorLabels.rotation = -rotval
	#	$Velocity.global_position = global_position
		$VectorLabels/Velocity.text = "V"+str(velocity)
	#	$Desired.global_position = global_position+velocity_desired
		$VectorLabels/Desired.text = "D"+str(velocity_desired)
	#	$Steering.global_position = global_position+velocity
		$VectorLabels/Steering.text = "S"+str(steering_vector)
	else:
		$VectorLabels/Velocity.text = ""
		$VectorLabels/Desired.text = ""
		$VectorLabels/Steering.text = ""


func decide_on_target():
	if(!is_instance_valid(target)):
		target = Node2D.new()
		target.global_position = global_position
	if(behavior == Behavior.WANDER_RANDOM || behavior == Behavior.WANDER_REYNOLDS): return
	if(use_mouse_as_target):
		target.global_position = get_global_mouse_position()
		return
	var group = Main.LEVEL.get_node(Main.Groups.QUARRY)
	if(group.get_child_count() > 0):
		target = group.get_child(0)
		return
	group = Main.LEVEL.get_node(Main.Groups.BEACONS)
	if(group.get_child_count() > 0):
		for i in group.get_children():
			if i.type == Beacon.Type.ATTRACTOR:
				target = i
				return


# Apply steering force towards a direct path to the target.
#	Once target has been reached, it will turn around at a given point
#	that is equal to the vector + speed at which it reached the target.
#	It will then bounce between +/-(vector+speed) points.
#	Note: This bouncing state will only begin if the steering vector
#	was lined up with the desired velocity.
# Does not handle collision detection and can cause physic wonkyness when
#	bumping into other moving objects.
func behavior_seek(seek_position: Vector2) -> Vector2:
	velocity_desired = (seek_position - global_position).normalized()*velocity_speed
	steering_vector = (velocity_desired - velocity).limit_length(steering_force)
	return steering_vector


# Apply steering force towards a direct path away from the target.
func behavior_flee(flee_position: Vector2) -> Vector2:
	velocity_desired = (global_position - flee_position).limit_length(velocity_speed)
	steering_vector = (velocity_desired - velocity).limit_length(steering_force)
	return steering_vector


# Apply steering force towards a calculated future position of the target.
# Calculates future position of a target based on the targets given position and
#	velocity. Once calculated, call seek.
func behavior_pursuit(pursuit_target: Object, pursuit_future_multiplier: float) -> Vector2:
	pursuit_vector = Vector2.ZERO
	if(is_instance_valid(pursuit_target)):
		if("velocity" in pursuit_target):
			pursuit_vector = Vector2(pursuit_target.velocity)
		pursuit_vector *= pursuit_future_multiplier
		pursuit_vector += pursuit_target.global_position
	return behavior_seek(pursuit_vector)


# Apply steering force away from a calculated future position of the target.
# Calculates future position of a target based on the targets given position and
#	velocity. Once calculated, call flee.
# TODO: Need to enhance to compare current distance. As it stands if the future point
#	goes past the evader, it will just turn and go towards the pursuer.
func behavior_evasion(evade_target: Object, evasion_future_multiplier) -> Vector2:
	evasion_vector = Vector2.ZERO
	if(is_instance_valid(evade_target)):
		if("velocity" in evade_target):
			evasion_vector = Vector2(evade_target.velocity)
		evasion_vector *= evasion_future_multiplier
		evasion_vector += evade_target.global_position
	return behavior_flee(evasion_vector)


# Apply steering force similar to pursuit, however offset the future vector target
#	based on a given offset amount.
# TODO: Check on some crossover with the vectors when the pursuit target is heading
#	directly towards the pursuer.
func behavior_pursuit_offset(pursuit_target: Object, pursuit_future_multiplier: float, pursuit_offset: float) -> Vector2:
	pursuit_vector = Vector2.ZERO
	if(is_instance_valid(pursuit_target)):
		if("velocity" in pursuit_target):
			pursuit_vector = Vector2(pursuit_target.velocity)
		pursuit_vector *= pursuit_future_multiplier
		pursuit_vector += pursuit_target.global_position
		var min_offset = $CollisionShape2D.shape.radius + pursuit_target.get_node("CollisionShape2D").shape.radius
		pursuit_offset = max(min_offset, pursuit_offset)
		if(sign(pursuit_vector.angle_to(pursuit_target.global_position)) > 0):
			pursuit_vector_offset = Vector2.from_angle(pursuit_target.rotation-(PI/2))*pursuit_offset
		else:
			pursuit_vector_offset = Vector2.from_angle(pursuit_target.rotation+(PI/2))*pursuit_offset
		pursuit_vector_offset += pursuit_vector
	return behavior_seek(pursuit_vector_offset)


# Apply steering force towards a direct path to the target, similar to seek.
# Upon approaching target, the set `arrival_slowing_distance` will begin to
#	slow the arriving object by linearly clipping the objects speed value once
#	inside the slowing radius.
func behavior_arrival(arrival_position: Vector2) -> Vector2:
	arrival_distance_vector = arrival_position - position
	arrival_distance_length = arrival_distance_vector.length()
	arrival_ramped_speed = velocity_speed * (arrival_distance_length / arrival_slowing_distance)
	arrival_clipped_speed = min(arrival_ramped_speed, velocity_speed)
	
	velocity_desired = (arrival_clipped_speed / arrival_distance_length) * arrival_distance_vector
	steering_vector = (velocity_desired - velocity).limit_length(steering_force)
	return steering_vector


func behavior_obstacle_avoidance_raycast() -> Vector2:
	# Calculate required vectors for raycast
	var avoidance_angle = Vector2.from_angle(rotation-deg_to_rad(90)) * $CollisionShape2D.shape.radius
	avoidance_left_position = global_position + avoidance_angle
	avoidance_right_position = global_position - avoidance_angle
	avoidance_magnitude = max($CollisionShape2D.shape.radius*4, velocity.length())
	avoidance_left_vector = avoidance_left_position + Vector2.from_angle(rotation) * avoidance_magnitude
	avoidance_right_vector = avoidance_right_position + Vector2.from_angle(rotation) * avoidance_magnitude
	avoidance_center_vector = global_position + Vector2.from_angle(rotation) * avoidance_magnitude
	
	# Ray cast collision query (use global coordinates)
	var space_state = get_world_2d().direct_space_state
	var center_query = PhysicsRayQueryParameters2D.create(global_position, avoidance_center_vector, collision_mask, [self])
	var center_result = space_state.intersect_ray(center_query)
	var left_query = PhysicsRayQueryParameters2D.create(avoidance_left_position, avoidance_left_vector, collision_mask, [self])
	var left_result = space_state.intersect_ray(left_query)
	var right_query = PhysicsRayQueryParameters2D.create(avoidance_right_position, avoidance_right_vector, collision_mask, [self])
	var right_result = space_state.intersect_ray(right_query)
	
	return steering_vector


func behavior_obstacle_avoidance_area2d() -> Vector2:
	if(!avoidance_area):
		var load = load("res://scenes/characters/shared/obstacle_avoidance_area.tscn")
		avoidance_area = load.instantiate() as Area2D
		add_child(avoidance_area)
		avoidance_angle = Vector2.from_angle(rotation-deg_to_rad(90)) * $CollisionShape2D.shape.radius
		avoidance_left_position = global_position + avoidance_angle
		avoidance_right_position = global_position - avoidance_angle
		avoidance_area.get_node("CollisionShape2D").shape.size.y = (avoidance_left_position - avoidance_right_position).length()
	avoidance_magnitude = max($CollisionShape2D.shape.radius * avoidance_area_multiplier, velocity.length())
	avoidance_area.get_node("CollisionShape2D").shape.size.x = avoidance_magnitude
	
	if(avoidance_target):
		velocity_desired = (global_position+velocity - avoidance_target.global_position).normalized() * velocity_speed
		steering_vector = (velocity_desired - velocity).limit_length(steering_force)
	else:
		steering_vector = Vector2.ZERO
	return steering_vector


func _on_obstacle_avoidance_area_body_entered(body) -> void:
	if(body == self): return
	if(avoidance_target):
		if(global_position.distance_to(body.global_position) < global_position.distance_to(avoidance_target.global_position)):
			avoidance_target = body
	else:
		avoidance_target = body


func _on_obstacle_avoidance_area_body_exited(body) -> void:
	if(body == self): return
	if(body == avoidance_target):
		avoidance_target = null


func behavior_wander_random(wander_interval: float) -> Vector2:
	if(wander_timer.is_stopped()):
		var x = randi_range(-wander_distance, wander_distance)
		var y = randi_range(-wander_distance, wander_distance)
		target.global_position = global_position+Vector2(x, y)
		wander_timer.start(wander_interval)
	return behavior_seek(target.global_position)


func behavior_wander_reynolds(wander_interval: float) -> Vector2:
	wander_area = position+velocity.normalized()*wander_distance
#	wander_target = wander_area+Vector2.from_angle(clamp(rotation+wander_angle, deg_to_rad(-wander_displacement), deg_to_rad(wander_displacement)))*wander_strength
	wander_target = wander_area + Vector2.from_angle(rotation + wander_angle) * wander_strength
	if(wander_timer.is_stopped() || wander_interval == 0):
		wander_angle = randf_range(-wander_displacement, wander_displacement)
		wander_timer.start(wander_interval)
	velocity_desired = (wander_target - position).normalized() * velocity_speed
	steering_vector = (velocity_desired - velocity).limit_length(steering_force)
	return steering_vector
	

func add_wander_timer() -> Timer:
	var timer = Timer.new()
	timer.name = "WanderTimer"
	timer.one_shot = true
	return timer


func path_following() -> Vector2:
	return steering_vector


func behavior_wall_following() -> Vector2:
	return steering_vector


func behavior_containment() -> Vector2:
	return steering_vector


func behavior_flow_field() -> Vector2:
	return steering_vector

########################################
# ALTERNATIVES?
########################################


# Apply steering force towards the target and pass through before looping back once
#	the steering_vector has had enough time.
# I don't believe this is an intended behavior, but could be enhanced with simple distance
#	checks that increase force until turned around. eg:
#		if distance > n begin applying auxilary force until rotation of x degrees
#func behavior_seek_secondary(target: Vector2) -> Vector2:
#	velocity_desired = (target - position).limit_length(velocity_speed)
#	steering_vector = (velocity_desired - velocity).limit_length(steering_force)
#	return (velocity + steering_vector).normalized()*velocity_speed

# Seems to work similar to arrive without distance modifier. What is the slowdown
#	taking place?
#func behavior_seek_to_stop(target: Vector2) -> Vector2:
#	velocity_desired = (target - position).limit_length(velocity_max_speed)
#	steering_vector = (velocity_desired - velocity).limit_length(steering_max_force)
#	return velocity + steering_vector
