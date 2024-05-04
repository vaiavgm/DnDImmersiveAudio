extends Node

class_name PlaylistEntry

var file_path: String
var link_to: int = -1 ## link to playlist ID
var loop_count: int = 1

static func create(_file_path: String, _link_to: int, _loop_count: int) -> PlaylistEntry:
	var result: PlaylistEntry = PlaylistEntry.new()
	
	result.file_path = _file_path
	result.link_to = _link_to
	result.loop_count = _loop_count
	
	return result

func _to_string() -> String:
	var path_split: PackedStringArray = file_path.split("\\")
	var short_path: String = path_split[path_split.size() - 1]
	return "%s (x%d -> %d)" % [short_path, loop_count, link_to]
