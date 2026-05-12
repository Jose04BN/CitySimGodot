extends Node3D

signal about_to_save(payload: Dictionary)
signal city_loaded(payload: Dictionary)

enum BuildMode {
	ROAD,
	RESIDENTIAL,
	COMMERCIAL,
	INDUSTRIAL,
	ERASE
}

@export var grid_path: NodePath
@export var road_scene: PackedScene
@export var zone_scene: PackedScene
@export var roads_parent_path: NodePath
@export var zones_parent_path: NodePath
@export var hud_label_path: NodePath
@export var save_file_path := "user://city_save.json"

var _grid: Node3D
var _roads_parent: Node3D
var _zones_parent: Node3D
var _hud_label: Label
var _mode: BuildMode = BuildMode.ROAD
var _pollution_overlay_visible: bool = true
var _city_pollution: float = 0.0
var _city_happiness: float = 60.0

var _road_tiles: Dictionary = {}
var _zone_tiles: Dictionary = {}

func _ready() -> void:
	_grid = get_node(grid_path)
	_roads_parent = get_node(roads_parent_path)
	_zones_parent = get_node(zones_parent_path)
	_hud_label = get_node_or_null(hud_label_path)
	_update_hud()
	_refresh_pollution_overlay()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_match_mode_shortcut(event.keycode)

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_apply_build_action(event.position)

func _match_mode_shortcut(keycode: Key) -> void:
	match keycode:
		KEY_1:
			_mode = BuildMode.ROAD
		KEY_2:
			_mode = BuildMode.RESIDENTIAL
		KEY_3:
			_mode = BuildMode.COMMERCIAL
		KEY_4:
			_mode = BuildMode.INDUSTRIAL
		KEY_E:
			_mode = BuildMode.ERASE
		KEY_H:
			_pollution_overlay_visible = not _pollution_overlay_visible
			_refresh_pollution_overlay()
		KEY_F5:
			save_city()
			return
		KEY_F9:
			load_city()
			return
		_:
			return
	_update_hud()

func _apply_build_action(mouse_pos: Vector2) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return

	var from := cam.project_ray_origin(mouse_pos)
	var to := from + cam.project_ray_normal(mouse_pos) * 1000.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return

	var hit_pos: Vector3 = result["position"]
	var cell: Vector2i = _grid.call("world_to_cell", hit_pos)
	if not bool(_grid.call("is_in_bounds", cell)):
		return

	match _mode:
		BuildMode.ROAD:
			_place_road(cell)
		BuildMode.RESIDENTIAL:
			_place_zone(cell, BuildMode.RESIDENTIAL)
		BuildMode.COMMERCIAL:
			_place_zone(cell, BuildMode.COMMERCIAL)
		BuildMode.INDUSTRIAL:
			_place_zone(cell, BuildMode.INDUSTRIAL)
		BuildMode.ERASE:
			_erase_cell(cell)

func _place_road(cell: Vector2i) -> void:
	var key := _cell_key(cell)
	if _road_tiles.has(key):
		return

	_erase_zone(cell)

	var road := road_scene.instantiate()
	var world_pos: Vector3 = _grid.call("cell_to_world", cell)
	road.position = world_pos + Vector3(0.0, 0.08, 0.0)
	_roads_parent.add_child(road)
	_road_tiles[key] = road

func _place_zone(cell: Vector2i, zone_type: BuildMode) -> void:
	var key := _cell_key(cell)
	if _road_tiles.has(key):
		return

	var zone = _zone_tiles.get(key, null)
	if zone == null:
		zone = zone_scene.instantiate()
		var world_pos: Vector3 = _grid.call("cell_to_world", cell)
		zone.position = world_pos + Vector3(0.0, 0.04, 0.0)
		_zones_parent.add_child(zone)
		_zone_tiles[key] = zone

	zone.call("set_zone", int(zone_type))

func set_zone_level(cell: Vector2i, level: int) -> void:
	var key := _cell_key(cell)
	if not _zone_tiles.has(key):
		return
	var zone_node: Node = _zone_tiles[key]
	zone_node.call("set_level", int(level))

func is_cell_connected(cell: Vector2i) -> bool:
	# A cell is connected if any orthogonal neighbor has a road
	var dirs := [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	for d in dirs:
		var n := Vector2i(cell.x + d.x, cell.y + d.y)
		var key := _cell_key(n)
		if _road_tiles.has(key):
			return true
	return false

func _erase_cell(cell: Vector2i) -> void:
	_erase_road(cell)
	_erase_zone(cell)

func _erase_road(cell: Vector2i) -> void:
	var key := _cell_key(cell)
	if not _road_tiles.has(key):
		return
	var road: Node3D = _road_tiles[key]
	road.queue_free()
	_road_tiles.erase(key)

func _erase_zone(cell: Vector2i) -> void:
	var key := _cell_key(cell)
	if not _zone_tiles.has(key):
		return
	var zone: Node3D = _zone_tiles[key]
	zone.queue_free()
	_zone_tiles.erase(key)

func _cell_key(cell: Vector2i) -> String:
	return str(cell.x) + ":" + str(cell.y)

func _update_hud() -> void:
	if _hud_label == null:
		return

	var mode_text := "Road"
	match _mode:
		BuildMode.ROAD:
			mode_text = "Road"
		BuildMode.RESIDENTIAL:
			mode_text = "Residential"
		BuildMode.COMMERCIAL:
			mode_text = "Commercial"
		BuildMode.INDUSTRIAL:
			mode_text = "Industrial"
		BuildMode.ERASE:
			mode_text = "Erase"

	_hud_label.text = "Mode: %s | 1 Road | 2 Residential | 3 Commercial | 4 Industrial | E Erase | H Overlay | LMB Place | F5 Save | F9 Load | RMB Rotate Camera | WASD Move" % mode_text

func save_city() -> void:
	var roads: Array = []
	for key in _road_tiles.keys():
		var cell := _key_to_cell(str(key))
		roads.append({"x": cell.x, "y": cell.y})

	var zones: Array = []
	for key in _zone_tiles.keys():
		var zone_node: Node = _zone_tiles[key]
		var zone_type := int(zone_node.call("get_zone_type"))
		var level := int(zone_node.call("get_level"))
		var cell := _key_to_cell(str(key))
		zones.append({"x": cell.x, "y": cell.y, "type": zone_type, "level": level})

	var payload: Dictionary = {"roads": roads, "zones": zones}
	emit_signal("about_to_save", payload)
	var file := FileAccess.open(save_file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(payload))

func load_city() -> void:
	if not FileAccess.file_exists(save_file_path):
		return

	var file := FileAccess.open(save_file_path, FileAccess.READ)
	if not file:
		return

	var content := file.get_as_text()
	var data = JSON.parse_string(content)
	if typeof(data) != TYPE_DICTIONARY:
		return
	var payload: Dictionary = data

	_clear_all()

	for entry in payload.get("roads", []):
		var cell := Vector2i(int(entry.get("x", 0)), int(entry.get("y", 0)))
		_place_road(cell)

	for entry in payload.get("zones", []):
		var cell := Vector2i(int(entry.get("x", 0)), int(entry.get("y", 0)))
		var zone_type := int(entry.get("type", BuildMode.RESIDENTIAL))
		_place_zone(cell, zone_type as BuildMode)
		var level := int(entry.get("level", 1))
		set_zone_level(cell, level)

	emit_signal("city_loaded", payload)

func _clear_all() -> void:
	for road in _road_tiles.values():
		(road as Node).queue_free()
	for zone in _zone_tiles.values():
		(zone as Node).queue_free()
	_road_tiles.clear()
	_zone_tiles.clear()

func _key_to_cell(key: String) -> Vector2i:
	var parts := key.split(":")
	if parts.size() != 2:
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))

func get_city_snapshot() -> Dictionary:
	var residential: int = 0
	var commercial: int = 0
	var industrial: int = 0

	var zones_detail: Array = []
	for key in _zone_tiles.keys():
		var zone_node: Node = _zone_tiles[key]
		var zone_type: int = int(zone_node.call("get_zone_type"))
		var level: int = int(zone_node.call("get_level"))
		var cell := _key_to_cell(str(key))
		var connected := is_cell_connected(cell)
		zones_detail.append({"x": cell.x, "y": cell.y, "type": zone_type, "level": level, "connected": connected})

	for z in zones_detail:
		match int(z.get("type", 0)):
			BuildMode.RESIDENTIAL:
				residential += 1
			BuildMode.COMMERCIAL:
				commercial += 1
			BuildMode.INDUSTRIAL:
				industrial += 1

	return {
		"road_count": _road_tiles.size(),
		"residential_zones": residential,
		"commercial_zones": commercial,
		"industrial_zones": industrial,
		"total_zones": _zone_tiles.size(),
		"zones_detail": zones_detail
	}

func set_city_environment(pollution: float, happiness: float, health_alert: String = "Stable", health_timer: float = 0.0) -> void:
	_city_pollution = clampf(pollution, 0.0, 100.0)
	_city_happiness = clampf(happiness, 0.0, 100.0)
	for zone_node in _zone_tiles.values():
		(zone_node as Node).call("set_environment", pollution, happiness)
	_refresh_pollution_overlay(health_alert, health_timer)

func _refresh_pollution_overlay(health_alert: String = "Stable", health_timer: float = 0.0) -> void:
	if _grid == null:
		return
	var overlay_entries: Array = []
	for key in _zone_tiles.keys():
		var zone_node: Node = _zone_tiles[key]
		var zone_type: int = int(zone_node.call("get_zone_type"))
		var level: int = int(zone_node.call("get_level"))
		var cell := _key_to_cell(str(key))
		var base_intensity := 0.0
		match zone_type:
			BuildMode.RESIDENTIAL:
				base_intensity = 0.12 + float(level) * 0.04 + _city_pollution * 0.002
			BuildMode.COMMERCIAL:
				base_intensity = 0.18 + float(level) * 0.05 + _city_pollution * 0.003
			BuildMode.INDUSTRIAL:
				base_intensity = 0.34 + float(level) * 0.09 + _city_pollution * 0.004
		overlay_entries.append({"x": cell.x, "y": cell.y, "intensity": clampf(base_intensity, 0.0, 1.0)})
		var directions: Array = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
		for d in directions:
			var neighbor: Vector2i = cell + d
			overlay_entries.append({"x": neighbor.x, "y": neighbor.y, "intensity": clampf(base_intensity * 0.45, 0.0, 1.0)})
		# add a red crisis tint for industrial zones during health alerts
		if health_alert != "Stable" and zone_type == BuildMode.INDUSTRIAL:
			var crisis_strength := clampf(health_timer / 12.0, 0.0, 1.0)
			overlay_entries.append({"x": cell.x, "y": cell.y, "intensity": clampf(0.6 + crisis_strength * 0.35, 0.0, 1.0), "r": 1.0, "g": 0.15, "b": 0.15, "a": 0.18 + crisis_strength * 0.45})

	_grid.call("set_pollution_overlay_visible", _pollution_overlay_visible)
	_grid.call("set_pollution_overlay", overlay_entries)

func get_road_cells() -> Array:
	var out: Array = []
	for key in _road_tiles.keys():
		out.append(_key_to_cell(str(key)))
	return out
