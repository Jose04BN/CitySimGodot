CitySimGodot — Prototype workspace

Quick start

1. Install Godot 4.x: https://godotengine.org/download
2. Install VS Code extensions: "Godot Tools" and "GDScript".
3. Open this folder in VS Code.
4. Run the task `Run Godot (editor)` (Terminal→Run Task) or open the project in the Godot Editor.

Current prototype features

- `scenes/Main.tscn` — main scene with grid, build controller, camera, light, and HUD.
- `scripts/Grid.gd` — draws a buildable grid and provides hit/cell conversion helpers.
- `scripts/BuildController.gd` — handles input modes and placement/erase logic.
- `scripts/CitySimulation.gd` — runs a live city loop (time, population, jobs, treasury, demand).
- `scripts/Pathfinder.gd` — simple grid A* pathfinding over road cells.
- `scripts/TrafficController.gd` and `scripts/Vehicle.gd` — lightweight traffic agents that spawn on roads, travel between connected points, and feed congestion back into the simulation.
- `scripts/Citizen.gd` — commuter agent placeholder now used to spawn visible home-to-work commuters on the traffic network.
- `scenes/RoadTile.tscn` — road tile visual prefab.
- `scenes/ZoneTile.tscn` + `scripts/ZoneTile.gd` — zone tile visual prefab and zone color mapping.
- `scripts/Citizen.gd` — minimal agent script for next milestones.

Controls

- `1` Road mode
- `2` Residential zone mode
- `3` Commercial zone mode
- `4` Industrial zone mode
- `E` Erase mode
- `F5` Save city to `user://city_save.json`
- `F9` Load city from `user://city_save.json`
- Left mouse click places/removes on the snapped grid cell based on mode
- Right mouse drag rotates camera
- `W/A/S/D` moves camera pivot
- Mouse wheel zooms camera

Traffic prototype

- The main scene now includes a `TrafficController` node that uses road cells and `Pathfinder.gd` to spawn simple vehicles.
- Traffic is intentionally capped and slow so it stays readable while the prototype is still small.
- Vehicle agents are visual placeholders for later commuter and congestion systems.
- Congestion now affects the simulation HUD and slightly changes treasury and industrial demand.
- Commuter agents now spawn from residential to job zones and move along the road graph when paths exist.

Notes

- Roads block zoning on the same cell.
- Zoning can overwrite other zone types on the same cell.
- Save/load now includes simulation state (time, population, treasury, demands).
- HUD second line shows live metrics and R/C/I demand values.
- The project starts with `res://scenes/Main.tscn` as the main scene.
