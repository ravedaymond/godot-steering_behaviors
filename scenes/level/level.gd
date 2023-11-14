class_name Level
extends Node2D


enum ContextActions {
	CREATE,
	DELETE,
}

@export var level_grid_color: Color = Color("#3d3d3d")

var boids: Array = []
var quarry: Array = []
var level_context_action: ContextActions = ContextActions.CREATE

@onready var ui_context_create: CheckButton = $CanvasLayer/Control/Container/MarginContainer/VBoxContainer/HBoxContainer/ButtonCreate
@onready var ui_context_delete: CheckButton = $CanvasLayer/Control/Container/MarginContainer/VBoxContainer/HBoxContainer/ButtonDelete
@onready var ui_boids: VBoxContainer = $CanvasLayer/Control/Container/MarginContainer/VBoxContainer/ScrollContainerBoids/VBoxContainer
@onready var ui_quarry: VBoxContainer = $CanvasLayer/Control/Container/MarginContainer/VBoxContainer/ScrollContainerQuarry/VBoxContainer
@export var level_background: Color = Color.TRANSPARENT


func _init():
	if(Main.LEVEL):
		Main.LEVEL.queue_free()
	Main.LEVEL = self


func _ready():
	# Create grouping nodes
	# Set level background color
	$CanvasLayer/ColorRect.color = level_background
	# Create grouping nodes
	for i in Main.Groups:
		if(!get_node(Main.Groups.get(i))):
			var node = Node.new()
			node.name = Main.Groups.get(i)
			add_child(node)
	# Populate boids and quarry list
	for i in get_node(Main.Groups.BOIDS).get_children():
		var new_item = Main.UiItemFactory.instantiate()
		new_item.name = str(i.get_instance_id())
		var button = new_item.get_child(0) as Button
		var label = new_item.get_child(1) as Label
		button.text = new_item.name
		label.text = Boid.Behavior.keys()[i.behavior]
		ui_boids.add_child(new_item)
	for i in get_node(Main.Groups.QUARRY).get_children():
		var new_item = Main.UiItemFactory.instantiate()
		var button = new_item.get_child(0) as Button
		var label = new_item.get_child(1) as Label
		button.text = str(i.get_instance_id())
		label.text = Quarry.Behavior.keys()[i.behavior]
		ui_quarry.add_child(new_item)


func _process(_delta):
	if(ui_context_create.button_pressed):
		level_context_action = ContextActions.CREATE
	elif(ui_context_delete.button_pressed):
		level_context_action = ContextActions.DELETE
	
	queue_redraw()


func _draw():
	var grid_position = get_viewport_rect().size  * Main.CAMERA.zoom / 2
	var grid_padding = 100
	var cell_size = 128
	var camera_position = Main.CAMERA.position
	var color = level_grid_color
	# Draw Vertical Lines
	for i in range(int((camera_position.x - grid_position.x) / cell_size) - 1, int((grid_position.x + camera_position.x) / cell_size) + 1):
		draw_line(Vector2(i * cell_size, camera_position.y + grid_position.y + grid_padding), Vector2(i * cell_size, camera_position.y - grid_position.y - grid_padding), color)
	# Draw Horizontal Lines
	for i in range(int((camera_position.y - grid_position.y) / cell_size) - 1, int((grid_position.y + camera_position.y) / cell_size) + 1):
		draw_line(Vector2(camera_position.x + grid_position.x + grid_padding, i * cell_size), Vector2(camera_position.x - grid_position.x - grid_padding, i * cell_size), color)

