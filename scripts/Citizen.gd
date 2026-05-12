extends Node3D

@export var speed: float = 3.0

var _path: Array = []
var _path_index: int = 0
var _visual: MeshInstance3D
var _finished: bool = false

func _ready() -> void:
	_visual = MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.12
	capsule.height = 0.4
	_visual.mesh = capsule
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.8, 0.95)
	_visual.material_override = material
	add_child(_visual)

func set_path(path: Array) -> void:
	_path = path
	_path_index = 0
	_finished = false

func is_finished() -> bool:
	return _finished

func _process(delta: float) -> void:
	if _path.size() == 0:
		return
	if _path_index >= _path.size():
		_finished = true
		queue_free()
		return
	var target_pos: Vector3 = _path[_path_index]
	var dir: Vector3 = target_pos - global_transform.origin
	if dir.length() < 0.1:
		_path_index += 1
		return
	var movement: Vector3 = dir.normalized() * speed * delta
	if movement.length() > dir.length():
		movement = dir
	global_transform.origin += movement
	look_at(global_transform.origin + Vector3(movement.x, 0.0, movement.z), Vector3.UP)
