extends Control

class_name AudioControlNode

#const AUDIO_CONTROL_NODE = preload("res://AudioControlNode.tscn")

@onready var loop_txt: LineEdit = $Panel/LoopTxt
@onready var track_id_lbl: Label = $Panel/TrackIDLbl

@onready var trackname_lbl: Label = $Panel/TracknameLbl
@onready var is_sfx_button: CheckButton = $Panel/IsSFXButton
@onready var link_txt: LineEdit = $Panel/LinkTxt

@export var file_path: String = ""
@export var id: int
@export var loop_count: int = 1
@export var link_to: int = -1
@export var is_sfx: bool = false


static var next_id: int



func serialize() -> Dictionary:
	var result: Dictionary = {}
	result["file_path"] = file_path
	result["id"] = id
	result["loop_count"] = int(loop_txt.text)
	result["link_to"] = int(link_txt.text)
	result["is_sfx"] = is_sfx_button.button_pressed
	return result


static func serialize_array(data: Array[AudioControlNode]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for datum: AudioControlNode in data:
		result.push_back(datum.serialize())

	return result


static func deserialize_array(data: Variant) -> Array[AudioControlNode]:
	var result: Array[AudioControlNode] = []

	for datum: Dictionary in data as Array[Dictionary]:
		result.push_back(deserialize(datum))
		
	return result


static func deserialize(data: Dictionary) -> AudioControlNode:
	#var result: AudioControlNode = AUDIO_CONTROL_NODE.instantiate()
	if data.is_empty():
		printerr("Could not deserialize DialogueEditorNode!")
		#return result

	var result := AudioControlNode.new()
	result.file_path = data["file_path"] if data.has("file_path") else ""
	result.id = data["id"] if data.has("id") else 0
	result.loop_count = data["loop_count"] if data.has("loop_count") else 1
	result.link_to = data["link_to"] if data.has("link_to") else -1
	result.is_sfx = data["is_sfx"] if data.has("is_sfx") else false
	return result
	

func _ready() -> void:
	id = next_id
	track_id_lbl.text = str(id)
	next_id += 1
	#link_txt.text = str(-1)
	#loop_txt.text = str(1)
	Signals.UPDATE_UI_SIGNAL.connect(_update_ui)
	_update_ui()

func _update_ui() -> void:
	var filename_split: PackedStringArray = file_path.split("\\")
	var filename: String = filename_split[filename_split.size() - 1]
	trackname_lbl.text = filename
	
	track_id_lbl.text = str(id)
	
	loop_txt.text = str(loop_count)
	
	link_txt.text = str(link_to)
	
	is_sfx_button.button_pressed = is_sfx

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
	var test := serialize()
	printerr(test)
		
	if file_path.is_empty(): return ## early exit
	
	if is_sfx_button.button_pressed:
		AudioPlayer.play_sfx_from_filename(file_path)
	else:
		## only update playlist when clicking a BGM sound, not for SFX
		Signals.CREATE_PLAYLIST_SIGNAL.emit(id)
		

