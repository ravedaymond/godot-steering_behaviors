class_name Quarry
extends Boid


func _init():
	if(behavior != Behavior.STATIC):
		add_to_group(Global.Groups.QUARRY)

