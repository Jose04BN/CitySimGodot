extends Node3D

@onready var _mesh_instance: MeshInstance3D = $Mesh
var _zone_type := 1
var _level: int = 1
var _building_root: Node3D = null

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
	_refresh_building_visuals()

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
	_refresh_building_visuals()

func upgrade() -> void:
	set_level(_level + 1)

func downgrade() -> void:
	set_level(max(1, _level - 1))

func _refresh_building_visuals() -> void:
	if _building_root == null:
		_building_root = Node3D.new()
		_building_root.name = "BuildingRoot"
		add_child(_building_root)
		_building_root.position = Vector3(0.0, 0.05, 0.0)

	for child in _building_root.get_children():
		(child as Node).queue_free()

	var primary_color := _get_zone_color()
	var accent_color := primary_color.lightened(0.15)
	var roof_color := primary_color.darkened(0.2)
	var segment_count := mini(_level, 5)
	for i in range(segment_count):
		var part := MeshInstance3D.new()
		var part_mesh := BoxMesh.new()
		var width := 0.48 - float(i) * 0.04
		var depth := 0.48 - float(i) * 0.04
		var height := 0.55 + float(_level) * 0.18 + float(i) * 0.12
		part_mesh.size = Vector3(width, height, depth)
		part.mesh = part_mesh
		var part_material := StandardMaterial3D.new()
		part_material.albedo_color = primary_color.lerp(accent_color, float(i) / max(1.0, float(segment_count - 1)))
		part_material.roughness = 0.7
		part.material_override = part_material
		part.position = Vector3(0.0, 0.45 + float(i) * 0.36 + height * 0.5, 0.0)
		_building_root.add_child(part)

	if _level >= 3:
		var roof := MeshInstance3D.new()
		var roof_mesh: BoxMesh = BoxMesh.new()
		roof_mesh.size = Vector3(0.78, 0.18 + float(_level) * 0.03, 0.78)
		roof.mesh = roof_mesh
		var roof_material := StandardMaterial3D.new()
		roof_material.albedo_color = roof_color
		roof_material.roughness = 0.9
		roof.material_override = roof_material
		roof.position = Vector3(0.0, 0.95 + float(_level) * 0.34, 0.0)
		_building_root.add_child(roof)

	if _zone_type == 3:
		var smoke_stack := MeshInstance3D.new()
		var stack_mesh := CylinderMesh.new()
		stack_mesh.top_radius = 0.06
		stack_mesh.bottom_radius = 0.08
		stack_mesh.height = 0.3 + float(_level) * 0.05
		smoke_stack.mesh = stack_mesh
		var stack_material := StandardMaterial3D.new()
		stack_material.albedo_color = Color(0.42, 0.42, 0.38)
		smoke_stack.material_override = stack_material
		smoke_stack.position = Vector3(0.22, 0.75 + float(_level) * 0.22, 0.15)
		_building_root.add_child(smoke_stack)

func _get_zone_color() -> Color:
	match _zone_type:
		1:
			return Color(0.3, 0.85, 0.3)
		2:
			return Color(0.2, 0.6, 0.95)
		3:
			return Color(0.95, 0.7, 0.2)
		_:
			return Color(0.4, 0.8, 0.4)
