extends Control
class_name NavigationConsoleController

signal closed

const REQUIRED_ALLOCATION: int = 25
const SYSTEM_NAME: String = PowerManagement.NAVIGATION
const PANEL_SIZE := Vector2(272.0, 112.0)
const VIEWPORT_MARGIN: float = 8.0
const BACKDROP := Color(0.004, 0.010, 0.018, 0.84)
const PANEL := Color(0.025, 0.043, 0.060, 1.0)
const BORDER := Color(0.14, 0.25, 0.29, 1.0)
const PRIMARY_TEXT := Color(0.84, 0.91, 0.92, 1.0)
const MUTED_TEXT := Color(0.50, 0.64, 0.68, 1.0)
const ACCENT := Color(0.30, 0.80, 0.84, 1.0)
const WARNING := Color(0.94, 0.67, 0.34, 1.0)

var _power_management: PowerManagement
var _panel: PanelContainer
var _system_label: Label
var _solution_label: Label
var _destination_label: Label


func _ready() -> void:
	_build_interface()
	visible = false


func open(power_management: PowerManagement) -> void:
	_power_management = power_management
	if not _power_management.allocation_changed.is_connected(_on_allocation_changed):
		_power_management.allocation_changed.connect(_on_allocation_changed)
	_refresh_status()
	visible = true


func close() -> void:
	if not visible:
		return

	visible = false
	closed.emit()


func _build_interface() -> void:
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = BACKDROP
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.add_theme_stylebox_override("panel", _make_panel_style(PANEL, BORDER))
	add_child(_panel)
	_resize_panel()
	get_viewport().size_changed.connect(_resize_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 9)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 9)
	margin.add_theme_constant_override("margin_bottom", 7)
	_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 5)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 18.0
	header.add_theme_constant_override("separation", 5)
	layout.add_child(header)

	var marker := ColorRect.new()
	marker.custom_minimum_size = Vector2(3.0, 13.0)
	marker.color = ACCENT
	header.add_child(marker)

	var title := Label.new()
	title.text = "AURORA-09 NAVIGATION"
	title.add_theme_color_override("font_color", PRIMARY_TEXT)
	title.add_theme_font_size_override("font_size", 11)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_button := Button.new()
	close_button.text = "CLOSE"
	close_button.custom_minimum_size = Vector2(44.0, 18.0)
	close_button.add_theme_color_override("font_color", PRIMARY_TEXT)
	close_button.add_theme_font_size_override("font_size", 8)
	close_button.add_theme_stylebox_override("normal", _make_button_style(Color(0.075, 0.12, 0.14, 1.0)))
	close_button.add_theme_stylebox_override("hover", _make_button_style(Color(0.10, 0.21, 0.23, 1.0)))
	close_button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.055, 0.10, 0.12, 1.0)))
	close_button.pressed.connect(close)
	header.add_child(close_button)

	var divider := ColorRect.new()
	divider.custom_minimum_size.y = 1.0
	divider.color = BORDER
	layout.add_child(divider)

	_system_label = _make_status_label(layout)
	_solution_label = _make_status_label(layout)
	_destination_label = _make_status_label(layout)


func _make_status_label(parent: VBoxContainer) -> Label:
	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 9)
	parent.add_child(label)
	return label


func _resize_panel() -> void:
	var viewport_size := get_viewport_rect().size
	var available_size := Vector2(
		maxf(0.0, viewport_size.x - VIEWPORT_MARGIN * 2.0),
		maxf(0.0, viewport_size.y - VIEWPORT_MARGIN * 2.0)
	)
	var panel_size := Vector2(
		minf(PANEL_SIZE.x, available_size.x),
		minf(PANEL_SIZE.y, available_size.y)
	)
	_panel.offset_left = -panel_size.x / 2.0
	_panel.offset_top = -panel_size.y / 2.0
	_panel.offset_right = panel_size.x / 2.0
	_panel.offset_bottom = panel_size.y / 2.0


func _refresh_status() -> void:
	if _power_management == null:
		return

	var allocation := _power_management.get_system_allocated_power(SYSTEM_NAME)
	if allocation >= REQUIRED_ALLOCATION:
		_system_label.text = "NAVIGATION SYSTEM: ONLINE"
		_solution_label.text = "NAVIGATION SOLUTION: VALID"
		_destination_label.text = "SHIP DESTINATION: NOT ON FILE"
		_system_label.add_theme_color_override("font_color", ACCENT)
		_solution_label.add_theme_color_override("font_color", ACCENT)
		_destination_label.add_theme_color_override("font_color", PRIMARY_TEXT)
	else:
		_system_label.text = "NAVIGATION SYSTEM: OFFLINE"
		_solution_label.text = "NAVIGATION SOLUTION: INVALID"
		_destination_label.text = (
			"Navigation requires at least %d power units; current allocation is %d."
			% [REQUIRED_ALLOCATION, allocation]
		)
		_system_label.add_theme_color_override("font_color", WARNING)
		_solution_label.add_theme_color_override("font_color", WARNING)
		_destination_label.add_theme_color_override("font_color", MUTED_TEXT)


func _on_allocation_changed(system_name: String, _previous: int, _current: int) -> void:
	if system_name == SYSTEM_NAME and visible:
		_refresh_status()


func _make_panel_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	return style


func _make_button_style(background: Color) -> StyleBoxFlat:
	var style := _make_panel_style(background, BORDER)
	style.content_margin_left = 3.0
	style.content_margin_right = 3.0
	return style
