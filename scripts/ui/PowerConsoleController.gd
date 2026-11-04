extends Control
class_name PowerConsoleController

signal closed

const PANEL_SIZE := Vector2(292.0, 164.0)
const PANEL_BACKGROUND := Color(0.035, 0.055, 0.067, 1.0)
const PANEL_BORDER := Color(0.20, 0.31, 0.34, 1.0)
const PRIMARY_TEXT := Color(0.83, 0.88, 0.86, 1.0)
const MUTED_TEXT := Color(0.48, 0.60, 0.61, 1.0)
const ACCENT := Color(0.38, 0.76, 0.70, 1.0)
const WARNING := Color(0.91, 0.65, 0.34, 1.0)

var _power_management: PowerManagement
var _sliders: Dictionary = {}
var _bars: Dictionary = {}
var _allocation_labels: Dictionary = {}
var _allocated_summary: Label
var _available_summary: Label
var _status_label: Label
var _default_status: String = "Adjust allocations  |  ESC to close"


func _ready() -> void:
	_build_interface()
	visible = false


func open(power_management: PowerManagement, status_message: String) -> void:
	_power_management = power_management
	if not _power_management.allocation_changed.is_connected(_on_allocation_changed):
		_power_management.allocation_changed.connect(_on_allocation_changed)

	_default_status = status_message if not status_message.is_empty() else "Adjust allocations  |  ESC to close"
	visible = true
	_set_status(_default_status, MUTED_TEXT)
	_refresh_display()


func close() -> void:
	if not visible:
		return

	visible = false
	closed.emit()


func _build_interface() -> void:
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.005, 0.012, 0.018, 0.82)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -PANEL_SIZE.x / 2.0
	panel.offset_top = -PANEL_SIZE.y / 2.0
	panel.offset_right = PANEL_SIZE.x / 2.0
	panel.offset_bottom = PANEL_SIZE.y / 2.0
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 4)
	margin.add_child(layout)

	_build_header(layout)
	_build_power_summary(layout)
	_build_system_rows(layout)
	_build_status(layout)


func _build_header(parent: VBoxContainer) -> void:
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 18.0
	header.add_theme_constant_override("separation", 4)
	parent.add_child(header)

	var title := Label.new()
	title.text = "SHIP POWER MANAGEMENT"
	title.add_theme_color_override("font_color", PRIMARY_TEXT)
	title.add_theme_font_size_override("font_size", 11)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var capacity := Label.new()
	capacity.text = "100 UNITS"
	capacity.add_theme_color_override("font_color", ACCENT)
	capacity.add_theme_font_size_override("font_size", 9)
	capacity.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(capacity)

	var close_button := Button.new()
	close_button.text = "CLOSE"
	close_button.custom_minimum_size = Vector2(42.0, 18.0)
	close_button.add_theme_font_size_override("font_size", 8)
	close_button.add_theme_color_override("font_color", PRIMARY_TEXT)
	close_button.add_theme_stylebox_override("normal", _make_button_style(Color(0.10, 0.15, 0.17, 1.0)))
	close_button.add_theme_stylebox_override("hover", _make_button_style(Color(0.15, 0.23, 0.24, 1.0)))
	close_button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.08, 0.13, 0.14, 1.0)))
	close_button.pressed.connect(close)
	header.add_child(close_button)


func _build_power_summary(parent: VBoxContainer) -> void:
	var summary := HBoxContainer.new()
	summary.custom_minimum_size.y = 15.0
	summary.add_theme_constant_override("separation", 10)
	parent.add_child(summary)

	var total_label := Label.new()
	total_label.text = "TOTAL 100"
	total_label.add_theme_color_override("font_color", MUTED_TEXT)
	total_label.add_theme_font_size_override("font_size", 8)
	summary.add_child(total_label)

	_allocated_summary = _make_summary_label("ALLOCATED 0", PRIMARY_TEXT)
	_allocated_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.add_child(_allocated_summary)

	_available_summary = _make_summary_label("AVAILABLE 0", ACCENT)
	_available_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	summary.add_child(_available_summary)


func _make_summary_label(label_text: String, text_color: Color) -> Label:
	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", text_color)
	label.add_theme_font_size_override("font_size", 8)
	return label


func _build_system_rows(parent: VBoxContainer) -> void:
	for system_name: String in PowerManagement.SYSTEM_NAMES:
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 20.0
		row.add_theme_constant_override("separation", 4)
		parent.add_child(row)

		var name_label := Label.new()
		name_label.text = system_name
		name_label.custom_minimum_size.x = 74.0
		name_label.add_theme_color_override("font_color", PRIMARY_TEXT)
		name_label.add_theme_font_size_override("font_size", 8)
		row.add_child(name_label)

		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(48.0, 9.0)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.max_value = PowerManagement.TOTAL_AVAILABLE_POWER
		bar.show_percentage = false
		bar.add_theme_stylebox_override("background", _make_bar_style(Color(0.10, 0.15, 0.16, 1.0)))
		bar.add_theme_stylebox_override("fill", _make_bar_style(ACCENT))
		row.add_child(bar)
		_bars[system_name] = bar

		var allocation_label := Label.new()
		allocation_label.custom_minimum_size.x = 27.0
		allocation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		allocation_label.add_theme_color_override("font_color", PRIMARY_TEXT)
		allocation_label.add_theme_font_size_override("font_size", 8)
		row.add_child(allocation_label)
		_allocation_labels[system_name] = allocation_label

		var slider := HSlider.new()
		slider.custom_minimum_size = Vector2(76.0, 16.0)
		slider.size_flags_horizontal = Control.SIZE_SHRINK_END
		slider.min_value = 0.0
		slider.step = 1.0
		slider.value_changed.connect(_on_slider_value_changed.bind(system_name))
		row.add_child(slider)
		_sliders[system_name] = slider


func _build_status(parent: VBoxContainer) -> void:
	_status_label = Label.new()
	_status_label.custom_minimum_size.y = 12.0
	_status_label.add_theme_font_size_override("font_size", 8)
	parent.add_child(_status_label)


func _refresh_display() -> void:
	if _power_management == null:
		return

	_allocated_summary.text = "ALLOCATED %d" % _power_management.get_total_allocated_power()
	_available_summary.text = "AVAILABLE %d" % _power_management.get_available_power()

	for system_name: String in PowerManagement.SYSTEM_NAMES:
		var allocation := _power_management.get_system_allocated_power(system_name)
		var slider: HSlider = _sliders[system_name]
		slider.max_value = allocation + _power_management.get_available_power()
		slider.value = allocation
		_bars[system_name].value = allocation
		_allocation_labels[system_name].text = "%d / 100" % allocation


func _on_slider_value_changed(value: float, system_name: String) -> void:
	if _power_management == null:
		return

	if not _power_management.set_system_allocation(system_name, roundi(value)):
		_set_status("Allocation rejected: available ship power exceeded.", WARNING)
		_refresh_display()
		return

	_set_status(_default_status, MUTED_TEXT)
	_refresh_display()


func _on_allocation_changed(_system_name: String, _previous_allocation: int, _new_allocation: int) -> void:
	_refresh_display()


func _set_status(message: String, color: Color) -> void:
	_status_label.text = message
	_status_label.add_theme_color_override("font_color", color)


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BACKGROUND
	style.border_color = PANEL_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	return style


func _make_button_style(background: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = PANEL_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(1)
	style.content_margin_left = 3.0
	style.content_margin_right = 3.0
	return style


func _make_bar_style(background: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.set_corner_radius_all(1)
	return style
