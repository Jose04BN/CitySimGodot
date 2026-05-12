extends Node

@export var grid_path: NodePath
@export var build_controller_path: NodePath
@export var pathfinder_path: NodePath
@export var spawn_interval: float = 4.0
@export var max_vehicles: int = 8

signal traffic_changed(vehicle_count: int, congestion_factor: float)

var _build_controller: Node
var _pathfinder: Node
var _grid: Node
var _accum: float = 0.0
var _vehicles_parent: Node3D
var _vehicle_scene: Script = preload("res://scripts/Vehicle.gd")

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
    var count: int = _vehicles_parent.get_child_count()
    var congestion: float = _congestion_factor(count)
    emit_signal("traffic_changed", count, congestion)
    if _accum >= spawn_interval and count < max_vehicles:
        _accum = 0.0
        _try_spawn()
    _retarget_busy_routes(congestion)

func get_vehicle_count() -> int:
    return _vehicles_parent.get_child_count()

func _congestion_factor(vehicle_count: int) -> float:
    if max_vehicles <= 0:
        return 1.0
    var saturation := float(vehicle_count) / float(max_vehicles)
    return clampf(1.0 - saturation * 0.45, 0.35, 1.0)

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
    var road_costs: Dictionary = _build_road_costs()
    var path: Array = _pathfinder.call("find_path_world", start_world, end_world, road_costs)
    if path.size() == 0:
        return
    var veh := Node3D.new()
    veh.set_script(_vehicle_scene)
    veh.position = start_world
    _vehicles_parent.add_child(veh)
    veh.call("set_path", path)
    veh.call("set_traffic_factor", _congestion_factor(_vehicles_parent.get_child_count()))

func _build_road_costs() -> Dictionary:
    var road_costs: Dictionary = {}
    for child in _vehicles_parent.get_children():
        var vehicle: Node = child
        var target: Variant = vehicle.call("get_next_target")
        if typeof(target) != TYPE_VECTOR3:
            continue
        var cell: Vector2i = _grid.call("world_to_cell", target)
        var key: String = str(cell.x) + ":" + str(cell.y)
        road_costs[key] = int(road_costs.get(key, 1)) + 1
    return road_costs

func _retarget_busy_routes(congestion: float) -> void:
    if congestion < 0.8:
        return
    var road_costs: Dictionary = _build_road_costs()
    for child in _vehicles_parent.get_children():
        var vehicle: Node = child
        var destination: Variant = vehicle.call("get_destination")
        if typeof(destination) != TYPE_VECTOR3:
            continue
        var current_pos: Vector3 = vehicle.global_transform.origin
        var path: Array = _pathfinder.call("find_path_world", current_pos, destination, road_costs)
        if path.size() > 1:
            vehicle.call("set_path", path)
            vehicle.call("set_traffic_factor", _congestion_factor(_vehicles_parent.get_child_count()))
