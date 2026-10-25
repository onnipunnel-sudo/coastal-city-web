extends CanvasLayer

# Cheat-code entry UI: a small keyboard icon on screen opens a panel with an
# on-screen keyboard, so codes can be entered on phones without a physical
# keyboard. Code "thugstools" grants the professional weapon set.

var _overlay: ColorRect = null
var _panel: Panel = null
var _display: Label = null
var _message: Label = null
var _typed: String = ""

func _ready() -> void:
    _build_ui()

func is_panel_open() -> bool:
    return _overlay != null and _overlay.visible

func _build_ui() -> void:
    var icon := Button.new()
    icon.name = "CheatKeyboardIcon"
    icon.text = "⌨ KEY"
    icon.tooltip_text = "Cheat keyboard"
    icon.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    icon.offset_left = -104
    icon.offset_top = 16
    icon.offset_right = -16
    icon.offset_bottom = 64
    icon.focus_mode = Control.FOCUS_NONE
    icon.add_theme_font_size_override("font_size", 20)
    icon.pressed.connect(_on_icon_pressed)
    add_child(icon)

    _overlay = ColorRect.new()
    _overlay.name = "CheatOverlay"
    _overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _overlay.color = Color(0, 0, 0, 0.45)
    _overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    _overlay.visible = false
    add_child(_overlay)

    _panel = Panel.new()
    _panel.set_anchors_preset(Control.PRESET_CENTER)
    _panel.offset_left = -320
    _panel.offset_top = -210
    _panel.offset_right = 320
    _panel.offset_bottom = 210
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.10, 0.12, 0.18, 0.97)
    style.corner_radius_top_left = 16
    style.corner_radius_top_right = 16
    style.corner_radius_bottom_left = 16
    style.corner_radius_bottom_right = 16
    style.border_width_left = 2
    style.border_width_top = 2
    style.border_width_right = 2
    style.border_width_bottom = 2
    style.border_color = Color(1, 1, 1, 0.35)
    _panel.add_theme_stylebox_override("panel", style)
    _overlay.add_child(_panel)

    var vbox := VBoxContainer.new()
    vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    vbox.offset_left = 18
    vbox.offset_top = 14
    vbox.offset_right = -18
    vbox.offset_bottom = -14
    vbox.add_theme_constant_override("separation", 10)
    _panel.add_child(vbox)

    var title_row := HBoxContainer.new()
    var title := Label.new()
    title.text = "CHEAT CODE"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_font_size_override("font_size", 24)
    title_row.add_child(title)
    var close_btn := Button.new()
    close_btn.text = "X"
    close_btn.custom_minimum_size = Vector2(44, 44)
    close_btn.focus_mode = Control.FOCUS_NONE
    close_btn.pressed.connect(_on_close_pressed)
    title_row.add_child(close_btn)
    vbox.add_child(title_row)

    _display = Label.new()
    _display.text = "Enter cheat code"
    _display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _display.add_theme_font_size_override("font_size", 24)
    vbox.add_child(_display)

    _message = Label.new()
    _message.text = ""
    _message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _message.add_theme_font_size_override("font_size", 18)
    vbox.add_child(_message)

    _add_key_row(vbox, ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"])
    _add_key_row(vbox, ["A", "S", "D", "F", "G", "H", "J", "K", "L"])
    _add_key_row(vbox, ["Z", "X", "C", "V", "B", "N", "M"])

    var bottom := HBoxContainer.new()
    bottom.alignment = BoxContainer.ALIGNMENT_CENTER
    bottom.add_theme_constant_override("separation", 8)
    var back_btn := Button.new()
    back_btn.text = "⌫"
    back_btn.custom_minimum_size = Vector2(64, 54)
    back_btn.focus_mode = Control.FOCUS_NONE
    back_btn.add_theme_font_size_override("font_size", 20)
    back_btn.pressed.connect(_on_backspace)
    bottom.add_child(back_btn)
    var clear_btn := Button.new()
    clear_btn.text = "Clear"
    clear_btn.custom_minimum_size = Vector2(84, 54)
    clear_btn.focus_mode = Control.FOCUS_NONE
    clear_btn.add_theme_font_size_override("font_size", 18)
    clear_btn.pressed.connect(_on_clear)
    bottom.add_child(clear_btn)
    var enter_btn := Button.new()
    enter_btn.text = "ENTER ✓"
    enter_btn.custom_minimum_size = Vector2(120, 54)
    enter_btn.focus_mode = Control.FOCUS_NONE
    enter_btn.add_theme_font_size_override("font_size", 18)
    enter_btn.pressed.connect(_on_submit)
    bottom.add_child(enter_btn)
    vbox.add_child(bottom)

func _add_key_row(parent: VBoxContainer, keys: Array[String]) -> void:
    var row := HBoxContainer.new()
    row.alignment = BoxContainer.ALIGNMENT_CENTER
    row.add_theme_constant_override("separation", 6)
    for k in keys:
        var b := Button.new()
        b.text = k
        b.custom_minimum_size = Vector2(52, 54)
        b.focus_mode = Control.FOCUS_NONE
        b.add_theme_font_size_override("font_size", 20)
        b.pressed.connect(_on_letter_pressed.bind(k))
        row.add_child(b)
    parent.add_child(row)

func _on_icon_pressed() -> void:
    _typed = ""
    _refresh_display()
    _message.text = ""
    _overlay.visible = true

func _on_close_pressed() -> void:
    _overlay.visible = false

func _on_letter_pressed(letter: String) -> void:
    if _typed.length() < 20:
        _typed += letter.to_lower()
    _refresh_display()

func _on_backspace() -> void:
    if _typed.length() > 0:
        _typed = _typed.substr(0, _typed.length() - 1)
    _refresh_display()

func _on_clear() -> void:
    _typed = ""
    _refresh_display()

func _refresh_display() -> void:
    if _display == null:
        return
    if _typed.is_empty():
        _display.text = "Enter cheat code"
    else:
        _display.text = "> " + _typed

func _on_submit() -> void:
    var code: String = _typed.strip_edges().to_lower()
    if code == "thugstools":
        var player := get_parent().get_node_or_null("Player")
        if player != null and player.has_method("grant_professional_weapons"):
            player.grant_professional_weapons()
            _message.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
            _message.text = "PROFESSIONAL WEAPONS!"
            _typed = ""
            _refresh_display()
            await get_tree().create_timer(1.2).timeout
            _overlay.visible = false
        else:
            _message.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
            _message.text = "Player not found"
    elif code.is_empty():
        _message.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
        _message.text = "Enter a code first"
    else:
        _message.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
        _message.text = "Invalid code"
        _typed = ""
        _refresh_display()

func _input(event: InputEvent) -> void:
    if _overlay == null or not _overlay.visible:
        return
    if event is InputEventKey:
        var key_event: InputEventKey = event as InputEventKey
        if not key_event.pressed or key_event.echo:
            return
        var u: int = key_event.unicode
        if (u >= 65 and u <= 90) or (u >= 97 and u <= 122):
            if _typed.length() < 20:
                _typed += String.chr(u).to_lower()
            _refresh_display()
        elif key_event.keycode == KEY_BACKSPACE:
            _on_backspace()
        elif key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER:
            _on_submit()
        elif key_event.keycode == KEY_ESCAPE:
            _overlay.visible = false
