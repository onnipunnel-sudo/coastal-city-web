extends Node3D

const PLAYER_SCRIPT: Script = preload("res://scripts/player.gd")
const CAR_SCRIPT: Script = preload("res://scripts/car.gd")
const TOUCH_UI_SCRIPT: Script = preload("res://scripts/touch_controls.gd")
const CHEAT_UI_SCRIPT: Script = preload("res://scripts/cheat_ui.gd")

var player: CharacterBody3D
var car: CharacterBody3D
var _camera_pressed_last_frame := false

func _ready() -> void:
    _setup_input_actions()
    _setup_environment()
    _build_city()
    _spawn_car()
    _spawn_player()
    var touch_ui := CanvasLayer.new()
    touch_ui.name = "PPSSPPLikeTouchControls"
    touch_ui.set_script(TOUCH_UI_SCRIPT)
    add_child(touch_ui)
    var cheat_ui := CanvasLayer.new()
    cheat_ui.name = "CheatUI"
    cheat_ui.set_script(CHEAT_UI_SCRIPT)
    add_child(cheat_ui)

func _process(_delta: float) -> void:
    if player == null or car == null:
        return
    var cheat_ui := get_node_or_null("CheatUI")
    if cheat_ui != null and cheat_ui.has_method("is_panel_open") and bool(cheat_ui.is_panel_open()):
        return
    if Input.is_action_just_pressed("interact"):
        if player.in_vehicle:
            player.exit_vehicle()
        elif player.global_position.distance_to(car.global_position) < 5.0:
            player.enter_vehicle(car)

func _setup_input_actions() -> void:
    var action_keys := {
        "move_forward": [KEY_W, KEY_UP],
        "move_back": [KEY_S, KEY_DOWN],
        "move_left": [KEY_A, KEY_LEFT],
        "move_right": [KEY_D, KEY_RIGHT],
        "jump": [KEY_SPACE],
        "sprint": [KEY_SHIFT],
        "interact": [KEY_E],
        "camera_toggle": [KEY_C],
        "look_up": [KEY_I],
        "look_down": [KEY_K],
        "look_left": [KEY_J],
        "look_right": [KEY_L],
        "weapon_switch": [KEY_Q]
    }
    for action_name in action_keys.keys():
        var action := StringName(action_name)
        if not InputMap.has_action(action):
            InputMap.add_action(action)
        for keycode in action_keys[action_name]:
            var event := InputEventKey.new()
            event.physical_keycode = keycode
            if not InputMap.action_has_event(action, event):
                InputMap.action_add_event(action, event)
    if not InputMap.has_action("fire"):
        InputMap.add_action("fire")
    var mouse_event := InputEventMouseButton.new()
    mouse_event.button_index = MOUSE_BUTTON_LEFT
    if not InputMap.action_has_event("fire", mouse_event):
        InputMap.action_add_event("fire", mouse_event)

func _setup_environment() -> void:
    var world_env := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color(0.10, 0.24, 0.49)
    sky_mat.sky_horizon_color = Color(0.97, 0.56, 0.55)
    sky_mat.ground_bottom_color = Color(0.08, 0.10, 0.16)
    sky_mat.ground_horizon_color = Color(0.72, 0.47, 0.46)
    sky.sky_material = sky_mat
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.67, 0.67, 0.82)
    env.ambient_light_energy = 0.8
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world_env.environment = env
    add_child(world_env)

    var sun := DirectionalLight3D.new()
    sun.name = "LateAfternoonSun"
    sun.rotation_degrees = Vector3(-42.0, -28.0, 0.0)
    sun.light_energy = 1.25
    sun.shadow_enabled = true
    add_child(sun)

func _make_material(color: Color, emission: Color = Color.BLACK, roughness: float = 0.78) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = roughness
    if emission != Color.BLACK:
        mat.emission_enabled = true
        mat.emission = emission
        mat.emission_energy_multiplier = 0.65
    return mat

func _add_box(name: String, pos: Vector3, size: Vector3, color: Color, collision: bool = false, emission: Color = Color.BLACK) -> Node3D:
    var box_mesh := BoxMesh.new()
    box_mesh.size = size
    var mat := _make_material(color, emission)
    if collision:
        var body := StaticBody3D.new()
        body.name = name
        body.position = pos
        add_child(body)
        var mesh := MeshInstance3D.new()
        mesh.name = "Visual"
        mesh.mesh = box_mesh
        mesh.material_override = mat
        body.add_child(mesh)
        var shape := BoxShape3D.new()
        shape.size = size
        var collider := CollisionShape3D.new()
        collider.shape = shape
        body.add_child(collider)
        return body
    var instance := MeshInstance3D.new()
    instance.name = name
    instance.mesh = box_mesh
    instance.position = pos
    instance.material_override = mat
    add_child(instance)
    return instance

func _add_cylinder(parent: Node3D, name: String, pos: Vector3, height: float, radius: float, color: Color) -> MeshInstance3D:
    var cylinder := CylinderMesh.new()
    cylinder.height = height
    cylinder.top_radius = radius
    cylinder.bottom_radius = radius
    var mi := MeshInstance3D.new()
    mi.name = name
    mi.mesh = cylinder
    mi.position = pos
    mi.material_override = _make_material(color)
    parent.add_child(mi)
    return mi

func _build_city() -> void:
    # Ground and waterfront. These are original procedural placeholder assets.
    _add_box("GroundCollision", Vector3(0, -0.5, -10), Vector3(280, 1, 250), Color(0.32, 0.43, 0.30), true)
    _add_box("BeachSand", Vector3(0, 0.015, 106), Vector3(280, 0.08, 20), Color(0.82, 0.70, 0.48))
    _add_box("Ocean", Vector3(0, -0.12, 155), Vector3(300, 0.12, 82), Color(0.04, 0.39, 0.59), false, Color(0.02, 0.12, 0.20))

    # Streets at regular intervals, with sidewalks and central pastel-gold lines.
    for i in range(-3, 4):
        var lane := float(i * 28)
        _add_box("RoadEastWest_%d" % i, Vector3(0, 0.025, lane), Vector3(270, 0.12, 8.5), Color(0.105, 0.12, 0.15))
        _add_box("RoadNorthSouth_%d" % i, Vector3(lane, 0.028, -10), Vector3(8.5, 0.12, 250), Color(0.105, 0.12, 0.15))
        _add_box("RoadLineEW_%d" % i, Vector3(0, 0.092, lane), Vector3(270, 0.025, 0.13), Color(0.98, 0.77, 0.35), false, Color(0.15, 0.09, 0.015))
        _add_box("RoadLineNS_%d" % i, Vector3(lane, 0.094, -10), Vector3(0.13, 0.025, 250), Color(0.98, 0.77, 0.35), false, Color(0.15, 0.09, 0.015))
        _add_box("SidewalkEW_A_%d" % i, Vector3(0, 0.07, lane + 5.2), Vector3(270, 0.18, 1.5), Color(0.66, 0.62, 0.57))
        _add_box("SidewalkEW_B_%d" % i, Vector3(0, 0.07, lane - 5.2), Vector3(270, 0.18, 1.5), Color(0.66, 0.62, 0.57))
        _add_box("SidewalkNS_A_%d" % i, Vector3(lane + 5.2, 0.07, -10), Vector3(1.5, 0.18, 250), Color(0.66, 0.62, 0.57))
        _add_box("SidewalkNS_B_%d" % i, Vector3(lane - 5.2, 0.07, -10), Vector3(1.5, 0.18, 250), Color(0.66, 0.62, 0.57))

    var rng := RandomNumberGenerator.new()
    rng.seed = 1986
    var building_colors: Array[Color] = [
        Color(0.80, 0.68, 0.61), Color(0.53, 0.72, 0.78), Color(0.91, 0.77, 0.57),
        Color(0.68, 0.58, 0.76), Color(0.80, 0.80, 0.72), Color(0.72, 0.52, 0.48)
    ]
    for x_idx in range(-3, 3):
        for z_idx in range(-3, 3):
            if rng.randf() < 0.12:
                continue
            var w := rng.randf_range(8.5, 13.2)
            var d := rng.randf_range(8.5, 13.2)
            var h := rng.randf_range(10.0, 28.0)
            var center := Vector3(float(x_idx * 28 + 14), h * 0.5, float(z_idx * 28 + 14))
            var base_color: Color = building_colors[rng.randi_range(0, building_colors.size() - 1)]
            _add_box("Building_%d_%d" % [x_idx, z_idx], center, Vector3(w, h, d), base_color, true)
            # Flat roof cap and simple window strips make the skyline read clearly on mobile.
            _add_box("RoofCap_%d_%d" % [x_idx, z_idx], center + Vector3(0, h * 0.5 + 0.22, 0), Vector3(w * 0.84, 0.44, d * 0.84), Color(0.25, 0.28, 0.34))
            var cols := int(floor(w / 2.5))
            var rows := int(floor((h - 3.0) / 3.0))
            for row in range(max(1, rows)):
                var wy := 2.2 + float(row) * 3.0
                for col in range(max(1, cols)):
                    var wx: float = center.x - w * 0.5 + 1.4 + float(col) * ((w - 2.0) / max(1, cols - 1))
                    if wy < h - 1.0 and wx < center.x + w * 0.5 - 0.5:
                        var win_color := Color(0.08, 0.22, 0.31) if rng.randf() > 0.18 else Color(0.99, 0.63, 0.30)
                        var win_emission := Color(0.0, 0.0, 0.0) if win_color.b > 0.3 else Color(0.25, 0.07, 0.01)
                        _add_box("Window", Vector3(wx, wy, center.z - d * 0.5 - 0.035), Vector3(0.95, 1.05, 0.06), win_color, false, win_emission)

    # Palm trees along the beachfront and selected street corners.
    for i in range(18):
        _add_palm(Vector3(-120.0 + float(i) * 14.0, 0, 93.0))
    for p in [Vector3(-55,0,-55), Vector3(55,0,-55), Vector3(-55,0,55), Vector3(55,0,55), Vector3(-83,0,0), Vector3(83,0,0)]:
        _add_palm(p)

    # A few neon-style hotel signs as original textless light panels.
    _add_box("NeonPinkSign", Vector3(17.2, 15.5, -27.0), Vector3(0.18, 4.2, 2.8), Color(0.92, 0.14, 0.55), false, Color(0.95, 0.06, 0.33))
    _add_box("NeonCyanSign", Vector3(-27.0, 11.5, 17.3), Vector3(2.8, 3.4, 0.18), Color(0.08, 0.75, 0.90), false, Color(0.02, 0.55, 0.9))

func _add_palm(pos: Vector3) -> void:
    var tree := Node3D.new()
    tree.name = "PalmTree"
    tree.position = pos
    add_child(tree)
    _add_cylinder(tree, "Trunk", Vector3(0, 2.3, 0), 4.6, 0.22, Color(0.40, 0.25, 0.14))
    for i in range(7):
        var angle := TAU * float(i) / 7.0
        var leaf := MeshInstance3D.new()
        var leaf_mesh := BoxMesh.new()
        leaf_mesh.size = Vector3(2.8, 0.11, 0.42)
        leaf.mesh = leaf_mesh
        leaf.position = Vector3(cos(angle) * 1.0, 4.4, sin(angle) * 1.0)
        leaf.rotation.y = -angle
        leaf.rotation.z = -0.20
        leaf.material_override = _make_material(Color(0.08, 0.32, 0.18))
        tree.add_child(leaf)

func _spawn_car() -> void:
    car = CharacterBody3D.new()
    car.name = "Convertible"
    car.set_script(CAR_SCRIPT)
    car.position = Vector3(3.5, 0.0, 7.0)
    add_child(car)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(2.1, 0.9, 4.1)
    collision.shape = shape
    collision.position.y = 0.5
    car.add_child(collision)

    _car_box(car, "Body", Vector3(0, 0.48, 0), Vector3(2.1, 0.62, 4.0), Color(0.94, 0.12, 0.42))
    _car_box(car, "Hood", Vector3(0, 0.78, -1.18), Vector3(1.85, 0.2, 1.35), Color(0.98, 0.22, 0.48))
    _car_box(car, "Windshield", Vector3(0, 1.05, -0.15), Vector3(1.6, 0.48, 0.85), Color(0.10, 0.22, 0.30))
    _car_box(car, "RearGlass", Vector3(0, 1.02, 0.8), Vector3(1.5, 0.32, 0.55), Color(0.10, 0.22, 0.30))
    for side in [-1.0, 1.0]:
        for front_back in [-1.0, 1.0]:
            var wheel := MeshInstance3D.new()
            var cylinder := CylinderMesh.new()
            cylinder.height = 0.28
            cylinder.top_radius = 0.38
            cylinder.bottom_radius = 0.38
            wheel.mesh = cylinder
            wheel.position = Vector3(side * 1.0, 0.27, front_back * 1.28)
            wheel.rotation_degrees.z = 90
            wheel.material_override = _make_material(Color(0.035,0.04,0.05))
            car.add_child(wheel)
    var car_pivot := Node3D.new()
    car_pivot.name = "VehicleCameraPivot"
    car_pivot.position = Vector3(0, 1.05, 0)
    car.add_child(car_pivot)
    var car_camera := Camera3D.new()
    car_camera.name = "VehicleCamera"
    car_camera.position = Vector3(0, 2.3, 7.2)
    car_camera.rotation_degrees = Vector3(-18, 0, 0)
    car_camera.current = false
    car_pivot.add_child(car_camera)

func _car_box(parent: Node3D, name: String, pos: Vector3, size: Vector3, color: Color) -> void:
    var mesh := MeshInstance3D.new()
    mesh.name = name
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    mesh.position = pos
    mesh.material_override = _make_material(color, Color.BLACK, 0.35)
    parent.add_child(mesh)

func _spawn_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.set_script(PLAYER_SCRIPT)
    player.position = Vector3(0, 0, -1.8)
    add_child(player)
    var collider := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.42
    capsule.height = 1.85
    collider.shape = capsule
    collider.position.y = 0.92
    player.add_child(collider)
    var visual := MeshInstance3D.new()
    visual.name = "PlayerPlaceholderModel"
    var capsule_mesh := CapsuleMesh.new()
    capsule_mesh.radius = 0.42
    capsule_mesh.height = 1.85
    visual.mesh = capsule_mesh
    visual.position.y = 0.92
    visual.material_override = _make_material(Color(0.03, 0.68, 0.72), Color(0.0, 0.08, 0.08), 0.9)
    player.add_child(visual)
    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.24
    head_mesh.height = 0.48
    head.mesh = head_mesh
    head.position = Vector3(0, 1.86, 0)
    head.material_override = _make_material(Color(0.74, 0.52, 0.38))
    player.add_child(head)
    var camera_pivot := Node3D.new()
    camera_pivot.name = "CameraPivot"
    camera_pivot.position = Vector3(0, 1.35, 0)
    player.add_child(camera_pivot)
    var camera := Camera3D.new()
    camera.name = "PlayerCamera"
    camera.position = Vector3(0, 1.8, 7.1)
    camera.rotation_degrees = Vector3(-17, 0, 0)
    camera.current = true
    camera_pivot.add_child(camera)
