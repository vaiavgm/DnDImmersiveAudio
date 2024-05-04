extends Node

class_name DragDropFileReader


@onready var control_nodes: Control = $UIPanel/ControlNodes


static var last_file_path: String
static var playlist: Dictionary ## contains PlaylistEntry objects

static var current_entry: PlaylistEntry

func _ready() -> void:
	get_tree().root.files_dropped.connect(_get_dropped_files) ## TODO: actually there needs to be only one connected signal, not all boxes...
	Signals.CREATE_PLAYLIST_SIGNAL.connect(generate_playlist)
	Signals.TRACK_COMPLETED_SIGNAL.connect(_play_next_track)

func _get_dropped_files(files: PackedStringArray) -> void:
	last_file_path = files[0]

func generate_playlist(from_id: int) -> void:
	playlist = {}
	current_entry = null # potentially unsafe!
	var current_id: int = -1
	
	for ctl: AudioControlNode in control_nodes.get_children() as Array[AudioControlNode]:
		current_id += 1
		if current_id < from_id || ctl.is_sfx_button.button_pressed || ctl.file_path.is_empty():
			continue
		
		#for i: int in int(ctl.loop_txt.text)+1:
		var new_entry: PlaylistEntry = PlaylistEntry.create(ctl.file_path, int(ctl.link_txt.text), int(ctl.loop_txt.text))
		playlist[current_id] = new_entry
		if current_entry == null:
			current_entry = new_entry
		
	print(playlist)
	AudioPlayer.play_bgm_from_filename(current_entry.file_path, AudioPlayer.PlaybackMode.PLAY_ONCE)
	current_entry.loop_count -= 1
	
	#var test := serialize()
	_on_save_to_json_btn_pressed("lel")
	
	deserialize_into_editor(DragDropFileReader.load_playlist_editor_from_file("lel.json"))
	
	
	#printerr(test)
	# deserialize_into_editor(test)
	

func _play_next_track() -> void:
	## TODO: what if the entire playlist is done?
	if current_entry.loop_count < 0:
		AudioPlayer.play_bgm_from_filename(current_entry.file_path, AudioPlayer.PlaybackMode.PLAY_ONCE)
		return
	elif current_entry.loop_count > 0:
		current_entry.loop_count -= 1
		AudioPlayer.play_bgm_from_filename(current_entry.file_path, AudioPlayer.PlaybackMode.PLAY_ONCE)
		return
	elif current_entry.link_to != -1:
		if !playlist.has(current_entry.link_to):
			printerr("playlist complete, %s not available" % current_entry.link_to)
			return
			

		var temp_entry: PlaylistEntry = playlist[current_entry.link_to]
		printerr("now playing %s [%s]" % [current_entry.link_to, temp_entry])
		current_entry = temp_entry
		AudioPlayer.play_bgm_from_filename(temp_entry.file_path, AudioPlayer.PlaybackMode.PLAY_ONCE)

func serialize() -> Dictionary:
	#
	var nodes: Array[AudioControlNode] = []
	
	for child:AudioControlNode in control_nodes.get_children() as Array[AudioControlNode]:
		nodes.push_back(child)
	
	return {
		"control_nodes": AudioControlNode.serialize_array(nodes),
		"next_id": AudioControlNode.next_id
	}
	
func deserialize_into_editor(data: Dictionary) -> void:
	@warning_ignore("unsafe_method_access")

	last_file_path = ""
	playlist = {}
	current_entry = null
	
	for node: AudioControlNode in control_nodes.get_children() as Array[AudioControlNode]:
		control_nodes.remove_child(node)
		node.queue_free()
	
	var audio_control_nodes: Array[AudioControlNode] = AudioControlNode.deserialize_array(data["control_nodes"])
	
	for node: AudioControlNode in audio_control_nodes:
		#var new_control_node: AudioControlNode = AUDIO_CONTROL_NODE.instantiate()
		control_nodes.add_child(node)
		@warning_ignore("integer_division")
		node.position.x = node.id / 5 * 250
		node.position.y = node.id % 5 * 200
	
	AudioControlNode.next_id = data["next_id"]
	Signals.UPDATE_UI_SIGNAL.emit()
	
	
const JSON_DIALOGUE_DATA_ASSET_PATH_PREFIX = "res://Playlists/"
	
func _on_save_to_json_btn_pressed(prefix: String) -> void:
	var save_file_path: String = JSON_DIALOGUE_DATA_ASSET_PATH_PREFIX + prefix + ".json"#+ str(Time.get_datetime_string_from_system()) + ".json"
	var file: FileAccess = FileAccess.open(save_file_path, FileAccess.WRITE)

	var serialized: Dictionary = serialize()

	file.store_string(JSON.stringify(serialized, "", false))
	file.close()
	print_debug("Playlist saved to: %s" % save_file_path)

static func load_playlist_editor_from_file(filename: String) -> Dictionary:
	var asset_path := JSON_DIALOGUE_DATA_ASSET_PATH_PREFIX + filename
	if not FileAccess.file_exists(asset_path):
		printerr("No playlist editor data found at path ["+asset_path+"]!")
		return {}

	var file := FileAccess.open(asset_path, FileAccess.READ)

	var json_string := file.get_line()
	return JSON.parse_string(json_string)
