extends Node


const Groups: Dictionary = {
	BOIDS = "Boids",
	QUARRY = "Quarry",
	STATIONS = "Stations",
	OBSTACLES = "Obstacles",
}

const Demos: Dictionary = {
	"demo_seek_flee": "Seek and Flee",
	"demo_pursuit_evasion": "Pursuit and Evasion",
	"demo_offset_pursuit": "Offset Pursuit",
	"demo_arrival": "Arrival",
	"demo_wander": "Wander",
}

const OBJECT_FACTORY = {
	BOID = preload("res://scenes/characters/boids/boid.tscn"),
	QUARRY = preload("res://scenes/characters/quarry/quarry.tscn"),
}

#static var UiItemFactory = preload("res://scenes/ui/components/ui_grid_item.tscn")


static var CAMERA: Camera
static var LEVEL: Level
static var DEMO_SELECTED: Resource
static var WINDOW_TITLE: String


func create_boid(global_pos: Vector2, type: Boid.Type = Boid.Type.NEUTRAL) -> void:
	if(!Global.Global.LEVEL || !Global.BoidFactory.can_instantiate()):
		print("Can not create new Boid.")
		return
	var boid = Global.BoidFactory.instantiate()
	boid.type = type
	boid.global_position = global_pos
	Global.LEVEL.get_node(Global.Groups.BOIDS).add_child(boid)


func create_quarry(global_pos: Vector2, type: Quarry.Type = Quarry.Type.NEUTRAL) -> void:
	if(!Global.LEVEL || !Global.QuarryFactory.can_instantiate()):
		print("Can not create new Quarry.")
		return
	var quarry = Global.QuarryFactory.instantiate()
	quarry.type = type
	quarry.global_position = global_pos
	Global.LEVEL.get_node(Global.Groups.QUARRY).add_child(quarry)
