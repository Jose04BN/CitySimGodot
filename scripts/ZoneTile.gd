extends Node3D

@onready var _mesh_instance: MeshInstance3D = $Mesh
var _zone_type := 1
var _level: int = 1
var _building: MeshInstance3D = null

func set_zone(zone_type: int) -> void:
	_zone_type = zone_type
	_level = 1
	var color := Color(0.4, 0.8, 0.4, 0.6)
	match zone_type:
		1:
			color = Color(0.3, 0.85, 0.3, 0.6) # Residential
		2:
			color = Color(0.2, 0.6, 0.95, 0.6) # Commercial
		3:
			color = Color(0.95, 0.7, 0.2, 0.6) # Industrial

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.flags_transparent = true
	mat.roughness = 1.0
	_mesh_instance.material_override = mat

func get_zone_type() -> int:
	return _zone_type

func get_level() -> int:
	return _level

func set_level(level: int) -> void:
	_level = clamp(level, 1, 5)
	# Visual: scale height based on level
	var base_scale: float = 1.0
	var height_scale: float = 0.25 * float(_level)
	_mesh_instance.scale = Vector3(base_scale, height_scale, base_scale)
	# Spawn/adjust simple building visual
	if _building == null:
		_building = MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.6, 1.0, 0.6)
		_building.mesh = bm
		add_child(_building)
		_building.position = Vector3(0, 0.5, 0)
	# Scale building with level
	_building.scale = Vector3(1, float(_level) * 0.7, 1)

func upgrade() -> void:
	set_level(_level + 1)

func downgrade() -> void:
	set_level(max(1, _level - 1))
