extends CharacterBody3D

@export var max_speed: float = 19.0
@export var acceleration: float = 10.0
@export var braking: float = 18.0
@export var steering_speed: float = 1.55

var drivable := false
var speed := 0.0
var _camera_pivot: Node3D
var _camera_close := false

func _ready() -> void:
    _camera_pivot = get_node_or_null("VehicleCameraPivot") as Node3D

func set_drivable(value: bool) -> void:
    drivable = value
    if not drivable:
        speed = 0.0
        velocity = Vector3.ZERO

func _physics_process(delta: float) -> void:
    if _camera_pivot == null:
        _camera_pivot = get_node_or_null("VehicleCameraPivot") as Node3D
    if not drivable:
        return
    if _camera_pivot != null:
        var look_x := Input.get_action_strength("look_right") - Input.get_action_strength("look_left")
        var look_y := Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
        _camera_pivot.rotation.y -= look_x * delta * 1.8
        _camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x + look_y * delta * 1.1, -0.45, 0.38)
    if Input.is_action_just_pressed("camera_toggle"):
        _camera_close = not _camera_close
        var cam := get_node_or_null("VehicleCameraPivot/VehicleCamera") as Camera3D
        if cam != null:
            cam.position.z = 5.1 if _camera_close else 7.2
            cam.position.y = 1.8 if _camera_close else 2.3
    var throttle := Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
    var steer := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
    if abs(throttle) > 0.01:
        speed = move_toward(speed, throttle * max_speed, acceleration * delta)
    else:
        speed = move_toward(speed, 0.0, braking * delta)
    var steer_factor: float = clamp(abs(speed) / max_speed, 0.18, 1.0)
    rotation.y -= steer * steering_speed * steer_factor * delta * sign(speed if abs(speed) > 0.05 else 1.0)
    var forward := -global_transform.basis.z
    velocity.x = forward.x * speed
    velocity.z = forward.z * speed
    velocity.y = 0.0
    move_and_slide()
