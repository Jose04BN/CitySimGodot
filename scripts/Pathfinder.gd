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

func _key_to_cell(key: String) -> Vector2i:
    var parts := key.split(":")
    return Vector2i(int(parts[0]), int(parts[1]))

func _is_walkable(cell: Vector2i) -> bool:
    if not _grid.call("is_in_bounds", cell):
        return false
    # Walkable if there's a road on the cell
    var roads: Array = _build_controller.call("get_road_cells")
    for r in roads:
        if r == cell:
            return true
    return false

func _manhattan(a: Vector2i, b: Vector2i) -> int:
    return abs(a.x - b.x) + abs(a.y - b.y)

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
    var open: Dictionary = {}
    var came_from: Dictionary = {}

    var g_score: Dictionary = {}
    var f_score: Dictionary = {}

    var start_key := _cell_key(start)
    open[start_key] = start
    g_score[start_key] = 0
    f_score[start_key] = _manhattan(start, goal)

    while open.size() > 0:
        # pick node in open with lowest f
        var current_key: String = ""
        var current_f: float = 1e9
        for k in open.keys():
            var v: float = float(f_score.get(k, 1e9))
            if v < current_f:
                current_f = v
                current_key = str(k)
        if current_key == "":
            break
        var current: Vector2i = open.get(current_key, Vector2i.ZERO)
        if current == goal:
            # reconstruct path
            var path: Array = []
            var cur: String = current_key
            while true:
                path.insert(0, _key_to_cell(cur))
                if came_from.has(cur):
                    cur = str(came_from[cur])
                else:
                    break
            return path

        open.erase(current_key)

        var neighbors := [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
        for d in neighbors:
            var n := Vector2i(current.x + d.x, current.y + d.y)
            if not _is_walkable(n):
                continue
            var nk := _cell_key(n)
            var tentative_g: int = int(g_score.get(current_key, 1000000000)) + 1
            if tentative_g < int(g_score.get(nk, 1000000000)):
                came_from[nk] = current_key
                g_score[nk] = tentative_g
                f_score[nk] = tentative_g + _manhattan(n, goal)
                if not open.has(nk):
                    open[nk] = n

    return []
