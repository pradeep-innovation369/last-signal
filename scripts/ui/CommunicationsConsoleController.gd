extends Control
class_name CommunicationsConsoleController

signal closed
signal transmission_discovered

const REQUIRED_ALLOCATION: int = 20
const PANEL_SIZE := Vector2(272.0, 128.0)
const VIEWPORT_MARGIN: float = 8.0
const SYSTEM_NAME: String = "Communications"
const SHIP_RECORDED_TIME: String = "2187-04-19 03:14:00"
const TRANSMISSION_TIMESTAMP: String = "2187-04-19 07:46:00"
const INCOMING_TRANSMISSION: String = (
	"Do not open the lower access hatch when the cryo bay cycles. "
	+ "There is someone knocking from the other side. "
	+ "We have not opened it. We can hear ourselves asking."
)
const BACKDROP := Color(0.004, 0.010, 0.018, 0.84)
const PANEL := Color(0.025, 0.043, 0.060, 1.0)
const BORDER := Color(0.14, 0.25, 0.29, 1.0)
const PRIMARY_TEXT := Color(0.84, 0.91, 0.92, 1.0)
const MUTED_TEXT := Color(0.50, 0.64, 0.68, 1.0)
const ACCENT := Color(0.30, 0.80, 0.84, 1.0)
const WARNING := Color(0.94, 0.67, 0.34, 1.0)

var _power_management: PowerManagement
var _allocation_label: Label
var _message_label: Label
var _state_label: Label
var _panel: PanelContainer
var _transmission_discovered: bool = false


func _ready() -> void:
	_build_interface()
	visible = false


func open(power_management: PowerManagement, transmission_discovered_before: bool) -> void:
	_power_management = power_management
	_transmission_discovered = transmission_discovered_before
	if not _power_management.allocation_changed.is_connected(_on_allocation_changed):
		_power_management.allocation_changed.connect(_on_allocation_changed)
	_refresh_message()
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
	var panel := _panel
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.add_theme_stylebox_override("panel", _make_panel_style(PANEL, BORDER))
	add_child(panel)
	_resize_panel()
	get_viewport().size_changed.connect(_resize_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 9)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 9)
	margin.add_theme_constant_override("margin_bottom", 7)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 6)
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
	title.text = "COMMUNICATIONS RELAY"
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

	var scroll_container := ScrollContainer.new()
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll_container)

	var scroll_content := VBoxContainer.new()
	scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_content.size_flags_vertical = Control.SIZE_FILL
	scroll_content.add_theme_constant_override("separation", 6)
	scroll_container.add_child(scroll_content)

	_state_label = Label.new()
	_state_label.add_theme_font_size_override("font_size", 9)
	_state_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_state_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll_content.add_child(_state_label)

	var allocation_row := HBoxContainer.new()
	allocation_row.custom_minimum_size.y = 14.0
	scroll_content.add_child(allocation_row)

	var allocation_heading := Label.new()
	allocation_heading.text = "COMMUNICATIONS POWER"
	allocation_heading.add_theme_color_override("font_color", MUTED_TEXT)
	allocation_heading.add_theme_font_size_override("font_size", 8)
	allocation_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	allocation_row.add_child(allocation_heading)

	_allocation_label = Label.new()
	_allocation_label.add_theme_color_override("font_color", ACCENT)
	_allocation_label.add_theme_font_size_override("font_size", 9)
	_allocation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	allocation_row.add_child(_allocation_label)

	var message_panel := PanelContainer.new()
	message_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	message_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.035, 0.058, 0.072, 1.0), BORDER))
	scroll_content.add_child(message_panel)

	var message_margin := MarginContainer.new()
	message_margin.add_theme_constant_override("margin_left", 7)
	message_margin.add_theme_constant_override("margin_top", 5)
	message_margin.add_theme_constant_override("margin_right", 7)
	message_margin.add_theme_constant_override("margin_bottom", 5)
	message_panel.add_child(message_margin)

	_message_label = Label.new()
	_message_label.add_theme_color_override("font_color", PRIMARY_TEXT)
	_message_label.add_theme_font_size_override("font_size", 9)
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_message_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	message_margin.add_child(_message_label)

	var footer := Label.new()
	footer.text = "INCOMING CHANNEL 07  /  ESC TO CLOSE"
	footer.add_theme_color_override("font_color", MUTED_TEXT)
	footer.add_theme_font_size_override("font_size", 8)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll_content.add_child(footer)


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


func _refresh_message() -> void:
	if _power_management == null:
		return

	var allocation := _power_management.get_system_allocated_power(SYSTEM_NAME)
	_allocation_label.text = "%d / %d UNITS" % [allocation, REQUIRED_ALLOCATION]
	if allocation >= REQUIRED_ALLOCATION:
		var first_access := not _transmission_discovered
		_transmission_discovered = true
		if first_access:
			transmission_discovered.emit()
			_state_label.text = "TRANSMISSION RECORDED"
		else:
			_state_label.text = "SIGNAL LOCK ACQUIRED"
		_state_label.add_theme_color_override("font_color", ACCENT)
		_message_label.text = (
			"INCOMING DISTRESS TRANSMISSION\n\n"
			+ "SHIP RECORDED TIME: "
			+ SHIP_RECORDED_TIME
			+ "\nSENDER: AURORA-09\nRECIPIENT: AURORA-09\nTIMESTAMP: "
			+ TRANSMISSION_TIMESTAMP
			+ "\n\n"
			+ INCOMING_TRANSMISSION
		)
	else:
		_state_label.text = "RELAY POWER INSUFFICIENT"
		_state_label.add_theme_color_override("font_color", WARNING)
		_message_label.text = (
			"Communications requires at least %d power units. "
			% REQUIRED_ALLOCATION
		) + (
			"Current allocation is %d units. Increase power allocation at the Engineering Power Console."
			% allocation
		)


func _on_allocation_changed(system_name: String, _previous: int, _current: int) -> void:
	if system_name == SYSTEM_NAME and visible:
		_refresh_message()


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
