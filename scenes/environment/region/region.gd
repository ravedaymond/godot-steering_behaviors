class_name Region
extends Area2D

@export var region_border_size: int = 5
@export var region_border_color: Color = Color.BLACK

var groups: Dictionary = {}
var corners: Array = []
var mouse_in_region: bool = false

var seek = true

func _init():
	for i in Global.Groups:
		groups[Global.Groups.get(i)] = []


# Called when the node enters the scene tree for the first time.
func _ready():
	# Create node groups
	for group in Global.Groups:
		var node_name = Global.Groups.get(group)
		if(!get_node(node_name)):
			var node = Node2D.new()
			node.name = node_name
			add_child(node)
	$CollisionShape2D.visible = false
	var size = $CollisionShape2D.shape.size
	size = Vector2(size.x*0.5, size.y*0.5)
	var offset = region_border_size * 0.5
	# Set corners in order of last to first (clockwise): BL, BR, TR, TL
	corners.append(Vector2(global_position.x-(size.x)-offset, global_position.y-(size.y)-offset))
	corners.append(Vector2(global_position.x+(size.x)+offset, global_position.y-(size.y)-offset))
	corners.append(Vector2(global_position.x+(size.x)+offset, global_position.y+(size.y)+offset))
	corners.append(Vector2(global_position.x-(size.x)-offset, global_position.y+(size.y)+offset))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _physics_process(_delta):
	queue_redraw()


func _draw():
	draw_line(to_local(corners[0]), to_local(corners[1]), region_border_color, region_border_size, false)
	draw_line(to_local(corners[1]), to_local(corners[2]), region_border_color, region_border_size, false)
	draw_line(to_local(corners[2]), to_local(corners[3]), region_border_color, region_border_size, false)
	draw_line(to_local(corners[3]), to_local(corners[0]), region_border_color, region_border_size, false)


func _on_body_entered(body):
	if(body.region): return
	if(body is Quarry):
		groups[Global.Groups.QUARRY].append(body)
		body.region = self
	elif(body is Boid):
		groups[Global.Groups.BOIDS].append(body)
		body.region = self
	elif(body is Obstacle):
		groups[Global.Groups.OBSTACLES].append(body)


func _on_body_exited(body):
	if(body is Boid && body.region == self):
		var gp = body.global_position
		var wrap_x_min = corners[0].x
		var wrap_y_min = corners[0].y
		var wrap_x_max = corners[2].x
		var wrap_y_max = corners[2].y
		body.global_position = Vector2(wrapf(gp.x, wrap_x_min, wrap_x_max), wrapf(gp.y, wrap_y_min, wrap_y_max))


func _on_area_entered(area):
	if(area is Station):
		groups[Global.Groups.STATIONS].append(area)
		area.region = self


func _on_mouse_entered():
	mouse_in_region = true
	Global.CAMERA.get_node("Area2D").visible = true


func _on_mouse_exited():
	mouse_in_region = false
	Global.CAMERA.get_node("Area2D").visible = false
