class_name Beacon
extends Node2D


enum Type { NEUTRAL, ATTRACTOR, DETRACTOR, }
const Colors = {
	Type.NEUTRAL: Color.GRAY,
	Type.ATTRACTOR: Color.ROYAL_BLUE,
}



@export var size: float = 6.0
var type: Type


func _init():
	add_to_group(Main.Groups.BEACONS)


func _ready():
	$CollisionShape2D.shape.radius = size


func _process(_delta):
	queue_redraw()


func _draw():
#	draw_line(Vector2(), get_local_mouse_position(), Color.GREEN, 1.0, false)
	draw_arc(Vector2(), size, 0, 360, 12, Colors.get(type), 2.0, false)

