extends Area2D


func _init():
	name = "ObstacleAvoidanceArea"


func _ready():
	body_entered.connect(get_parent()._on_obstacle_avoidance_area_body_entered)
	body_exited.connect(get_parent()._on_obstacle_avoidance_area_body_exited)


func _physics_process(_delta):
	global_position = get_parent().global_position + Vector2.from_angle(get_parent().rotation) * $CollisionShape2D.shape.size.x/2
