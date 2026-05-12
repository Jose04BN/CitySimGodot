extends Camera3D

@export var move_speed: float = 18.0
@export var zoom_speed: float = 4.0
@export var min_height: float = 8.0
@export var max_height: float = 60.0
@export var rotate_speed: float = 0.006

var _yaw: float = -0.78
var _pitch: float = -0.62
var _pivot: Vector3 = Vector3(20.0, 0.0, 20.0)
var _is_rotating: bool = false

func _ready() -> void:
	_update_transform()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_is_rotating = event.pressed
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom(-zoom_speed)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom(zoom_speed)

	if event is InputEventMouseMotion and _is_rotating:
		_yaw -= event.relative.x * rotate_speed
		_pitch = clamp(_pitch - event.relative.y * rotate_speed, -1.2, -0.2)
		_update_transform()

func _process(delta: float) -> void:
	var move_input: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_W):
		move_input.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		move_input.y += 1.0
	if Input.is_key_pressed(KEY_A):
		move_input.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		move_input.x += 1.0

	if move_input != Vector2.ZERO:
		move_input = move_input.normalized()
		var forward: Vector3 = Vector3(sin(_yaw), 0.0, cos(_yaw)).normalized()
		var right: Vector3 = Vector3(forward.z, 0.0, -forward.x)
		_pivot += (right * move_input.x + forward * move_input.y) * move_speed * delta
		_update_transform()

func _zoom(amount: float) -> void:
	var current_height: float = global_position.y
	var target_height: float = clampf(current_height + amount, min_height, max_height)
	var delta_h: float = target_height - current_height
	_pivot += Vector3(0.0, delta_h * 0.55, 0.0)
	position.y = target_height
	_update_transform()

func _update_transform() -> void:
	var distance: float = maxf(position.y * 1.2, 10.0)
	var offset: Vector3 = Vector3(
		sin(_yaw) * cos(_pitch),
		sin(-_pitch),
		cos(_yaw) * cos(_pitch)
	) * distance
	global_position = _pivot + offset
	look_at(_pivot, Vector3.UP)
