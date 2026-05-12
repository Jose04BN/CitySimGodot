extends Node

@export var build_controller_path: NodePath
@export var traffic_controller_path: NodePath
@export var stats_label_path: NodePath
@export var tick_seconds: float = 1.0
@export var starting_treasury: float = 50000.0

enum BuildMode {
	ROAD,
	RESIDENTIAL,
	COMMERCIAL,
	INDUSTRIAL,
	ERASE
}

var _build_controller: Node
var _traffic_controller: Node
var _stats_label: Label

var _accum: float = 0.0
var _sim_hours: float = 8.0
var _population: int = 0
var _treasury: float = 0.0
var _r_demand: float = 50.0
var _c_demand: float = 50.0
var _i_demand: float = 50.0
var _history_size: int = 40
var _pop_history: Array = []
var _treasury_history: Array = []
var _vehicle_count: int = 0
var _congestion_factor: float = 1.0
var _commuters: int = 0

func _ready() -> void:
	_build_controller = get_node(build_controller_path)
	_traffic_controller = get_node_or_null(traffic_controller_path)
	_stats_label = get_node_or_null(stats_label_path)
	_treasury = starting_treasury

	if _build_controller.has_signal("about_to_save"):
		_build_controller.connect("about_to_save", Callable(self, "_on_about_to_save"))
	if _build_controller.has_signal("city_loaded"):
		_build_controller.connect("city_loaded", Callable(self, "_on_city_loaded"))
	if _traffic_controller != null and _traffic_controller.has_signal("traffic_changed"):
		_traffic_controller.connect("traffic_changed", Callable(self, "_on_traffic_changed"))

	_update_stats_label()

func _process(delta: float) -> void:
	_accum += delta
	while _accum >= tick_seconds:
		_accum -= tick_seconds
		_tick_simulation()
	_update_stats_label()

func _tick_simulation() -> void:
	var snapshot_variant: Variant = _build_controller.call("get_city_snapshot")
	if typeof(snapshot_variant) != TYPE_DICTIONARY:
		return
	var snapshot: Dictionary = snapshot_variant

	var roads: int = int(snapshot.get("road_count", 0))
	var res_zones: int = int(snapshot.get("residential_zones", 0))
	var com_zones: int = int(snapshot.get("commercial_zones", 0))
	var ind_zones: int = int(snapshot.get("industrial_zones", 0))

	var res_capacity: int = res_zones * 12
	var com_jobs: int = com_zones * 8
	var ind_jobs: int = ind_zones * 14
	var jobs_capacity: int = com_jobs + ind_jobs

	var desired_population: int = mini(res_capacity, int(float(jobs_capacity) * 1.15))
	if desired_population > _population:
		var growth: int = maxi(1, int(ceil(float(desired_population - _population) * 0.08)))
		_population += growth
	elif desired_population < _population:
		var decline: int = maxi(1, int(ceil(float(_population - desired_population) * 0.05)))
		_population -= decline

	_population = clampi(_population, 0, res_capacity)

	var tax_income: float = float(_population) * 1.8 + float(com_zones) * 4.0 + float(ind_zones) * 5.5
	var service_cost: float = float(roads) * 1.4 + float(_population) * 0.7 + 40.0
	service_cost += float(_vehicle_count) * 0.25
	tax_income += float(_commuters) * 0.2
	_treasury += tax_income - service_cost

	_r_demand = clampf(50.0 + float(jobs_capacity - _population) * 0.25 - float(res_zones) * 0.4, 0.0, 100.0)
	_c_demand = clampf(45.0 + float(_population - com_jobs) * 0.30 + float(roads) * 0.08, 0.0, 100.0)
	_i_demand = clampf(40.0 + float(_population - ind_jobs) * 0.22 + float(roads) * 0.06 - float(_vehicle_count) * 0.5, 0.0, 100.0)

	_sim_hours += 0.25
	if _sim_hours >= 24.0:
		_sim_hours -= 24.0

	# Zone growth/decay logic every tick
	_apply_zone_growth(snapshot)

	# record history
	_pop_history.append(_population)
	_treasury_history.append(int(round(_treasury)))
	if _pop_history.size() > _history_size:
		_pop_history.remove_at(0)
	if _treasury_history.size() > _history_size:
		_treasury_history.remove_at(0)

func _apply_zone_growth(snapshot: Dictionary) -> void:
	# snapshot contains zones_detail with x,y,type,level,connected
	for z in snapshot.get("zones_detail", []):
		var ztype: int = int(z.get("type", 1))
		var level: int = int(z.get("level", 1))
		var connected: bool = bool(z.get("connected", false))
		var cell := Vector2i(int(z.get("x", 0)), int(z.get("y", 0)))
		# Determine relevant demand
		var demand: float = 50.0
		match ztype:
			BuildMode.RESIDENTIAL:
				demand = _r_demand
			BuildMode.COMMERCIAL:
				demand = _c_demand
			BuildMode.INDUSTRIAL:
				demand = _i_demand

		# Upgrade if demand strong and connected
		if demand >= 70.0 and connected and level < 3:
			_build_controller.call("set_zone_level", cell, level + 1)
		# Downgrade if demand weak
		elif demand <= 30.0 and level > 1:
			_build_controller.call("set_zone_level", cell, level - 1)

func _update_stats_label() -> void:
	if _stats_label == null:
		return

	var snapshot_variant: Variant = _build_controller.call("get_city_snapshot")
	var roads: int = 0
	var res_zones: int = 0
	var com_zones: int = 0
	var ind_zones: int = 0
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		var snapshot: Dictionary = snapshot_variant
		roads = int(snapshot.get("road_count", 0))
		res_zones = int(snapshot.get("residential_zones", 0))
		com_zones = int(snapshot.get("commercial_zones", 0))
		ind_zones = int(snapshot.get("industrial_zones", 0))

	var jobs_capacity: int = com_zones * 8 + ind_zones * 14
	var employed: int = mini(_population, jobs_capacity)
	var unemployment: int = maxi(_population - employed, 0)
	var households: int = int(round(float(_population) / 2.6))

	_stats_label.text = "Time %02d:%02d  |  Pop %d  HH %d  Jobs %d  Unemp %d  Treasury $%d\nRoads %d  Zones R:%d C:%d I:%d  |  Demand R:%d C:%d I:%d  |  Traffic %d  Cong %.2f  Comm %d" % [
		int(floor(_sim_hours)),
		int(round((_sim_hours - floor(_sim_hours)) * 60.0)) % 60,
		_population,
		households,
		employed,
		unemployment,
		int(round(_treasury)),
		roads,
		res_zones,
		com_zones,
		ind_zones,
		int(round(_r_demand)),
		int(round(_c_demand)),
		int(round(_i_demand)),
		_vehicle_count,
		_congestion_factor,
		_commuters
	]

	# append simple sparkline for population
	var spark := _make_sparkline(_pop_history)
	_stats_label.text += "\nPop: " + spark

func _make_sparkline(data: Array) -> String:
	if data.size() == 0:
		return ""
	var blocks := ["▁","▂","▃","▄","▅","▆","▇","█"]
	var mn := 1e9
	var mx := -1e9
	for v in data:
		mn = mini(mn, float(v))
		mx = maxi(mx, float(v))
	if mn == mx:
		mx = mn + 1.0
	var s := ""
	for v in data:
		var t := int(floor((float(v) - mn) / (mx - mn) * float(blocks.size() - 1)))
		t = clamp(t, 0, blocks.size() - 1)
		s += blocks[t]
	return s

func _on_about_to_save(payload: Dictionary) -> void:
	payload["simulation"] = {
		"sim_hours": _sim_hours,
		"population": _population,
		"treasury": _treasury,
		"r_demand": _r_demand,
		"c_demand": _c_demand,
		"i_demand": _i_demand
	}

func _on_city_loaded(payload: Dictionary) -> void:
	var sim_variant: Variant = payload.get("simulation", {})
	if typeof(sim_variant) != TYPE_DICTIONARY:
		return
	var sim: Dictionary = sim_variant

	_sim_hours = float(sim.get("sim_hours", 8.0))
	_population = int(sim.get("population", 0))
	_treasury = float(sim.get("treasury", starting_treasury))
	_r_demand = float(sim.get("r_demand", 50.0))
	_c_demand = float(sim.get("c_demand", 50.0))
	_i_demand = float(sim.get("i_demand", 50.0))

func _on_traffic_changed(vehicle_count: int, congestion_factor: float) -> void:
	_vehicle_count = vehicle_count
	_congestion_factor = clampf(congestion_factor, 0.35, 1.0)
	_commuters = int(round(float(_population) * (1.0 - _congestion_factor) * 0.55))
