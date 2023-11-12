extends Node2D


const Groups: Dictionary = {
	BOIDS = "Boids",
	QUARRY = "Quarry",
	BEACONS = "Beacons",
}


static var BoidFactory = preload("res://scenes/characters/boids/boid.tscn")
static var QuarryFactory = preload("res://scenes/characters/quarry/quarry.tscn")
static var BeaconFactory = preload("res://scenes/characters/beacons/beacon.tscn")
static var UiItemFactory = preload("res://scenes/ui/components/ui_grid_item.tscn")


static var CAMERA: Camera
static var LEVEL: Level

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if(Input.is_action_just_pressed("ui_cancel")):
		get_tree().reload_current_scene()
	pass


func create_beacon(global_pos: Vector2, type: Beacon.Type = Beacon.Type.NEUTRAL) -> void:
	if(!LEVEL || !BeaconFactory.can_instantiate()):
		print("Can not create new Beacon.")
		return
	var beacon = BeaconFactory.instantiate()
	beacon.type = type
	beacon.global_position = global_pos
	LEVEL.get_node(Groups.BEACONS).add_child(beacon)


func create_boid(global_pos: Vector2, type: Boid.Type = Boid.Type.NEUTRAL) -> void:
	if(!LEVEL || !BoidFactory.can_instantiate()):
		print("Can not create new Boid.")
		return
	var boid = BoidFactory.instantiate()
	boid.type = type
	boid.global_position = global_pos
	LEVEL.get_node(Groups.BOIDS).add_child(boid)


func create_quarry(global_pos: Vector2, type: Quarry.Type = Quarry.Type.NEUTRAL) -> void:
	if(!LEVEL || !QuarryFactory.can_instantiate()):
		print("Can not create new Quarry.")
		return
	var quarry = QuarryFactory.instantiate()
	quarry.type = type
	quarry.global_position = global_pos
	LEVEL.get_node(Groups.QUARRY).add_child(quarry)

