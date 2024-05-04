extends Panel

@onready var trackname_lbl: Label = $TracknameLbl

static var last_file_path: String

func _ready() -> void:
	get_tree().root.files_dropped.connect(_get_dropped_files) ## TODO: actually there needs to be only one connected signal, not all boxes...


func _get_dropped_files(files: PackedStringArray) -> void:
	last_file_path = files[0]
	print_debug(files)


func _on_mouse_entered() -> void:

	if last_file_path.is_empty(): return ## early exit
	
	
	var filename_split: PackedStringArray = last_file_path.split("\\")
	var filename: String = filename_split[filename_split.size() - 1]
	trackname_lbl.text = filename
	AudioPlayer.play_bgm_from_filename(last_file_path, AudioPlayer.PlaybackMode.PLAY_LOOPED)
	
	last_file_path = "" ## reset so it's not triggered again

