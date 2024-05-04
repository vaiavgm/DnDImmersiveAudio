extends Panel


func _ready() -> void:
	get_tree().root.files_dropped.connect(_get_dropped_files)


func _get_dropped_files(files: PackedStringArray) -> void:
	print_debug(files)
	AudioPlayer.play_bgm_from_filename(files[0], AudioPlayer.PlaybackMode.PLAY_LOOPED)
