class_name Level
extends Node2D


@export var level_background: Color = Color.TRANSPARENT
@export var level_grid_color: Color = Color("#3d3d3d")


func _init():
	if(Main.LEVEL):
		Main.LEVEL.queue_free()
	Main.LEVEL = self


func _ready():
	# Create grouping nodes
	for i in Main.Groups:
		if(!get_node(Main.Groups.get(i))):
			var node = Node.new()
			node.name = Main.Groups.get(i)
			add_child(node)
	# Set level background color
	$CanvasLayer/ColorRect.color = level_background


func _process(delta):
	queue_redraw()


func _draw():
	var grid_position = get_viewport_rect().size  * get_node("Camera2D").zoom / 2
	var grid_padding = 100
	var cell_size = 128
	var camera_position = get_node("Camera2D").position
	var color = level_grid_color
	# Draw Vertical Lines
	for i in range(int((camera_position.x - grid_position.x) / cell_size) - 1, int((grid_position.x + camera_position.x) / cell_size) + 1):
		draw_line(Vector2(i * cell_size, camera_position.y + grid_position.y + grid_padding), Vector2(i * cell_size, camera_position.y - grid_position.y - grid_padding), color)
	# Draw Horizontal Lines
	for i in range(int((camera_position.y - grid_position.y) / cell_size) - 1, int((grid_position.y + camera_position.y) / cell_size) + 1):
		draw_line(Vector2(camera_position.x + grid_position.x + grid_padding, i * cell_size), Vector2(camera_position.x - grid_position.x - grid_padding, i * cell_size), color)

