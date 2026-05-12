extends Node3D

@export var road_scene: PackedScene

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var cam := get_viewport().get_camera_3d()
		if cam == null:
			return
		var from := cam.project_ray_origin(event.position)
		var to := from + cam.project_ray_normal(event.position) * 1000
		var space_state := get_world_3d().direct_space_state
		var query := PhysicsRayQueryParameters3D.create(from, to)
		var res := space_state.intersect_ray(query)
		if not res.is_empty():
			var pos: Vector3 = res["position"]
			pos = Vector3(round(pos.x / 2.0) * 2.0, 0, round(pos.z / 2.0) * 2.0)
			if road_scene:
				var road = road_scene.instantiate()
				road.transform.origin = pos
				get_tree().get_root().get_node("Main").add_child(road)
