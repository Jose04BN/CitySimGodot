extends Node

@export var build_controller_path: NodePath
@export var pathfinder_path: NodePath
@export var spawn_interval: float = 3.0
@export var max_vehicles: int = 10

var _build_controller: Node
var _pathfinder: Node
var _accum: float = 0.0
var _vehicles_parent: Node3D

func _ready() -> void:
    _build_controller = get_node(build_controller_path)
    _pathfinder = get_node(pathfinder_path)
    _vehicles_parent = Node3D.new()
    _vehicles_parent.name = "Vehicles"
    add_child(_vehicles_parent)

func _process(delta: float) -> void:
    _accum += delta
    # cleanup count
    var count := _vehicles_parent.get_child_count()
    if _accum >= spawn_interval and count < max_vehicles:
        _accum = 0.0
        _try_spawn()

func _try_spawn() -> void:
    var roads: Array = _build_controller.call("get_road_cells")
    if roads.size() < 2:
        return
    var a := roads[randi() % roads.size()]
    var b := roads[randi() % roads.size()]
    if a == b:
        return
    # safe way: compute world via grid call on the build controller
    var grid := _build_controller.get_node(_build_controller.get("grid_path"))
    var start_world := grid.call("cell_to_world", a) + Vector3(0, 0.2, 0)
    var end_world := grid.call("cell_to_world", b) + Vector3(0, 0.2, 0)
    var path := _pathfinder.call("find_path_world", start_world, end_world)
    if path.size() == 0:
        return
    var veh := MeshInstance3D.new()
    var sph := SphereMesh.new()
    sph.radius = 0.18
    veh.mesh = sph
    veh.position = start_world
    _vehicles_parent.add_child(veh)
    var script := load("res://scripts/Vehicle.gd")
    veh.set_script(script)
    veh.call("set_path", path)
