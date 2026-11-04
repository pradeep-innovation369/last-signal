extends Control
class_name PowerConsoleController

signal closed

const PANEL_SIZE := Vector2(304.0, 172.0)
const PANEL_BACKGROUND := Color(0.025, 0.043, 0.060, 1.0)
const CARD_BACKGROUND := Color(0.045, 0.069, 0.083, 1.0)
const ROW_BACKGROUND := Color(0.035, 0.057, 0.071, 1.0)
const PANEL_BORDER := Color(0.14, 0.25, 0.29, 1.0)
const PRIMARY_TEXT := Color(0.84, 0.91, 0.92, 1.0)
const MUTED_TEXT := Color(0.50, 0.64, 0.68, 1.0)
const ACCENT := Color(0.30, 0.80, 0.84, 1.0)
const WARNING := Color(0.94, 0.67, 0.34, 1.0)

var _power_management: PowerManagement
var _sliders: Dictionary = {}
var _bars: Dictionary = {}
var _allocation_labels: Dictionary = {}
var _total_summary: Label
var _allocated_summary: Label
var _available_summary: Label
var _status_label: Label
var _default_status: String = "POWER GRID ONLINE"
var _refreshing_display: bool = false


func _ready() -> void:
	_build_interface()
	visible = false


func open(power_management: PowerManagement, status_message: String) -> void:
	_power_management = power_management
	if not _power_management.allocation_changed.is_connected(_on_allocation_changed):
		_power_management.allocation_changed.connect(_on_allocation_changed)

	_default_status = status_message if not status_message.is_empty() else "POWER GRID ONLINE"
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
	backdrop.color = Color(0.004, 0.010, 0.018, 0.84)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -PANEL_SIZE.x / 2.0
	panel.offset_top = -PANEL_SIZE.y / 2.0
	panel.offset_right = PANEL_SIZE.x / 2.0
	panel.offset_bottom = PANEL_SIZE.y / 2.0
	panel.add_theme_stylebox_override("panel", _make_panel_style(PANEL_BACKGROUND, PANEL_BORDER))
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 5)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 2)
	margin.add_child(layout)

	_build_header(layout)
	_build_power_summary(layout)
	_build_section_heading(layout)
	_build_system_rows(layout)
	_build_footer(layout)


func _build_header(parent: VBoxContainer) -> void:
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 18.0
	header.add_theme_constant_override("separation", 5)
	parent.add_child(header)

	var signal_mark := ColorRect.new()
	signal_mark.custom_minimum_size = Vector2(3.0, 13.0)
	signal_mark.color = ACCENT
	header.add_child(signal_mark)

	var title := Label.new()
	title.text = "SHIP POWER MANAGEMENT"
	title.add_theme_color_override("font_color", PRIMARY_TEXT)
	title.add_theme_font_size_override("font_size", 11)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_button := Button.new()
	close_button.text = "CLOSE"
	close_button.custom_minimum_size = Vector2(46.0, 18.0)
	close_button.add_theme_color_override("font_color", PRIMARY_TEXT)
	close_button.add_theme_font_size_override("font_size", 8)
	close_button.add_theme_stylebox_override("normal", _make_button_style(Color(0.075, 0.12, 0.14, 1.0)))
	close_button.add_theme_stylebox_override("hover", _make_button_style(Color(0.10, 0.21, 0.23, 1.0)))
	close_button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.055, 0.10, 0.12, 1.0)))
	close_button.pressed.connect(close)
	header.add_child(close_button)


func _build_power_summary(parent: VBoxContainer) -> void:
	var summary := HBoxContainer.new()
	summary.custom_minimum_size.y = 29.0
	summary.add_theme_constant_override("separation", 4)
	parent.add_child(summary)

	_total_summary = _make_summary_card(summary, "SHIP POWER", ACCENT)
	_allocated_summary = _make_summary_card(summary, "ALLOCATED", PRIMARY_TEXT)
	_available_summary = _make_summary_card(summary, "AVAILABLE", ACCENT)


func _make_summary_card(parent: HBoxContainer, heading: String, value_color: Color) -> Label:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _make_panel_style(CARD_BACKGROUND, PANEL_BORDER))
	parent.add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 5)
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_right", 3)
	margin.add_theme_constant_override("margin_bottom", 2)
	card.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 0)
	margin.add_child(content)

	var heading_label := Label.new()
	heading_label.text = heading
	heading_label.add_theme_color_override("font_color", MUTED_TEXT)
	heading_label.add_theme_font_size_override("font_size", 7)
	content.add_child(heading_label)

	var value_label := Label.new()
	value_label.text = "0 UNITS"
	value_label.add_theme_color_override("font_color", value_color)
	value_label.add_theme_font_size_override("font_size", 11)
	content.add_child(value_label)
	return value_label


func _build_section_heading(parent: VBoxContainer) -> void:
	var heading_row := HBoxContainer.new()
	heading_row.custom_minimum_size.y = 10.0
	parent.add_child(heading_row)

	var heading := Label.new()
	heading.text = "SYSTEM ALLOCATION"
	heading.add_theme_color_override("font_color", MUTED_TEXT)
	heading.add_theme_font_size_override("font_size", 8)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_row.add_child(heading)

	var scale_label := Label.new()
	scale_label.text = "0-100 UNITS"
	scale_label.add_theme_color_override("font_color", MUTED_TEXT)
	scale_label.add_theme_font_size_override("font_size", 7)
	scale_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	heading_row.add_child(scale_label)


func _build_system_rows(parent: VBoxContainer) -> void:
	for system_name: String in PowerManagement.SYSTEM_NAMES:
		var row_panel := PanelContainer.new()
		row_panel.custom_minimum_size.y = 19.0
		row_panel.add_theme_stylebox_override("panel", _make_panel_style(ROW_BACKGROUND, PANEL_BORDER))
		parent.add_child(row_panel)

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 3)
		margin.add_theme_constant_override("margin_top", 0)
		margin.add_theme_constant_override("margin_right", 3)
		margin.add_theme_constant_override("margin_bottom", 0)
		row_panel.add_child(margin)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		margin.add_child(row)

		var name_label := Label.new()
		name_label.text = system_name
		name_label.custom_minimum_size.x = 73.0
		name_label.add_theme_color_override("font_color", PRIMARY_TEXT)
		name_label.add_theme_font_size_override("font_size", 9)
		row.add_child(name_label)

		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(44.0, 8.0)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.max_value = PowerManagement.TOTAL_AVAILABLE_POWER
		bar.show_percentage = false
		bar.add_theme_stylebox_override("background", _make_bar_style(Color(0.075, 0.12, 0.14, 1.0)))
		bar.add_theme_stylebox_override("fill", _make_bar_style(ACCENT))
		row.add_child(bar)
		_bars[system_name] = bar

		var allocation_label := Label.new()
		allocation_label.custom_minimum_size.x = 30.0
		allocation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		allocation_label.add_theme_color_override("font_color", PRIMARY_TEXT)
		allocation_label.add_theme_font_size_override("font_size", 9)
		row.add_child(allocation_label)
		_allocation_labels[system_name] = allocation_label

		var slider := HSlider.new()
		slider.custom_minimum_size = Vector2(80.0, 16.0)
		slider.size_flags_horizontal = Control.SIZE_SHRINK_END
		slider.min_value = 0.0
		slider.step = 1.0
		slider.add_theme_stylebox_override("slider", _make_bar_style(Color(0.11, 0.18, 0.20, 1.0)))
		slider.value_changed.connect(_on_slider_value_changed.bind(system_name))
		row.add_child(slider)
		_sliders[system_name] = slider


func _build_footer(parent: VBoxContainer) -> void:
	var footer := HBoxContainer.new()
	footer.custom_minimum_size.y = 13.0
	footer.add_theme_constant_override("separation", 4)
	parent.add_child(footer)

	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 8)
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_status_label)

	var close_hint := Label.new()
	close_hint.text = "ESC TO CLOSE"
	close_hint.add_theme_color_override("font_color", ACCENT)
	close_hint.add_theme_font_size_override("font_size", 8)
	close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	footer.add_child(close_hint)


func _refresh_display() -> void:
	if _power_management == null:
		return

	_refreshing_display = true
	_total_summary.text = "%d UNITS" % PowerManagement.TOTAL_AVAILABLE_POWER
	_allocated_summary.text = "%d UNITS" % _power_management.get_total_allocated_power()
	_available_summary.text = "%d UNITS" % _power_management.get_available_power()

	for system_name: String in PowerManagement.SYSTEM_NAMES:
		var allocation: int = _power_management.get_system_allocated_power(system_name)
		var slider: HSlider = _sliders[system_name]
		slider.max_value = allocation + _power_management.get_available_power()
		slider.value = allocation
		_bars[system_name].value = allocation
		_allocation_labels[system_name].text = "%d UNITS" % allocation
	_refreshing_display = false
	if (
		_power_management.get_system_allocated_power(PowerManagement.LIFE_SUPPORT)
		>= LifeSupport.MINIMUM_STABLE_ALLOCATION
	):
		_set_status("LIFE SUPPORT STABILIZED", ACCENT)
	else:
		_set_status(_default_status, WARNING)


func _on_slider_value_changed(value: float, system_name: String) -> void:
	if _power_management == null or _refreshing_display:
		return

	if not _power_management.set_system_allocation(system_name, roundi(value)):
		_set_status("ALLOCATION REJECTED: POWER LIMIT REACHED", WARNING)
		_refresh_display()
		return

	_set_status(_default_status, MUTED_TEXT)
	_refresh_display()


func _on_allocation_changed(_system_name: String, _previous_allocation: int, _new_allocation: int) -> void:
	_refresh_display()


func _set_status(message: String, color: Color) -> void:
	_status_label.text = message
	_status_label.add_theme_color_override("font_color", color)


func _make_panel_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	return style


func _make_button_style(background: Color) -> StyleBoxFlat:
	var style := _make_panel_style(background, PANEL_BORDER)
	style.content_margin_left = 3.0
	style.content_margin_right = 3.0
	return style


func _make_bar_style(background: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.set_corner_radius_all(1)
	return style
