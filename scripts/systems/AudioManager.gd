extends Node

enum Category {
	MASTER,
	MUSIC,
	SFX,
}

const TITLE_OPENING_PATH: String = "res://assets/audio/title_opening.wav"
const TITLE_FADE_OUT_SECONDS: float = 1.5
const TITLE_FADE_IN_SECONDS: float = 1.2
const SILENCE_DB: float = -60.0

var _music_player: AudioStreamPlayer
var _title_opening_started: bool = false
var _title_opening_active: bool = false
var _title_fade_started: bool = false
var _music_loop_enabled: bool = false
var _music_tween: Tween


func _ready() -> void:
	_music_player = _create_player(&"Music")
	_music_player.finished.connect(_on_music_finished)


func set_category_volume(category: Category, linear_volume: float) -> void:
	if not is_finite(linear_volume):
		push_error("AudioManager: Volume must be a finite value.")
		return

	var bus_name := _get_bus_name(category)
	if bus_name.is_empty():
		push_error("AudioManager: Unknown audio category.")
		return

	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		push_error("AudioManager: Audio bus '%s' is missing." % bus_name)
		return

	var clamped_volume := clampf(linear_volume, 0.0, 1.0)
	AudioServer.set_bus_mute(bus_index, is_zero_approx(clamped_volume))
	if clamped_volume > 0.0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(clamped_volume))


func play_music(stream: AudioStream, loop: bool = false, fade_in_seconds: float = 0.0) -> void:
	if stream == null:
		push_error("AudioManager: Cannot play a null music stream.")
		return

	_title_opening_active = false
	_title_fade_started = false
	_start_music(stream, loop, fade_in_seconds)


func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		push_error("AudioManager: Cannot play a null SFX stream.")
		return

	if not is_finite(volume_db):
		push_error("AudioManager: SFX volume must be finite.")
		return

	var player := _create_player(&"SFX")
	player.stream = stream
	player.volume_db = volume_db
	player.finished.connect(player.queue_free, CONNECT_ONE_SHOT)
	player.play()


func play_title_opening() -> void:
	if _title_opening_started:
		return
	_title_opening_started = true

	if not ResourceLoader.exists(TITLE_OPENING_PATH):
		push_warning(
			(
				"AudioManager: Title opening audio is not installed. "
				+ "Add an original or commercially licensed file at '%s'." % TITLE_OPENING_PATH
			)
		)
		return

	var stream := load(TITLE_OPENING_PATH) as AudioStream
	if stream == null:
		push_error("AudioManager: Could not load title opening audio.")
		return

	_title_opening_active = true
	_start_music(stream, false, TITLE_FADE_IN_SECONDS)


func fade_title_opening_out() -> void:
	if not _title_opening_active or _title_fade_started or not _music_player.playing:
		return

	_title_fade_started = true
	_kill_music_tween()
	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", SILENCE_DB, TITLE_FADE_OUT_SECONDS)
	_music_tween.tween_callback(_music_player.stop)


func _start_music(stream: AudioStream, loop: bool, fade_in_seconds: float) -> void:
	_kill_music_tween()
	_music_loop_enabled = loop
	_music_player.stop()
	_music_player.stream = stream
	_music_player.volume_db = SILENCE_DB if fade_in_seconds > 0.0 else 0.0
	_music_player.play()
	if fade_in_seconds > 0.0:
		_music_tween = create_tween()
		_music_tween.tween_property(_music_player, "volume_db", 0.0, fade_in_seconds)


func _on_music_finished() -> void:
	if _music_loop_enabled:
		_music_player.play()
	elif _title_opening_active:
		_title_opening_active = false


func _kill_music_tween() -> void:
	if _music_tween != null and _music_tween.is_running():
		_music_tween.kill()
	_music_tween = null


func _create_player(bus_name: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus_name
	add_child(player)
	return player


func _get_bus_name(category: Category) -> StringName:
	match category:
		Category.MASTER:
			return &"Master"
		Category.MUSIC:
			return &"Music"
		Category.SFX:
			return &"SFX"
	return &""
