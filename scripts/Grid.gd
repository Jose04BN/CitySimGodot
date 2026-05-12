extends Node3D

@export var width := 20
@export var height := 20
@export var cell_size := 2.0

var _overlay_parent: Node3D
var _overlay_visible: bool = true

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

	_overlay_parent = Node3D.new()
	_overlay_parent.name = "PollutionOverlay"
	add_child(_overlay_parent)

func world_to_cell(world_pos: Vector3) -> Vector2i:
	return Vector2i(
		int(round(world_pos.x / cell_size)),
		int(round(world_pos.z / cell_size))
	)

func cell_to_world(cell: Vector2i) -> Vector3:
	return Vector3(cell.x * cell_size, 0.0, cell.y * cell_size)

func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height

func set_pollution_overlay(entries: Array) -> void:
	if _overlay_parent == null:
		return
	for child in _overlay_parent.get_children():
		(child as Node).queue_free()
	if not _overlay_visible:
		return

	var overlay_mesh := BoxMesh.new()
	overlay_mesh.size = Vector3(cell_size * 0.96, 0.08, cell_size * 0.96)
	for entry in entries:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var cell := Vector2i(int(entry.get("x", 0)), int(entry.get("y", 0)))
		if not is_in_bounds(cell):
			continue
		var intensity: float = clampf(float(entry.get("intensity", 0.0)), 0.0, 1.0)
		if intensity <= 0.01:
			continue
		var overlay := MeshInstance3D.new()
		overlay.mesh = overlay_mesh
		var mat := StandardMaterial3D.new()
		# support optional explicit color per entry (r,g,b,a)
		if entry.has("r") and entry.has("g") and entry.has("b"):
			var ra: float = float(entry.get("r", 0.15))
			var ga: float = float(entry.get("g", 0.2))
			var ba: float = float(entry.get("b", 0.12))
			var aa: float = float(entry.get("a", 0.12 + intensity * 0.45))
			mat.albedo_color = Color(clampf(ra,0.0,1.0), clampf(ga,0.0,1.0), clampf(ba,0.0,1.0), clampf(aa,0.0,1.0))
		else:
			mat.albedo_color = Color(0.15 + intensity * 0.8, 0.2, 0.12, 0.12 + intensity * 0.45)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.flags_transparent = true
		mat.roughness = 1.0
		overlay.material_override = mat
		overlay.position = cell_to_world(cell) + Vector3(0.0, 0.12, 0.0)
		_overlay_parent.add_child(overlay)

func set_pollution_overlay_visible(visible: bool) -> void:
	_overlay_visible = visible
	if _overlay_parent == null:
		return
	_overlay_parent.visible = _overlay_visible
