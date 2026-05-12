extends Node3D

@export var speed: float = 6.0

var _path: Array = []
var _idx: int = 0

func set_path(path: Array) -> void:
    _path = path
    _idx = 0

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
    global_transform.origin += dir.normalized() * speed * delta
