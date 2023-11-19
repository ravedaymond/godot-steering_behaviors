class_name Obstacle
extends Node2D


enum Size {
	TINY,
	SMALL,
	MEDIUM,
	LARGE,
}

@export var size: Size = Size.MEDIUM
var sprite
var region: Area2D

func _init():
	match(size):
		Size.TINY:
			sprite = load("res://scenes/environment/obstacle/obstacle_tiny.png")
		Size.SMALL:
			sprite = load("res://scenes/environment/obstacle/obstacle_small.png")
		Size.MEDIUM:
			sprite = load("res://scenes/environment/obstacle/obstacle_medium.png")
		Size.LARGE:
			sprite = load("res://scenes/environment/obstacle/obstacle_large.png")


func _ready():
	$Sprite2D.texture = sprite
	$CollisionShape2D.shape.radius = $Sprite2D.texture.get_width() * 0.5


func _process(delta):
	pass
