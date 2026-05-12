extends Node3D

@export var width := 20
@export var height := 20
@export var cell_size := 2.0

func _ready() -> void:
	var ground := StaticBody3D.new()
	ground.name = "GroundCollider"
	add_child(ground)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width * cell_size, 0.2, height * cell_size)
	shape.shape = box
	shape.position = Vector3(width * cell_size * 0.5 - cell_size * 0.5, 0.0, height * cell_size * 0.5 - cell_size * 0.5)
	ground.add_child(shape)

	var line_mesh := BoxMesh.new()
	line_mesh.size = Vector3(cell_size * 0.94, 0.04, cell_size * 0.94)

	for x in range(width):
		for y in range(height):
			var cell := MeshInstance3D.new()
			cell.mesh = line_mesh
			cell.position = cell_to_world(Vector2i(x, y))

			var mat := StandardMaterial3D.new()
			if (x + y) % 2 == 0:
				mat.albedo_color = Color(0.17, 0.2, 0.17)
			else:
				mat.albedo_color = Color(0.15, 0.18, 0.15)
			mat.roughness = 1.0
			cell.material_override = mat
			add_child(cell)

func world_to_cell(world_pos: Vector3) -> Vector2i:
	return Vector2i(
		int(round(world_pos.x / cell_size)),
		int(round(world_pos.z / cell_size))
	)

func cell_to_world(cell: Vector2i) -> Vector3:
	return Vector3(cell.x * cell_size, 0.0, cell.y * cell_size)

func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height
