extends Node3D

@export var home: NodePath
@export var work: NodePath
@export var speed := 4.0
@export var pathfinder_path: NodePath

var _path: Array = []
var _path_index: int = 0
var _pathfinder: Node = null

func _ready():
	if home != null:
		global_transform.origin = get_node(home).global_transform.origin
	if pathfinder_path != null:
		_pathfinder = get_node_or_null(pathfinder_path)
	var work_node: Node3D = get_node_or_null(work)
	if work_node != null and _pathfinder != null:
		_path = _pathfinder.call("find_path_world", global_transform.origin, work_node.global_transform.origin)
		_path_index = 0

func _process(delta: float) -> void:
	if _path.size() == 0:
		return
	if _path_index >= _path.size():
		return
	var target_pos: Vector3 = _path[_path_index]
	var dir: Vector3 = target_pos - global_transform.origin
	if dir.length() < 0.1:
		_path_index += 1
		return
	global_transform.origin += dir.normalized() * speed * delta
