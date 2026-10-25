extends CanvasLayer

# Touch layout inspired by the familiar PPSSPP handheld emulator layout.
# It is an original UI; no emulator assets are copied.

var _fire_button: Button = null
var _switch_button: Button = null
var _weapon_label: Label = null

func _ready() -> void:
    var layer := Control.new()
    layer.name = "ControlsOverlay"
    layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.mouse_filter = Control.MOUSE_FILTER_PASS
    add_child(layer)

    var title := Label.new()
    title.text = "COASTAL CITY  |  PROTOTYPE"
    title.set_anchors_preset(Control.PRESET_TOP_LEFT)
    title.offset_left = 22
    title.offset_top = 18
    title.offset_right = 460
    title.offset_bottom = 52
    title.add_theme_font_size_override("font_size", 21)
    title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.86, 0.95))
    title.add_theme_color_override("font_shadow_color", Color(0,0,0,0.8))
    title.add_theme_constant_override("shadow_offset_x", 2)
    title.add_theme_constant_override("shadow_offset_y", 2)
    layer.add_child(title)

    var hint := Label.new()
    hint.text = "E / INTERACT: enter or exit the pink car"
    hint.set_anchors_preset(Control.PRESET_TOP_LEFT)
    hint.offset_left = 22
    hint.offset_top = 52
    hint.offset_right = 450
    hint.offset_bottom = 80
    hint.add_theme_font_size_override("font_size", 15)
    hint.add_theme_color_override("font_color", Color(1,1,1,0.78))
    layer.add_child(hint)

    # Left directional pad.
    _add_button(layer, "▲", "move_forward", Control.PRESET_BOTTOM_LEFT, Rect2(84, -244, 72, 64), 27)
    _add_button(layer, "▼", "move_back", Control.PRESET_BOTTOM_LEFT, Rect2(84, -100, 72, 64), 27)
    _add_button(layer, "◀", "move_left", Control.PRESET_BOTTOM_LEFT, Rect2(12, -172, 72, 64), 27)
    _add_button(layer, "▶", "move_right", Control.PRESET_BOTTOM_LEFT, Rect2(156, -172, 72, 64), 27)

    # Right-side PPSSPP-style face-button diamond: Y / X / B / A.
    _add_button(layer, "Y", "camera_toggle", Control.PRESET_BOTTOM_RIGHT, Rect2(-174, -250, 70, 66), 24, Color(0.25,0.70,0.92,0.76))
    _add_button(layer, "X", "sprint", Control.PRESET_BOTTOM_RIGHT, Rect2(-244, -180, 70, 66), 24, Color(0.48,0.83,0.48,0.76))
    _add_button(layer, "B", "jump", Control.PRESET_BOTTOM_RIGHT, Rect2(-104, -180, 70, 66), 24, Color(0.96,0.40,0.40,0.76))
    _add_button(layer, "A", "interact", Control.PRESET_BOTTOM_RIGHT, Rect2(-174, -110, 70, 66), 24, Color(0.96,0.72,0.28,0.78))

    # L/R buttons and START/SELECT-like small buttons.
    _add_button(layer, "L", "look_left", Control.PRESET_TOP_LEFT, Rect2(22, 92, 62, 46), 18, Color(0.20,0.24,0.31,0.68))
    _add_button(layer, "R", "look_right", Control.PRESET_TOP_LEFT, Rect2(92, 92, 62, 46), 18, Color(0.20,0.24,0.31,0.68))
    _add_button(layer, "SELECT", "look_down", Control.PRESET_TOP_LEFT, Rect2(530, 20, 92, 40), 13, Color(0.18,0.20,0.26,0.70))
    _add_button(layer, "START", "look_up", Control.PRESET_TOP_LEFT, Rect2(636, 20, 92, 40), 13, Color(0.18,0.20,0.26,0.70))

    # Weapon buttons, hidden until a cheat grants weapons.
    _fire_button = _add_button(layer, "FIRE", "fire", Control.PRESET_BOTTOM_RIGHT, Rect2(-229, -330, 110, 60), 22, Color(0.85,0.15,0.15,0.85))
    _fire_button.visible = false
    _switch_button = _add_button(layer, "SWITCH", "weapon_switch", Control.PRESET_BOTTOM_RIGHT, Rect2(-104, -330, 90, 60), 16, Color(0.20,0.30,0.50,0.80))
    _switch_button.visible = false
    _weapon_label = Label.new()
    _weapon_label.name = "WeaponLabel"
    _weapon_label.text = "Weapon: —"
    _weapon_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
    _weapon_label.offset_left = 760
    _weapon_label.offset_top = 20
    _weapon_label.offset_right = 1160
    _weapon_label.offset_bottom = 56
    _weapon_label.add_theme_font_size_override("font_size", 18)
    _weapon_label.add_theme_color_override("font_color", Color(1,1,1,0.85))
    layer.add_child(_weapon_label)

func _add_button(parent: Control, caption: String, action_name: String, preset: int, rect: Rect2, font_size: int, tint: Color = Color(0.12,0.15,0.22,0.72)) -> Button:
    var button := Button.new()
    button.name = "Touch_" + caption
    button.text = caption
    button.set_anchors_preset(preset)
    button.offset_left = rect.position.x
    button.offset_top = rect.position.y
    button.offset_right = rect.position.x + rect.size.x
    button.offset_bottom = rect.position.y + rect.size.y
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", font_size)
    button.add_theme_color_override("font_color", Color(1,1,1,0.96))
    button.add_theme_color_override("font_pressed_color", Color(1,1,1,1))
    var normal := StyleBoxFlat.new()
    normal.bg_color = tint
    normal.corner_radius_top_left = 18
    normal.corner_radius_top_right = 18
    normal.corner_radius_bottom_left = 18
    normal.corner_radius_bottom_right = 18
    normal.border_width_left = 2
    normal.border_width_top = 2
    normal.border_width_right = 2
    normal.border_width_bottom = 2
    normal.border_color = Color(1,1,1,0.45)
    normal.shadow_color = Color(0,0,0,0.28)
    normal.shadow_size = 4
    button.add_theme_stylebox_override("normal", normal)
    var pressed := normal.duplicate() as StyleBoxFlat
    pressed.bg_color = Color(tint.r, tint.g, tint.b, min(1.0, tint.a + 0.2))
    button.add_theme_stylebox_override("pressed", pressed)
    var hover := normal.duplicate() as StyleBoxFlat
    hover.bg_color = Color(tint.r, tint.g, tint.b, min(1.0, tint.a + 0.1))
    button.add_theme_stylebox_override("hover", hover)
    button.button_down.connect(_press_action.bind(StringName(action_name)))
    button.button_up.connect(_release_action.bind(StringName(action_name)))
    parent.add_child(button)
    return button

func set_weapons_ui_visible(v: bool) -> void:
    if _fire_button != null:
        _fire_button.visible = v
    if _switch_button != null:
        _switch_button.visible = v

func set_weapon_label(text: String) -> void:
    if _weapon_label != null:
        _weapon_label.text = "Weapon: " + text

func _press_action(action_name: StringName) -> void:
    if InputMap.has_action(action_name):
        Input.action_press(action_name)

func _release_action(action_name: StringName) -> void:
    if InputMap.has_action(action_name):
        Input.action_release(action_name)
