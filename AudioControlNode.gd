extends Node

@onready var loop_txt: LineEdit = $LoopTxt
@onready var loop_lbl: Label = $LoopTxt/LoopLbl
@onready var trackname_lbl: Label = $TracknameLbl
@onready var is_sfx_button: CheckButton = $IsSFXButton

@export var file_path: String

func _on_mouse_entered() -> void:

	if DragDropFileReader.last_file_path.is_empty(): return ## early exit
	
	## copy the last file path
	file_path = DragDropFileReader.last_file_path
	
	## reset so it's not triggered again
	DragDropFileReader.last_file_path = ""
	
	var filename_split: PackedStringArray = file_path.split("\\")
	var filename: String = filename_split[filename_split.size() - 1]
	trackname_lbl.text = filename



func _on_play_button_pressed() -> void:
	if file_path.is_empty(): return ## early exit
	
	var playback_mode := AudioPlayer.PlaybackMode.PLAY_GODOT_DEFAULT
	
	var loop_count := int(loop_txt.text)
	print_debug(loop_count)
	
	if loop_count == 0:
		playback_mode = AudioPlayer.PlaybackMode.PLAY_ONCE
	elif loop_count > 0:
		playback_mode = AudioPlayer.PlaybackMode.PLAY_LOOPED
	else:
		playback_mode = AudioPlayer.PlaybackMode.PLAY_GODOT_DEFAULT
	
	if is_sfx_button.toggled:
		AudioPlayer.play_sfx_from_filename(file_path)
	else:
		AudioPlayer.play_bgm_from_filename(file_path, playback_mode)
		
