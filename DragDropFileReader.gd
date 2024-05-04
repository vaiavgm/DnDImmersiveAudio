extends Node

class_name DragDropFileReader

static var last_file_path: String

func _ready() -> void:
	get_tree().root.files_dropped.connect(_get_dropped_files) ## TODO: actually there needs to be only one connected signal, not all boxes...


func _get_dropped_files(files: PackedStringArray) -> void:
	last_file_path = files[0]
	#print_debug(files)
