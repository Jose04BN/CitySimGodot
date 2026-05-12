extends Node3D

@export var speed: float = 6.0

var _path: Array = []
var _idx: int = 0
var _traffic_factor: float = 1.0
var _visual: MeshInstance3D
var _destination: Vector3 = Vector3.ZERO

func set_path(path: Array) -> void:
    _path = path
    _idx = 0
    if _path.size() > 0:
        _destination = _path[_path.size() - 1]

func set_traffic_factor(value: float) -> void:
    _traffic_factor = clampf(value, 0.35, 1.0)

func get_destination() -> Vector3:
    return _destination

func get_next_target() -> Vector3:
    if _idx >= 0 and _idx < _path.size():
        return _path[_idx]
    return _destination

func _ready() -> void:
    _visual = MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(0.22, 0.18, 0.38)
    _visual.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.95, 0.35, 0.2)
    _visual.material_override = material
    add_child(_visual)

func _process(delta: float) -> void:
    if _path.size() == 0:
        return
    if _idx >= _path.size():
        queue_free()
        return
    var target: Vector3 = _path[_idx]
    var dir := target - global_transform.origin
    if dir.length() < 0.1:
        _idx += 1
        return
    var movement := dir.normalized() * speed * _traffic_factor * delta
    if movement.length() > dir.length():
        movement = dir
    global_transform.origin += movement
    look_at(global_transform.origin + Vector3(movement.x, 0.0, movement.z), Vector3.UP)
