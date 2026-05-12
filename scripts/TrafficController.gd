extends Node

@export var grid_path: NodePath
@export var build_controller_path: NodePath
@export var pathfinder_path: NodePath
@export var spawn_interval: float = 4.0
@export var max_vehicles: int = 8

var _build_controller: Node
var _pathfinder: Node
var _grid: Node
var _accum: float = 0.0
var _vehicles_parent: Node3D

func _ready() -> void:
    _grid = get_node(grid_path)
    _build_controller = get_node(build_controller_path)
    _pathfinder = get_node(pathfinder_path)
    randomize()
    _vehicles_parent = Node3D.new()
    _vehicles_parent.name = "Vehicles"
    add_child(_vehicles_parent)

func _process(delta: float) -> void:
    _accum += delta
    # cleanup count
    var count: int = _vehicles_parent.get_child_count()
    if _accum >= spawn_interval and count < max_vehicles:
        _accum = 0.0
        _try_spawn()

func _try_spawn() -> void:
    var roads: Array = _build_controller.call("get_road_cells")
    if roads.size() < 2:
        return
    var a: Vector2i = roads[randi() % roads.size()]
    var b: Vector2i = roads[randi() % roads.size()]
    if a == b:
        return
    var start_world: Vector3 = _grid.call("cell_to_world", a) + Vector3(0, 0.2, 0)
    var end_world: Vector3 = _grid.call("cell_to_world", b) + Vector3(0, 0.2, 0)
    var path: Array = _pathfinder.call("find_path_world", start_world, end_world)
    if path.size() == 0:
        return
    var veh := MeshInstance3D.new()
    var sph := SphereMesh.new()
    sph.radius = 0.18
    veh.mesh = sph
    veh.position = start_world
    _vehicles_parent.add_child(veh)
    var script: Script = load("res://scripts/Vehicle.gd")
    veh.set_script(script)
    veh.call("set_path", path)
