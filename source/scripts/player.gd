extends CharacterBody3D

@export var walk_speed: float = 5.4
@export var sprint_speed: float = 8.2
@export var jump_velocity: float = 5.3
@export var gravity: float = 18.0

var in_vehicle := false
var vehicle: CharacterBody3D
var _camera_close := false
var _camera: Camera3D
var _camera_pivot: Node3D

func _ready() -> void:
    _camera_pivot = get_node_or_null("CameraPivot") as Node3D
    if _camera_pivot != null:
        _camera = _camera_pivot.get_node_or_null("PlayerCamera") as Camera3D

func _physics_process(delta: float) -> void:
    # Children are assembled by world.gd after the player enters the scene tree.
    if _camera_pivot == null:
        _camera_pivot = get_node_or_null("CameraPivot") as Node3D
        if _camera_pivot != null:
            _camera = _camera_pivot.get_node_or_null("PlayerCamera") as Camera3D
    if in_vehicle:
        return
    var direction := Vector3(
        Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
        0.0,
        Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
    )
    if direction.length() > 1.0:
        direction = direction.normalized()
    var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
    velocity.x = direction.x * speed
    velocity.z = direction.z * speed

    if not is_on_floor():
        velocity.y -= gravity * delta
    elif Input.is_action_just_pressed("jump"):
        velocity.y = jump_velocity
    else:
        velocity.y = 0.0
    move_and_slide()

    if _camera_pivot != null:
        var look_x := Input.get_action_strength("look_right") - Input.get_action_strength("look_left")
        var look_y := Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
        _camera_pivot.rotation.y -= look_x * delta * 1.8
        _camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x + look_y * delta * 1.1, -0.45, 0.38)
    if Input.is_action_just_pressed("camera_toggle") and _camera != null:
        _camera_close = not _camera_close
        if _camera_close:
            _camera.position = Vector3(0, 1.45, 4.7)
            _camera.rotation_degrees = Vector3(-12, 0, 0)
        else:
            _camera.position = Vector3(0, 1.8, 7.1)
            _camera.rotation_degrees = Vector3(-17, 0, 0)

func enter_vehicle(target: CharacterBody3D) -> void:
    in_vehicle = true
    vehicle = target
    visible = false
    collision_layer = 0
    collision_mask = 0
    if vehicle.has_method("set_drivable"):
        vehicle.set_drivable(true)
    var vehicle_camera := vehicle.get_node_or_null("VehicleCameraPivot/VehicleCamera") as Camera3D
    if vehicle_camera != null:
        vehicle_camera.current = true
    if _camera != null:
        _camera.current = false

func exit_vehicle() -> void:
    if not in_vehicle or vehicle == null:
        return
    global_position = vehicle.global_position + vehicle.global_transform.basis.x * 2.3 + Vector3(0, 0.1, 0)
    in_vehicle = false
    visible = true
    collision_layer = 1
    collision_mask = 1
    if vehicle.has_method("set_drivable"):
        vehicle.set_drivable(false)
    var vehicle_camera := vehicle.get_node_or_null("VehicleCameraPivot/VehicleCamera") as Camera3D
    if vehicle_camera != null:
        vehicle_camera.current = false
    if _camera != null:
        _camera.current = true
    vehicle = null
