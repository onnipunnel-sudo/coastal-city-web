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

# Weapons, granted by the "thugstools" cheat code (professional set).
var weapons_armed := false
var weapon_index := 0
var _fire_cooldown: float = 0.0
var _gun: Node3D = null
var _muzzle_offset: Vector3 = Vector3(0.52, 1.28, -0.75)
var _tracers: Array = []
var _flashes: Array = []
var _cheat_ui: Node = null

const WEAPONS: Array[Dictionary] = [
    {"name": "Pistol", "interval": 0.35, "body_len": 0.28, "barrel_len": 0.22, "color": Color(0.22, 0.22, 0.24)},
    {"name": "Rifle", "interval": 0.12, "body_len": 0.42, "barrel_len": 0.55, "color": Color(0.08, 0.08, 0.10)},
]

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
    var cheat_open := _is_cheat_open()
    var direction := Vector3(
        Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
        0.0,
        Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
    )
    if direction.length() > 1.0:
        direction = direction.normalized()
    if cheat_open:
        direction = Vector3.ZERO
    var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
    velocity.x = direction.x * speed
    velocity.z = direction.z * speed

    if not is_on_floor():
        velocity.y -= gravity * delta
    elif Input.is_action_just_pressed("jump") and not cheat_open:
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
    if not cheat_open and weapons_armed:
        if Input.is_action_just_pressed("weapon_switch"):
            _switch_weapon()
        if Input.is_action_pressed("fire") and _fire_cooldown <= 0.0:
            _fire()

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

func _is_cheat_open() -> bool:
    if _cheat_ui == null:
        _cheat_ui = get_parent().get_node_or_null("CheatUI")
    if _cheat_ui != null and _cheat_ui.has_method("is_panel_open"):
        return bool(_cheat_ui.is_panel_open())
    return false

func _process(delta: float) -> void:
    if _fire_cooldown > 0.0:
        _fire_cooldown -= delta
    for i in range(_tracers.size() - 1, -1, -1):
        var entry: Dictionary = _tracers[i]
        var age: float = float(entry["age"]) + delta
        entry["age"] = age
        if age > 0.09:
            var mesh: Node3D = entry["mesh"]
            mesh.queue_free()
            _tracers.remove_at(i)
    for i in range(_flashes.size() - 1, -1, -1):
        var entry: Dictionary = _flashes[i]
        var age: float = float(entry["age"]) + delta
        entry["age"] = age
        var mesh: MeshInstance3D = entry["mesh"]
        var s: float = max(0.0, 1.0 - age / 0.25)
        mesh.scale = Vector3.ONE * s
        if age > 0.25:
            mesh.queue_free()
            _flashes.remove_at(i)

func grant_professional_weapons() -> void:
    weapons_armed = true
    weapon_index = 1
    _rebuild_gun()
    var ui := get_parent().get_node_or_null("PPSSPPLikeTouchControls")
    if ui != null and ui.has_method("set_weapons_ui_visible"):
        ui.set_weapons_ui_visible(true)
    if ui != null and ui.has_method("set_weapon_label"):
        ui.set_weapon_label(String(WEAPONS[weapon_index]["name"]))

func _switch_weapon() -> void:
    if not weapons_armed:
        return
    weapon_index = (weapon_index + 1) % WEAPONS.size()
    _rebuild_gun()
    var ui := get_parent().get_node_or_null("PPSSPPLikeTouchControls")
    if ui != null and ui.has_method("set_weapon_label"):
        ui.set_weapon_label(String(WEAPONS[weapon_index]["name"]))

func _gun_material(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.45
    mat.metallic = 0.35
    return mat

func _rebuild_gun() -> void:
    if _gun != null:
        _gun.queue_free()
        _gun = null
    var w: Dictionary = WEAPONS[weapon_index]
    var body_len: float = float(w["body_len"])
    var barrel_len: float = float(w["barrel_len"])
    var col: Color = w["color"]
    _gun = Node3D.new()
    _gun.name = "Gun"
    _gun.position = Vector3(0.52, 1.28, 0.0)
    add_child(_gun)
    var body := MeshInstance3D.new()
    var body_mesh := BoxMesh.new()
    body_mesh.size = Vector3(0.09, 0.13, body_len)
    body.mesh = body_mesh
    body.material_override = _gun_material(col)
    _gun.add_child(body)
    var barrel := MeshInstance3D.new()
    var barrel_mesh := CylinderMesh.new()
    barrel_mesh.height = barrel_len
    barrel_mesh.top_radius = 0.035
    barrel_mesh.bottom_radius = 0.035
    barrel.mesh = barrel_mesh
    barrel.rotation.x = PI / 2.0
    barrel.position = Vector3(0, 0.02, -(body_len * 0.5 + barrel_len * 0.5 - 0.05))
    barrel.material_override = _gun_material(Color(0.05, 0.05, 0.06))
    _gun.add_child(barrel)
    _muzzle_offset = Vector3(0.52, 1.28, -(body_len * 0.5 + barrel_len))

func _fire() -> void:
    var w: Dictionary = WEAPONS[weapon_index]
    _fire_cooldown = float(w["interval"])
    if _camera == null:
        return
    var from: Vector3 = _camera.global_position
    var dir: Vector3 = -_camera.global_transform.basis.z
    var to: Vector3 = from + dir * 80.0
    var space := get_world_3d().direct_space_state
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [get_rid()]
    var hit: Dictionary = space.intersect_ray(query)
    var end: Vector3 = to
    if not hit.is_empty():
        end = hit["position"]
        _spawn_flash(end)
    _spawn_tracer(to_global(_muzzle_offset), end)

func _spawn_tracer(from: Vector3, to: Vector3) -> void:
    var length: float = from.distance_to(to)
    if length < 0.5:
        return
    var tracer := MeshInstance3D.new()
    var tracer_mesh := BoxMesh.new()
    tracer_mesh.size = Vector3(0.035, 0.035, length)
    tracer.mesh = tracer_mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(1.0, 0.75, 0.2)
    mat.emission_enabled = true
    mat.emission = Color(1.0, 0.6, 0.1)
    mat.emission_energy_multiplier = 2.0
    tracer.material_override = mat
    tracer.position = (from + to) * 0.5
    tracer.look_at(to, Vector3.UP)
    get_parent().add_child(tracer)
    _tracers.append({"mesh": tracer, "age": 0.0})

func _spawn_flash(pos: Vector3) -> void:
    var flash := MeshInstance3D.new()
    var flash_mesh := SphereMesh.new()
    flash_mesh.radius = 0.14
    flash_mesh.height = 0.28
    flash.mesh = flash_mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(1.0, 0.55, 0.1)
    mat.emission_enabled = true
    mat.emission = Color(1.0, 0.5, 0.05)
    mat.emission_energy_multiplier = 2.5
    flash.material_override = mat
    flash.position = pos
    get_parent().add_child(flash)
    _flashes.append({"mesh": flash, "age": 0.0})
