extends Control
class_name ShipMinimap

const WORLD_MIN := Vector2(-360.0, -120.0)
const WORLD_MAX := Vector2(510.0, 120.0)
const MAP_RECT := Rect2(7.0, 21.0, 109.0, 42.0)
const MAP_BACKGROUND := Color(0.018, 0.036, 0.049, 0.98)
const HULL_FILL := Color(0.027, 0.060, 0.072, 1.0)
const CRYO_FILL := Color(0.045, 0.12, 0.15, 1.0)
const CORRIDOR_FILL := Color(0.040, 0.15, 0.17, 1.0)
const ENGINEERING_FILL := Color(0.055, 0.12, 0.14, 1.0)
const MAP_LINE := Color(0.25, 0.66, 0.71, 1.0)
const LABEL_COLOR := Color(0.67, 0.84, 0.86, 1.0)
const PLAYER_MARKER := Color(0.52, 0.96, 1.0, 1.0)

var _player_position: Vector2 = Vector2(-208.0, 0.0)


func set_player_position(world_position: Vector2) -> void:
	if _player_position.is_equal_approx(world_position):
		return

	_player_position = world_position
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), MAP_BACKGROUND, true)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.12, 0.27, 0.31, 1.0), false, 1.0)
	draw_rect(Rect2(5.0, 4.0, 3.0, 8.0), MAP_LINE, true)
	draw_string(ThemeDB.fallback_font, Vector2(12.0, 11.0), "SHIP DECK", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 8, LABEL_COLOR)
	draw_string(ThemeDB.fallback_font, Vector2(size.x - 6.0, 11.0), "MAP", HORIZONTAL_ALIGNMENT_RIGHT, -1.0, 7, MAP_LINE)
	draw_rect(MAP_RECT, Color(0.012, 0.024, 0.033, 1.0), true)

	var hull := PackedVector2Array([
		Vector2(-360, 0), Vector2(-318, -38), Vector2(-278, -90),
		Vector2(-238, -118), Vector2(-100, -118), Vector2(-54, -78),
		Vector2(150, -64), Vector2(205, -96), Vector2(286, -116),
		Vector2(378, -114), Vector2(430, -96), Vector2(478, -62),
		Vector2(510, -62), Vector2(510, -30), Vector2(488, -16),
		Vector2(488, 16), Vector2(510, 30), Vector2(510, 62),
		Vector2(478, 62), Vector2(430, 96), Vector2(378, 114),
		Vector2(286, 116), Vector2(205, 96), Vector2(150, 64),
		Vector2(-54, 78), Vector2(-100, 118), Vector2(-238, 118),
		Vector2(-278, 90), Vector2(-318, 38)
	])
	_draw_deck(hull, HULL_FILL)

	var cryo_deck := PackedVector2Array([
		Vector2(-312, -34), Vector2(-274, -84), Vector2(-236, -110),
		Vector2(-96, -112), Vector2(-96, -64), Vector2(-80, -64),
		Vector2(-80, 64), Vector2(-96, 64), Vector2(-96, 112),
		Vector2(-236, 110), Vector2(-274, 84), Vector2(-312, 34)
	])
	var corridor_deck := PackedVector2Array([
		Vector2(-80, -64), Vector2(160, -64),
		Vector2(160, 64), Vector2(-80, 64)
	])
	var engineering_deck := PackedVector2Array([
		Vector2(160, -64), Vector2(216, -88), Vector2(286, -108),
		Vector2(378, -106), Vector2(428, -88), Vector2(478, -54),
		Vector2(478, -25), Vector2(490, -12), Vector2(490, 12),
		Vector2(478, 25), Vector2(478, 54), Vector2(428, 88),
		Vector2(378, 106), Vector2(286, 108), Vector2(216, 88),
		Vector2(160, 64)
	])
	_draw_deck(cryo_deck, CRYO_FILL)
	_draw_deck(corridor_deck, CORRIDOR_FILL)
	_draw_deck(engineering_deck, ENGINEERING_FILL)

	_draw_area_label("CRYO", Vector2(-200, 0))
	_draw_area_label("CORRIDOR", Vector2(40, 0))
	_draw_area_label("ENGINEERING", Vector2(326, -43))

	var marker_position := _world_to_map(_player_position)
	draw_circle(marker_position, 3.0, Color(0.012, 0.024, 0.033, 1.0))
	draw_circle(marker_position, 2.2, PLAYER_MARKER)
	draw_circle(marker_position, 0.8, Color.WHITE)


func _draw_deck(points: PackedVector2Array, fill_color: Color) -> void:
	var map_points := PackedVector2Array()
	for point in points:
		map_points.append(_world_to_map(point))

	draw_colored_polygon(map_points, fill_color)
	var outline := map_points.duplicate()
	outline.append(map_points[0])
	draw_polyline(outline, MAP_LINE, 0.8, false)


func _draw_area_label(label: String, world_position: Vector2) -> void:
	var position := _world_to_map(world_position)
	draw_string(
		ThemeDB.fallback_font,
		position + Vector2(0.0, 2.0),
		label,
		HORIZONTAL_ALIGNMENT_CENTER,
		-1.0,
		6,
		LABEL_COLOR
	)


func _world_to_map(world_position: Vector2) -> Vector2:
	var scale_factor := minf(
		MAP_RECT.size.x / (WORLD_MAX.x - WORLD_MIN.x),
		MAP_RECT.size.y / (WORLD_MAX.y - WORLD_MIN.y)
	)
	var map_size := Vector2(WORLD_MAX.x - WORLD_MIN.x, WORLD_MAX.y - WORLD_MIN.y) * scale_factor
	var map_origin := MAP_RECT.position + (MAP_RECT.size - map_size) * 0.5
	return map_origin + (world_position - WORLD_MIN) * scale_factor
