class_name Station
extends Area2D

enum StationColor {
	WHITE,
	WHITE_BLACK,
	BLACK,
	YELLOW,
	GREEN,
	BLUE,
	PURPLE,
	RED,
	ORANGE,
	YELLOW_BLACK,
	GREEN_BLACK,
	BLUE_BLACK,
	PURPLE_BLACK,
	RED_BLACK,
	ORANGE_BLACK,
}

@export var station_color: StationColor = StationColor.WHITE

var region: Area2D

func _ready():
	$CollisionShape2D.visible = false
	$AnimatedSprite2D.animation = str(station_color)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
