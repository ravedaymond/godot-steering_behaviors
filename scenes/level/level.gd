class_name Level
extends Node2D


@export var level_grid_color: Color = Color("#3d3d3d")
var boids: Array = []
var quarry: Array = []

@export var demo_level_info: Dictionary = {
	Static = false,
	Seek = false,
	Flee = false,
	Pursuit = false,
	Evasion = false,
	OffsetPursuit = false,
	Arrival = false,
}

#@onready var ui_context_create: CheckButton = $CanvasLayer/Control/Container/MarginContainer/VBoxContainer/HBoxContainer/ButtonCreate
#@onready var ui_context_delete: CheckButton = $CanvasLayer/Control/Container/MarginContainer/VBoxContainer/HBoxContainer/ButtonDelete
#@onready var ui_boids: VBoxContainer = $CanvasLayer/Control/Container/MarginContainer/VBoxContainer/ScrollContainerBoids/VBoxContainer
#@onready var ui_quarry: VBoxContainer = $CanvasLayer/Control/Container/MarginContainer/VBoxContainer/ScrollContainerQuarry/VBoxContainer
@export var level_background: Color = Color.TRANSPARENT
@export var draw_level_grid: bool = false

func _init():
	if(is_instance_valid(Global.LEVEL)):
		Global.LEVEL.queue_free()
	Global.LEVEL = self


func _ready():
	# Set level background color
	$CanvasLayer/ColorRect.color = level_background
	# Populate boids and quarry list
#	for i in get_node(Global.Groups.BOIDS).get_children():
#		var new_item = Global.UiItemFactory.instantiate()
#		new_item.name = str(i.get_instance_id())
#		var button = new_item.get_child(0) as Button
#		var label = new_item.get_child(1) as Label
#		button.text = new_item.name
#		label.text = Boid.Behavior.keys()[i.behavior]
#		ui_boids.add_child(new_item)
#	for i in get_node(Global.Groups.QUARRY).get_children():
#		var new_item = Global.UiItemFactory.instantiate()
#		var button = new_item.get_child(0) as Button
#		var label = new_item.get_child(1) as Label
#		button.text = str(i.get_instance_id())
#		label.text = Quarry.Behavior.keys()[i.behavior]
#		ui_quarry.add_child(new_item)


func _physics_process(_delta):
	queue_redraw()


func _draw():
	if(!Global.CAMERA): return
	if(draw_level_grid):
		var grid_position = get_viewport_rect().size  * Global.CAMERA.zoom / 2
		var grid_padding = 100
		var cell_size = 128
		var camera_position = Global.CAMERA.position
		var color = level_grid_color
		# Draw Vertical Lines
		for i in range(int((camera_position.x - grid_position.x) / cell_size) - 1, int((grid_position.x + camera_position.x) / cell_size) + 1):
			draw_line(Vector2(i * cell_size, camera_position.y + grid_position.y + grid_padding), Vector2(i * cell_size, camera_position.y - grid_position.y - grid_padding), color)
		# Draw Horizontal Lines
		for i in range(int((camera_position.y - grid_position.y) / cell_size) - 1, int((grid_position.y + camera_position.y) / cell_size) + 1):
			draw_line(Vector2(camera_position.x + grid_position.x + grid_padding, i * cell_size), Vector2(camera_position.x - grid_position.x - grid_padding, i * cell_size), color)


func _on_camera_2d_signal_toggle_seek_flee():
	var toggle_list = []
	for region in get_node("Regions").get_children():
		if(region.mouse_in_region):
			var arr = Array()
			arr.append_array(region.groups.get(Global.Groups.BOIDS))
			arr.append_array(region.groups.get(Global.Groups.QUARRY))
			for e in arr:
				if(e.behavior == Boid.Behavior.SEEK):
					e.behavior = Boid.Behavior.FLEE
				elif(e.behavior == Boid.Behavior.FLEE):
					e.behavior = Boid.Behavior.SEEK


func _on_camera_2d_signal_toggle_pursuit_evasion():
	var toggle_list = []
	for region in get_node("Regions").get_children():
		if(region.mouse_in_region):
			var arr = Array()
			arr.append_array(region.groups.get(Global.Groups.BOIDS))
			arr.append_array(region.groups.get(Global.Groups.QUARRY))
			for e in arr:
				if(e.behavior == Boid.Behavior.PURSUIT):
					e.behavior = Boid.Behavior.EVASION
				elif(e.behavior == Boid.Behavior.EVASION):
					e.behavior = Boid.Behavior.PURSUIT
