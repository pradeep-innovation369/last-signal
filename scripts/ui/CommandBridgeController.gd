extends Control
class_name CommandBridgeController

signal closed
signal evidence_discovered
signal ending_confirmed(ending_id: String)
signal return_to_title_requested
signal new_game_requested

const PANEL_SIZE := Vector2(288.0, 164.0)
const VIEWPORT_MARGIN: float = 6.0
const COMMAND_RECORD: String = (
	"MISSION CONTROL / ORIGINAL TASKING\n"
	+ "AURORA-09 was dispatched to investigate a repeating signal beyond the filed route.\n\n"
	+ "SHIP CHRONOMETER AT WAKE: 2187-04-19 03:14:00\n"
	+ "TRANSMISSION HEADER: 2187-04-19 07:46:00\n\n"
	+ "FLIGHT RECORDER / EVENT ORDER\n"
	+ "07:31:08 — Uncommanded route correction accepted.\n"
	+ "07:39:42 — Lower cryo-hatch access authenticated with the engineer's credentials; "
	+ "the occupant was recorded in cryosleep.\n"
	+ "07:46:00 — Distress transmission received, timestamped 07:46:00.\n\n"
	+ "MISSION CONTROL NOTE: Central computer cannot reconcile the route, access, and "
	+ "transmission records."
)
const BACKDROP := Color(0.004, 0.010, 0.018, 0.88)
const PANEL := Color(0.025, 0.043, 0.060, 1.0)
const BORDER := Color(0.14, 0.25, 0.29, 1.0)
const PRIMARY_TEXT := Color(0.84, 0.91, 0.92, 1.0)
const MUTED_TEXT := Color(0.50, 0.64, 0.68, 1.0)
const ACCENT := Color(0.30, 0.80, 0.84, 1.0)
const ENDING_RESPONSE := "response"
const ENDING_SILENCE := "silence"

var _panel: PanelContainer
var _title_label: Label
var _close_button: Button
var _record_button: Button
var _record_label: Label
var _choices_box: VBoxContainer
var _selection_label: Label
var _confirm_button: Button
var _cancel_button: Button
var _ending_title: Label
var _ending_body: Label
var _continue_button: Button
var _continuation_title: Label
var _continuation_status: Label
var _chapter_title: Label
var _chapter_quote: Label
var _availability_label: Label
var _return_to_title_button: Button
var _new_game_button: Button
var _evidence_discovered: bool = false
var _selected_ending: String = ""
var _is_ending: bool = false
var _continuation_shown: bool = false
var _ending_presentation_id: int = 0


func _ready() -> void:
	_build_interface()
	visible = false


func open(evidence_discovered: bool) -> void:
	_evidence_discovered = evidence_discovered
	_is_ending = false
	_selected_ending = ""
	_title_label.text = "COMMAND BRIDGE RECORD"
	_close_button.visible = true
	_record_button.visible = true
	_record_button.text = "READ FINAL COMMAND RECORD"
	_record_label.visible = evidence_discovered
	_record_label.text = "RECORD REVIEWED\n" + COMMAND_RECORD if evidence_discovered else ""
	_choices_box.visible = evidence_discovered
	_selection_label.text = "Select a response. Your choice will not be sent until confirmed."
	_confirm_button.disabled = true
	visible = true
	_resize_panel()


func show_ending(ending_id: String) -> void:
	if ending_id != ENDING_RESPONSE and ending_id != ENDING_SILENCE:
		push_error("CommandBridgeController: Unknown ending id '%s'." % ending_id)
		return

	_is_ending = true
	_continuation_shown = false
	_ending_presentation_id += 1
	var presentation_id := _ending_presentation_id
	_selected_ending = ""
	_title_label.text = "MISSION RECORD CLOSED"
	_close_button.visible = false
	_record_button.visible = false
	_record_label.visible = false
	_choices_box.visible = false
	_ending_title.text = (
		"ENDING A — THE RESPONSE"
		if ending_id == ENDING_RESPONSE
		else "ENDING B — THE SILENCE"
	)
	if ending_id == ENDING_RESPONSE:
		_ending_body.text = (
			"TRANSMISSION SENT: AURORA-09 TO AURORA-09\n\n"
			+ "The carrier tone returns on the same channel. AURORA-09 continues transmitting."
		)
	else:
		_ending_body.text = (
			"RELAY ISOLATED. ROUTE ALTERED AWAY FROM THE SOURCE.\n\n"
			+ "The signal falls quiet. Its origin remains unknown."
		)
	_ending_title.visible = true
	_ending_body.visible = true
	_continue_button.text = "CONTINUE"
	_continue_button.visible = true
	_continuation_title.visible = false
	_continuation_status.visible = false
	_chapter_title.visible = false
	_chapter_quote.visible = false
	_availability_label.visible = false
	_return_to_title_button.visible = false
	_new_game_button.visible = false
	visible = true
	_resize_panel()
	get_tree().create_timer(5.0).timeout.connect(
		_on_ending_presentation_timeout.bind(presentation_id),
		CONNECT_ONE_SHOT
	)


func show_continuation() -> void:
	if not visible or not _is_ending or _continuation_shown:
		return

	_continuation_shown = true
	_ending_presentation_id += 1
	_title_label.text = "NEXT TRANSMISSION"
	_ending_title.visible = false
	_ending_body.visible = false
	_continue_button.visible = false
	_continuation_title.visible = true
	_continuation_status.visible = true
	_chapter_title.visible = true
	_chapter_quote.visible = true
	_availability_label.visible = true
	_return_to_title_button.visible = true
	_new_game_button.visible = true
	visible = true
	_resize_panel()


func close() -> void:
	if not visible or _is_ending:
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
	get_viewport().size_changed.connect(_resize_panel)

	var margin := MarginContainer.new()
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
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
	_title_label.text = "COMMAND BRIDGE RECORD"
	_title_label.add_theme_color_override("font_color", PRIMARY_TEXT)
	_title_label.add_theme_font_size_override("font_size", 10)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title_label)

	_close_button = _make_button("CLOSE", Vector2(44.0, 18.0))
	_close_button.pressed.connect(close)
	header.add_child(_close_button)

	var divider := ColorRect.new()
	divider.custom_minimum_size.y = 1.0
	divider.color = BORDER
	layout.add_child(divider)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_FILL
	content.add_theme_constant_override("separation", 5)
	scroll.add_child(content)

	_record_button = _make_button("READ FINAL COMMAND RECORD", Vector2(0.0, 18.0))
	_record_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_record_button.pressed.connect(_on_record_button_pressed)
	content.add_child(_record_button)

	_record_label = _make_label(content, ACCENT)
	_record_label.visible = false

	_choices_box = VBoxContainer.new()
	_choices_box.add_theme_constant_override("separation", 4)
	_choices_box.visible = false
	content.add_child(_choices_box)

	var response_row := HBoxContainer.new()
	response_row.add_theme_constant_override("separation", 5)
	_choices_box.add_child(response_row)
	var response_description := _make_label(response_row, PRIMARY_TEXT)
	response_description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	response_description.text = "ENDING A — THE RESPONSE\nReply; AURORA-09 continues transmitting."
	var response_button := _make_button("SELECT", Vector2(48.0, 22.0))
	response_button.pressed.connect(_on_ending_selected.bind(ENDING_RESPONSE))
	response_row.add_child(response_button)

	var silence_row := HBoxContainer.new()
	silence_row.add_theme_constant_override("separation", 5)
	_choices_box.add_child(silence_row)
	var silence_description := _make_label(silence_row, PRIMARY_TEXT)
	silence_description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	silence_description.text = "ENDING B — THE SILENCE\nIsolate the signal and route away from its source."
	var silence_button := _make_button("SELECT", Vector2(48.0, 22.0))
	silence_button.pressed.connect(_on_ending_selected.bind(ENDING_SILENCE))
	silence_row.add_child(silence_button)

	_selection_label = _make_label(_choices_box, MUTED_TEXT)
	_selection_label.text = "Select a response. Your choice will not be sent until confirmed."
	_confirm_button = _make_button("CONFIRM ENDING", Vector2(0.0, 20.0))
	_confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirm_button.disabled = true
	_confirm_button.pressed.connect(_on_confirm_button_pressed)
	_choices_box.add_child(_confirm_button)
	_cancel_button = _make_button("CLEAR SELECTION", Vector2(0.0, 18.0))
	_cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cancel_button.pressed.connect(_on_cancel_selection)
	_choices_box.add_child(_cancel_button)

	_ending_title = _make_label(content, ACCENT)
	_ending_title.add_theme_font_size_override("font_size", 11)
	_ending_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ending_title.visible = false
	_ending_body = _make_label(content, PRIMARY_TEXT)
	_ending_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ending_body.visible = false
	_continue_button = _make_button("CONTINUE", Vector2(0.0, 22.0))
	_continue_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_continue_button.visible = false
	_continue_button.pressed.connect(show_continuation)
	content.add_child(_continue_button)

	_continuation_title = _make_label(content, ACCENT)
	_continuation_title.text = "LAST SIGNAL"
	_continuation_title.add_theme_font_size_override("font_size", 14)
	_continuation_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_continuation_title.visible = false
	_continuation_status = _make_label(content, PRIMARY_TEXT)
	_continuation_status.text = "CONTINUES..."
	_continuation_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_continuation_status.visible = false
	_chapter_title = _make_label(content, PRIMARY_TEXT)
	_chapter_title.text = "CHAPTER 2\nBEYOND THE SIGNAL"
	_chapter_title.add_theme_font_size_override("font_size", 9)
	_chapter_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chapter_title.visible = false
	_chapter_quote = _make_label(content, MUTED_TEXT)
	_chapter_quote.text = "\"The signal was never the end.\""
	_chapter_quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chapter_quote.visible = false
	_availability_label = _make_label(content, Color(0.86, 0.43, 0.38, 1.0))
	_availability_label.text = "COMING IN THE NEXT CHAPTER"
	_availability_label.add_theme_font_size_override("font_size", 7)
	_availability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_availability_label.visible = false
	_return_to_title_button = _make_button("RETURN TO TITLE", Vector2(0.0, 20.0))
	_return_to_title_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_return_to_title_button.visible = false
	_return_to_title_button.pressed.connect(_on_return_to_title_pressed)
	content.add_child(_return_to_title_button)
	_new_game_button = _make_button("NEW GAME", Vector2(0.0, 20.0))
	_new_game_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_new_game_button.visible = false
	_new_game_button.pressed.connect(_on_new_game_pressed)
	content.add_child(_new_game_button)


func _make_label(parent: Node, color: Color) -> Label:
	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 8)
	parent.add_child(label)
	return label


func _make_button(button_text: String, minimum_size: Vector2) -> Button:
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = minimum_size
	button.add_theme_color_override("font_color", PRIMARY_TEXT)
	button.add_theme_font_size_override("font_size", 8)
	button.add_theme_stylebox_override("normal", _make_panel_style(Color(0.075, 0.12, 0.14, 1.0), BORDER))
	button.add_theme_stylebox_override("hover", _make_panel_style(Color(0.10, 0.21, 0.23, 1.0), BORDER))
	button.add_theme_stylebox_override("pressed", _make_panel_style(Color(0.055, 0.10, 0.12, 1.0), BORDER))
	return button


func _on_record_button_pressed() -> void:
	if not _evidence_discovered:
		_evidence_discovered = true
		evidence_discovered.emit()
		_record_label.text = "COMMAND RECORD ADDED\n" + COMMAND_RECORD
	else:
		_record_label.text = "RECORD REVIEWED\n" + COMMAND_RECORD
	_record_label.visible = true
	_record_button.text = "COMMAND RECORD: REVIEWED"
	_choices_box.visible = true


func _on_ending_selected(ending_id: String) -> void:
	_selected_ending = ending_id
	_confirm_button.disabled = false
	_selection_label.text = (
		"Confirm ENDING A — THE RESPONSE?"
		if ending_id == ENDING_RESPONSE
		else "Confirm ENDING B — THE SILENCE?"
	)


func _on_confirm_button_pressed() -> void:
	if _selected_ending.is_empty():
		return
	ending_confirmed.emit(_selected_ending)


func _on_cancel_selection() -> void:
	_selected_ending = ""
	_confirm_button.disabled = true
	_selection_label.text = "Select a response. Your choice will not be sent until confirmed."


func _on_return_to_title_pressed() -> void:
	return_to_title_requested.emit()


func _on_new_game_pressed() -> void:
	new_game_requested.emit()


func _on_ending_presentation_timeout(presentation_id: int) -> void:
	if presentation_id != _ending_presentation_id or not visible:
		return
	show_continuation()


func _resize_panel() -> void:
	if not is_instance_valid(_panel):
		return
	var available := get_viewport_rect().size - Vector2(VIEWPORT_MARGIN * 2.0, VIEWPORT_MARGIN * 2.0)
	var size := Vector2(minf(PANEL_SIZE.x, available.x), minf(PANEL_SIZE.y, available.y))
	_panel.offset_left = -size.x / 2.0
	_panel.offset_top = -size.y / 2.0
	_panel.offset_right = size.x / 2.0
	_panel.offset_bottom = size.y / 2.0


func _make_panel_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 3.0
	style.content_margin_right = 3.0
	return style
