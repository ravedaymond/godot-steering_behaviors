class_name Boid
extends CharacterBody2D


enum Behavior { 
	STATIC=0,
	SEEK,
	FLEE,
	PURSUE,
	EVADE,
	ARRIVAL,
	PURSUE_OFFSET,
	OBSTACLE_AVOIDANCE,
	WANDER,
	PATH_FOLLOWING,
	WALL_FOLLOWING,
	CONTAINMENT,
	FLOW_FIELD,
}

enum Type {
	NEUTRAL,
	PASSIVE,
	AGGRESSIVE,
	DEFENSIVE,
}

@export var use_mouse_as_target: bool = false
@export var use_intervals: bool = false
@export var velocity_speed: float = 0.0
@export var velocity_speed_max: float = 50.0
@export var velocity_acceleration: float = 1.0
var velocity_desired: Vector2
@export var steering_force: float = 0.0
@export var steering_force_max: float = 2.0
@export var steering_intensity: float = 0.01
var steering_vector: Vector2
var velocity_modifier: Vector2

@export var pursue_future_multiplier: float = 10.0
@export var evade_future_multiplier: float = 10.0
var pursue_vector: Vector2
var evade_vector: Vector2
@export var arrival_slowing_distance: float = 50.0
var arrival_distance_vector: Vector2
var arrival_distance_length: float
var arrival_ramped_speed: float
var arrival_clipped_speed: float

var target: Variant
var type: Type
@export var behavior: Behavior = Behavior.STATIC

func _init():
	add_to_group(Main.Groups.BOIDS)


# Called when the node enters the scene tree for the first time.
func _ready():
	if(!use_intervals):
		velocity_speed = velocity_speed_max
		steering_force = steering_force_max
	if(behavior == Behavior.STATIC):
		var x = randf()*sign(randi_range(-1, 1))
		var y = randf()*sign(randi_range(-1, 1))
		velocity = Vector2(x, y).normalized()*velocity_speed_max


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	$AnimatedSprite2D.animation = str(behavior)


func _physics_process(_delta):
	if(use_intervals):
		velocity_speed = clampf(velocity_speed+velocity_acceleration, 0, velocity_speed_max)
		steering_force = clampf(steering_force+steering_intensity, 0, steering_force_max)
	decide_on_target()
	
	match(behavior):
		Behavior.SEEK:
			velocity_modifier += behavior_seek(target.global_position)
		Behavior.FLEE:
			velocity_modifier += behavior_flee(target.global_position)
		Behavior.PURSUE:
			velocity_modifier += behavior_pursue(target, pursue_future_multiplier)
		Behavior.EVADE:
			velocity_modifier += behavior_evade(target, pursue_future_multiplier)
		Behavior.ARRIVAL:
			velocity_modifier += behavior_arrival(target.global_position)
		_:
			behavior = Behavior.STATIC
	
	velocity = velocity + velocity_modifier
	move_and_slide()
	velocity_modifier = Vector2.ZERO
	
	queue_redraw()
	# Rotate with velocity direction
	rotation = position.angle_to_point(position+velocity) + (PI / 2)
	debug_labels(rotation)


func _draw():
	if(target):
		draw_line(Vector2.ZERO, to_local(target.global_position), Color.DIM_GRAY, 1.0, false)
		if(pursue_vector != Vector2.ZERO):
			draw_line(Vector2.ZERO, to_local(pursue_vector), Color.DIM_GRAY, 1.0, false)
		if(evade_vector != Vector2.ZERO):
			draw_line(Vector2.ZERO, to_local(evade_vector), Color.DIM_GRAY, 1.0, false)
	draw_set_transform(Vector2.ZERO, -rotation)
	draw_line(velocity, velocity_desired, Color.DIM_GRAY, 1.0, false)
	draw_line(Vector2.ZERO, velocity_desired, Color.RED, 1.0, false)
	draw_line(velocity, velocity+steering_vector, Color.MEDIUM_BLUE, 1.0, false)
	draw_line(Vector2.ZERO, velocity, Color.DARK_GREEN, 1.0, false)


func debug_labels(rotation: float):
	$VectorLabels.rotation = -rotation
#	$Velocity.global_position = global_position
	$VectorLabels/Velocity.text = "V"+str(velocity)
#	$Desired.global_position = global_position+velocity_desired
	$VectorLabels/Desired.text = "D"+str(velocity_desired)
#	$Steering.global_position = global_position+velocity
	$VectorLabels/Steering.text = "S"+str(steering_vector)


func decide_on_target():
	if(!is_instance_valid(target)):
		target = Node2D.new()
		target.global_position = global_position
	if(use_mouse_as_target):
		target = Node2D.new()
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
func behavior_seek(target: Vector2) -> Vector2:
	if(behavior != Behavior.PURSUE): 
		behavior = Behavior.SEEK
	velocity_desired = (target - position).normalized()*velocity_speed
	steering_vector = (velocity_desired - velocity).limit_length(steering_force)
	return steering_vector


# Apply steering force towards a direct path away from the target.
func behavior_flee(target: Vector2) -> Vector2:
	if(behavior != Behavior.EVADE): 
		behavior = Behavior.FLEE
	velocity_desired = (position - target).limit_length(velocity_speed)
	steering_vector = (velocity_desired - velocity).limit_length(steering_force)
	return steering_vector


# Apply steering force towards a direct path to the target, similar to seek.
# Upon approaching target, the set `arrival_slowing_distance` will begin to
#	slow the arriving object by linearly clipping the objects speed value once
#	inside the slowing radius.
func behavior_arrival(target: Vector2) -> Vector2:
	behavior = Behavior.ARRIVAL
	arrival_distance_vector = target - position
	arrival_distance_length = arrival_distance_vector.length()
	arrival_ramped_speed = velocity_speed * (arrival_distance_length / arrival_slowing_distance)
	arrival_clipped_speed = min(arrival_ramped_speed, velocity_speed)
	velocity_desired = (arrival_clipped_speed / arrival_distance_length) * arrival_distance_vector
	steering_vector = (velocity_desired - velocity).limit_length(steering_force)
	return steering_vector


# Apply steering force towards a calculated future position of the target.
# Calculates future position of a target based on the targets given position and
#	velocity. Once calculated, call seek.
func behavior_pursue(target: Object, pursue_future_multiplier: float) -> Vector2:
	behavior = Behavior.PURSUE
	pursue_vector = Vector2.ZERO
	if(is_instance_valid(target)):
		if("velocity" in target):
			pursue_vector = Vector2(target.velocity)
		pursue_vector*pursue_future_multiplier
		pursue_vector += target.global_position
	return behavior_seek(pursue_vector)


# Apply steering force away from a calculated future position of the target.
# Calculates future position of a target based on the targets given position and
#	velocity. Once calculated, call flee.
func behavior_evade(target: Object, evade_future_multiplier) -> Vector2:
	behavior = Behavior.EVADE
	evade_vector = Vector2.ZERO
	if(is_instance_valid(target)):
		if("velocity" in target):
			evade_vector = Vector2(target.velocity)
		evade_vector*evade_future_multiplier
		evade_vector += target.global_position
	return behavior_flee(evade_vector)


func behavior_pursue_offset() -> Vector2:
	return steering_vector


func behavior_obstacle_avoidance() -> Vector2:
	return steering_vector


func behavior_wander() -> Vector2:
	return steering_vector


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
