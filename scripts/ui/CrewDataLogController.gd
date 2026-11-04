extends Control
class_name CrewDataLogController

signal closed
signal opened

const VIEWPORT_MARGIN: float = 8.0
const PANEL_SIZE := Vector2(272.0, 152.0)
const BACKDROP := Color(0.004, 0.010, 0.018, 0.84)
const PANEL := Color(0.025, 0.043, 0.060, 1.0)
const BORDER := Color(0.14, 0.25, 0.29, 1.0)
const PRIMARY_TEXT := Color(0.84, 0.91, 0.92, 1.0)
const MUTED_TEXT := Color(0.50, 0.64, 0.68, 1.0)
const ACCENT := Color(0.30, 0.80, 0.84, 1.0)

var _log_system: CrewDataLogSystem
var _panel: PanelContainer
var _title_label: Label
var _archive_button: Button
var _content: VBoxContainer


func _ready() -> void:
	_build_interface()
	visible = false


func open_log(log_system: CrewDataLogSystem, log_id: String) -> void:
	_log_system = log_system
	visible = true
	_show_log(log_id)
	opened.emit()


func open_archive(log_system: CrewDataLogSystem) -> void:
	_log_system = log_system
	visible = true
	_show_archive()
	opened.emit()


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

	_title_label = Label.new()
	_title_label.text = "CREW DATA ARCHIVE"
	_title_label.add_theme_color_override("font_color", PRIMARY_TEXT)
	_title_label.add_theme_font_size_override("font_size", 10)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title_label)

	_archive_button = _make_header_button("ARCHIVE")
	_archive_button.pressed.connect(_show_archive)
	header.add_child(_archive_button)

	var close_button := _make_header_button("CLOSE")
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

	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.size_flags_vertical = Control.SIZE_FILL
	_content.add_theme_constant_override("separation", 6)
	scroll_container.add_child(_content)


func _make_header_button(button_text: String) -> Button:
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(42.0, 18.0)
	button.add_theme_color_override("font_color", PRIMARY_TEXT)
	button.add_theme_font_size_override("font_size", 7)
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.075, 0.12, 0.14, 1.0)))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.10, 0.21, 0.23, 1.0)))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.055, 0.10, 0.12, 1.0)))
	return button


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


func _show_archive() -> void:
	_title_label.text = "CREW DATA ARCHIVE"
	_archive_button.visible = false
	_clear_content()

	var logs: Array[Dictionary] = []
	if _log_system != null:
		logs = _log_system.get_discovered_logs()
	if logs.is_empty():
		_add_content_label(
			"NO RECOVERED LOGS",
			MUTED_TEXT,
			9
		)
		_add_content_label(
			"Approach crew data logs aboard the ship to recover them.",
			PRIMARY_TEXT,
			9
		)
		return

	for log: Dictionary in logs:
		var log_id: String = log["id"] if log.has("id") else ""
		var entry_button := Button.new()
		entry_button.text = "%s\n%s  /  %s" % [
			log["title"],
			log["author"],
			log["location"],
		]
		entry_button.custom_minimum_size.y = 28.0
		entry_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		entry_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		entry_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		entry_button.add_theme_color_override("font_color", PRIMARY_TEXT)
		entry_button.add_theme_font_size_override("font_size", 8)
		entry_button.add_theme_stylebox_override("normal", _make_button_style(Color(0.045, 0.072, 0.086, 1.0)))
		entry_button.add_theme_stylebox_override("hover", _make_button_style(Color(0.075, 0.14, 0.16, 1.0)))
		entry_button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.035, 0.060, 0.072, 1.0)))
		entry_button.pressed.connect(_show_log.bind(log_id))
		_content.add_child(entry_button)


func _show_log(log_id: String) -> void:
	if _log_system == null or not _log_system.is_discovered(log_id):
		_show_archive()
		return

	var log := _log_system.get_log(log_id)
	if log.is_empty():
		_show_archive()
		return

	_title_label.text = "CREW DATA LOG"
	_archive_button.visible = true
	_clear_content()
	_add_content_label(str(log["title"]), ACCENT, 10)
	_add_content_label("AUTHOR: %s\nLOCATION: %s" % [log["author"], log["location"]], MUTED_TEXT, 8)
	_add_content_label(str(log["text"]), PRIMARY_TEXT, 9)


func _add_content_label(label_text: String, color: Color, font_size: int) -> void:
	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	_content.add_child(label)


func _clear_content() -> void:
	for child: Node in _content.get_children():
		_content.remove_child(child)
		child.queue_free()


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
