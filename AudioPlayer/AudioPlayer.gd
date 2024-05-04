extends Node


var rng := RandomNumberGenerator.new()

var sfx_channels:Array[AudioStreamPlayer]
var bgm_channel: AudioStreamPlayer ## TODO: maybe use 2+ channels to crossfade?
var channel_id_to_play_on := 0

var global_sfx_volume := 80.0
var global_bgm_volume := 50.0

@onready var BUS_INDEX_BGM := AudioServer.get_bus_index("BGM")
@onready var BUS_INDEX_SFX := AudioServer.get_bus_index("SFX")

enum PlaybackMode {IGNORE, PLAY_LOOPED, PLAY_ONCE, STOP, PLAY_GODOT_DEFAULT}

@onready var audio_bus_layout := preload("res://AudioPlayer/default_bus_layout.tres")

const BGM_DIRECTORY := "res://Assets/Audio/BGM/"
const SFX_DIRECTORY := "res://Assets/Audio/SFX/"

var LPF_effect: AudioEffectLowPassFilter

enum Tweening {NONE, OPEN, CLOSE}

var LPF_tweening: Tweening


func _ready() -> void:
	#GameInstance.get_files_from_dir(BGM_DIRECTORY, false)

	# print("audio player loaded")
	#AudioServer.set_bus_layout(audio_bus_layout)
	sfx_channels = [$SFX0, $SFX1, $SFX2, $SFX3, $SFX4, $SFX5, $SFX6, $SFX7]
	bgm_channel = $BGM

	LPF_tweening = Tweening.NONE
	if BUS_INDEX_BGM > 0: LPF_effect = AudioServer.get_bus_effect(BUS_INDEX_BGM, 0)


func cycle_channel() -> void:
	channel_id_to_play_on = (channel_id_to_play_on+1) % sfx_channels.size()


func get_next_channel() -> AudioStreamPlayer:
	cycle_channel()
	# print("current channel: %s" % channel_id_to_play_on)
	return sfx_channels[channel_id_to_play_on]


func open_lpf() -> void:
	printerr("opening LPF")

	LPF_tweening = Tweening.OPEN

	var tween := get_tree().create_tween()
	tween.tween_property(LPF_effect, "cutoff_hz", 20500, 1.0)
	tween.tween_callback(_mute_lpf)


func close_lpf() -> void:
	printerr("closing LPF")

	LPF_tweening = Tweening.CLOSE

	AudioServer.set_bus_effect_enabled(BUS_INDEX_BGM, 0, true)

	var tween := get_tree().create_tween()
	tween.tween_property(LPF_effect, "cutoff_hz", 1, 1.0)


func _mute_lpf() -> void:
	if LPF_tweening != Tweening.CLOSE:
		printerr("disabling...")
		AudioServer.set_bus_effect_enabled(BUS_INDEX_BGM, 0, false)
		LPF_tweening = Tweening.NONE


func play_sfx(sfx_to_play: Variant, volume: float = 1.0) -> void:
	var channel: AudioStreamPlayer = get_next_channel()
	channel.stream = sfx_to_play
	var db := 10.0 * log(volume*global_sfx_volume/100.0)
	channel.volume_db = db
	channel.play()

## TODO: instead of loading from filename, maybe they should instead be loaded from a list of preloaded vars?
##     : maybe evaluate the string and load the variable with that name
func update_bgm_from_filename(filename: String, playback_mode: PlaybackMode) -> void:
	match playback_mode:
		PlaybackMode.PLAY_LOOPED, PlaybackMode.PLAY_ONCE, PlaybackMode.PLAY_GODOT_DEFAULT:
			play_bgm_from_filename(filename, playback_mode)
		PlaybackMode.STOP:
			stop_bgm()
		_:
			pass


func play_sfx_from_filename(filename: String) -> void:
	if filename == "NONE" || filename == "":
		printerr("Invalid SFX filename %s" % filename)
		return

	var full_file_path: String = filename # SFX_DIRECTORY + filename

	if !FileAccess.file_exists(full_file_path):
		printerr("Invalid audio stream (sfx) from file %s. No music will play." % (full_file_path))
		return

	var audio_stream: AudioStream = load(full_file_path) as AudioStream

	play_sfx(audio_stream)


func play_bgm_from_filename(filename: String, playback_mode: PlaybackMode) -> void:
	if filename == "NONE" || filename == "":
		printerr("Invalid BGM filename %s" % filename)
		return

	var full_file_path: String = filename #BGM_DIRECTORY + filename

	if !FileAccess.file_exists(full_file_path):
		printerr("Invalid audio stream (bgm) from file %s. No music will play." % (full_file_path))
		return

	####
	var snd_file := FileAccess.open(full_file_path, FileAccess.READ)
	
	var split_file_name := full_file_path.split(".")
	var file_ending := split_file_name[split_file_name.size() - 1]
	
	match file_ending:
		"mp3": 
			var audio_stream := AudioStreamMP3.new()
			audio_stream.data = snd_file.get_buffer(snd_file.get_length())
			set_bgm_loop(playback_mode == PlaybackMode.PLAY_LOOPED)
			
			snd_file.close()
			play_bgm(audio_stream)
		"ogg":
			#var audio_stream := AudioStreamOggVorbis.new()
			var audio_stream := AudioStreamOggVorbis.load_from_file(full_file_path)
			set_bgm_loop(playback_mode == PlaybackMode.PLAY_LOOPED)
			
			snd_file.close()
			play_bgm(audio_stream)
		_: 
			printerr(".%s not supported!" % file_ending)

	####



	# var audio_stream: AudioStream = load(full_file_path) as AudioStream

	#if playback_mode == PlaybackMode.PLAY_ONCE:
		#@warning_ignore("unsafe_method_access")
		#audio_stream.set_loop(false)
	#elif playback_mode == PlaybackMode.PLAY_LOOPED:
		#@warning_ignore("unsafe_method_access")
		#audio_stream.set_loop(true)

	#play_bgm(audio_stream)


func _restart() -> void:
	bgm_channel.play()


func play_bgm(bgm_to_play: Variant, volume: float = 1.0) -> void:
	bgm_channel.stream = bgm_to_play
	if global_bgm_volume == 0.0:
		bgm_channel.volume_db = -80.0
	else:
		var db := 10.0 * log(volume*global_bgm_volume/100.0)
		bgm_channel.volume_db = db
	bgm_channel.play()


func set_bgm_loop(set_enabled: bool) -> void:
	print_debug("Set BGM looping to [%s]" % str(set_enabled))
	if set_enabled:
		if !bgm_channel.finished.is_connected(_restart):
			bgm_channel.finished.connect(_restart)
		if bgm_channel.finished.is_connected(stop_bgm):
			bgm_channel.finished.disconnect(stop_bgm)
	else:
		if bgm_channel.finished.is_connected(_restart):
			bgm_channel.finished.disconnect(_restart)
		if !bgm_channel.finished.is_connected(stop_bgm):
			bgm_channel.finished.connect(stop_bgm)


func stop_bgm() -> void:
	bgm_channel.stop()


func set_global_sfx_volume() -> void:
	for sfx_channel: AudioStreamPlayer in sfx_channels:
		sfx_channel.volume_db = 10.0 * log(global_sfx_volume/100.0)


func set_global_bgm_volume() -> void:
	(bgm_channel as AudioStreamPlayer).volume_db = 10.0 * log(global_bgm_volume/100.0)
