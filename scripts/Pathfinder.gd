extends Node

@export var grid_path: NodePath
@export var build_controller_path: NodePath

var _grid: Node
var _build_controller: Node

func _ready() -> void:
    _grid = get_node(grid_path)
    _build_controller = get_node(build_controller_path)

func _cell_key(cell: Vector2i) -> String:
    return str(cell.x) + ":" + str(cell.y)

func _is_walkable(cell: Vector2i) -> bool:
    if not _grid.call("is_in_bounds", cell):
        return false
    # Walkable if there's a road on the cell
    var roads: Array = _build_controller.call("get_road_cells")
    for r in roads:
        if r == cell:
            return true
    return false

func find_path_world(start_world: Vector3, end_world: Vector3) -> Array:
    var start_cell: Vector2i = _grid.call("world_to_cell", start_world)
    var end_cell: Vector2i = _grid.call("world_to_cell", end_world)
    var cells: Array = find_path_cells(start_cell, end_cell)
    var out: Array = []
    for c in cells:
        out.append(_grid.call("cell_to_world", c) + Vector3(0, 0.0, 0))
    return out

func find_path_cells(start: Vector2i, goal: Vector2i) -> Array:
    # Simple A* on 4-neighborhood
    if start == goal:
        return [start]
    var open := {}
    var came_from := {}
    func h(a: Vector2i, b: Vector2i) -> int:
        return abs(a.x - b.x) + abs(a.y - b.y)

    var g_score := {}
    var f_score := {}

    open[_cell_key(start)] = start
    g_score[_cell_key(start)] = 0
    f_score[_cell_key(start)] = h(start, goal)

    while open.size() > 0:
        # pick node in open with lowest f
        var current_key := null
        var current_f := 1e9
        for k in open.keys():
            var v := f_score.get(k, 1e9)
            if v < current_f:
                current_f = v
                current_key = k
        var current: Vector2i = open[current_key]
        if current == goal:
            # reconstruct path
            var path := []
            var k := current_key
            while k != null and came_from.has(k):
                path.insert(0, _key_to_cell(k))
                k = came_from.get(k, null)
            path.append(goal)
            return path

        open.erase(current_key)

        var neighbors := [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
        for d in neighbors:
            var n := Vector2i(current.x + d.x, current.y + d.y)
            if not _is_walkable(n):
                continue
            var nk := _cell_key(n)
            var tentative_g := g_score.get(current_key, 1e9) + 1
            if tentative_g < g_score.get(nk, 1e9):
                came_from[nk] = current_key
                g_score[nk] = tentative_g
                f_score[nk] = tentative_g + h(n, goal)
                if not open.has(nk):
                    open[nk] = n

    return []

func _key_to_cell(key: String) -> Vector2i:
    var parts := key.split(":")
    return Vector2i(int(parts[0]), int(parts[1]))
