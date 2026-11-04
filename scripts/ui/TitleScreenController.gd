extends CanvasLayer
class_name TitleScreenController

signal play_requested
signal continue_requested

const BACKGROUND := Color(0.006, 0.014, 0.027, 0.97)
const PANEL_BACKGROUND := Color(0.012, 0.027, 0.043, 0.98)
const BORDER := Color(0.12, 0.25, 0.30, 1.0)
const PRIMARY_TEXT := Color(0.87, 0.93, 0.94, 1.0)
const MUTED_TEXT := Color(0.48, 0.64, 0.69, 1.0)
const CYAN := Color(0.30, 0.80, 0.84, 1.0)
const SIGNAL_RED := Color(0.77, 0.30, 0.27, 1.0)

var _root_control: Control
var _content_panel: PanelContainer
var _continue_button: Button
var _accent_line: ColorRect
var _transition_started: bool = false


func _ready() -> void:
	_build_interface()
	refresh_continue_availability()
	get_viewport().size_changed.connect(_resize_layout)
	_resize_layout()
	visible = true
	AudioManager.play_title_opening()


func refresh_continue_availability() -> void:
	if not is_instance_valid(_continue_button):
		return
	_continue_button.visible = SaveGameSystem.new().has_save_file()


func prepare_for_display() -> void:
	_transition_started = false
	refresh_continue_availability()
	visible = true


func _build_interface() -> void:
	_root_control = Control.new()
	_root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root_control)

	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = BACKGROUND
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root_control.add_child(backdrop)

	var upper_rule := ColorRect.new()
	upper_rule.anchor_left = 0.10
	upper_rule.anchor_right = 0.90
	upper_rule.anchor_top = 0.16
	upper_rule.anchor_bottom = 0.16
	upper_rule.offset_bottom = 1.0
	upper_rule.color = Color(0.13, 0.28, 0.33, 0.55)
	upper_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root_control.add_child(upper_rule)

	var lower_rule := ColorRect.new()
	lower_rule.anchor_left = 0.10
	lower_rule.anchor_right = 0.90
	lower_rule.anchor_top = 0.84
	lower_rule.anchor_bottom = 0.84
	lower_rule.offset_bottom = 1.0
	lower_rule.color = Color(0.13, 0.28, 0.33, 0.38)
	lower_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root_control.add_child(lower_rule)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root_control.add_child(center)

	_content_panel = PanelContainer.new()
	_content_panel.add_theme_stylebox_override(
		"panel",
		_make_panel_style(PANEL_BACKGROUND, BORDER)
	)
	center.add_child(_content_panel)

	var margin := MarginContainer.new()
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	_content_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 5)
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(layout)

	var signal_rule := HBoxContainer.new()
	signal_rule.custom_minimum_size = Vector2(112.0, 2.0)
	signal_rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	signal_rule.add_theme_constant_override("separation", 4)
	layout.add_child(signal_rule)

	var red_marker := ColorRect.new()
	red_marker.custom_minimum_size = Vector2(14.0, 2.0)
	red_marker.color = SIGNAL_RED
	red_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	signal_rule.add_child(red_marker)

	_accent_line = ColorRect.new()
	_accent_line.custom_minimum_size = Vector2(94.0, 2.0)
	_accent_line.color = CYAN
	_accent_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	signal_rule.add_child(_accent_line)

	var pulse := create_tween().set_loops()
	pulse.tween_property(_accent_line, "modulate:a", 0.62, 2.5)
	pulse.tween_property(_accent_line, "modulate:a", 1.0, 2.5)

	var title := Label.new()
	title.text = "LAST SIGNAL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", PRIMARY_TEXT)
	title.add_theme_font_size_override("font_size", 24)
	layout.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "AURORA-09 — CHAPTER 1: THE AWAKENING"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", MUTED_TEXT)
	subtitle.add_theme_font_size_override("font_size", 8)
	layout.add_child(subtitle)

	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(0.0, 1.0)
	divider.color = BORDER
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(divider)

	var play_button := _make_button("PLAY", true, Vector2(180.0, 24.0))
	play_button.pressed.connect(_on_play_pressed)
	layout.add_child(play_button)

	_continue_button = _make_button("CONTINUE", false, Vector2(180.0, 20.0))
	_continue_button.pressed.connect(_on_continue_pressed)
	layout.add_child(_continue_button)


func _make_button(button_text: String, primary: bool, minimum_size: Vector2) -> Button:
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = minimum_size
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 9)
	if primary:
		button.add_theme_color_override("font_color", Color(0.01, 0.04, 0.06, 1.0))
		button.add_theme_color_override("font_hover_color", Color(0.01, 0.04, 0.06, 1.0))
		button.add_theme_stylebox_override("normal", _make_panel_style(CYAN, CYAN))
		button.add_theme_stylebox_override(
			"hover",
			_make_panel_style(Color(0.48, 0.91, 0.93, 1.0), Color(0.48, 0.91, 0.93, 1.0))
		)
	else:
		button.add_theme_color_override("font_color", PRIMARY_TEXT)
		button.add_theme_color_override("font_hover_color", CYAN)
		button.add_theme_stylebox_override(
			"normal",
			_make_panel_style(Color(0.035, 0.075, 0.09, 1.0), BORDER)
		)
		button.add_theme_stylebox_override(
			"hover",
			_make_panel_style(Color(0.06, 0.15, 0.17, 1.0), CYAN)
		)
	button.add_theme_stylebox_override(
		"pressed",
		_make_panel_style(Color(0.035, 0.095, 0.11, 1.0), CYAN)
	)
	return button


func _resize_layout() -> void:
	if not is_instance_valid(_content_panel):
		return
	var available_width := get_viewport().get_visible_rect().size.x - 24.0
	_content_panel.custom_minimum_size.x = clampf(available_width, 180.0, 280.0)


func _on_play_pressed() -> void:
	if not _begin_title_transition():
		return
	play_requested.emit()


func _on_continue_pressed() -> void:
	if not _begin_title_transition():
		return
	continue_requested.emit()


func _begin_title_transition() -> bool:
	if _transition_started:
		return false
	_transition_started = true
	AudioManager.fade_title_opening_out()
	return true


func _make_panel_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 4.0
	style.content_margin_right = 4.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0
	return style
