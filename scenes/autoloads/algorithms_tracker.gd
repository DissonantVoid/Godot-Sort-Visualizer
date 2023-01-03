extends Node

const _algo_path : String = "res://scenes/objects/sorters/"
var _algorithms : Dictionary # {name:path,..}

func _ready():
	var dir : Directory = Directory.new()
	dir.open(_algo_path)
	dir.list_dir_begin(true, true)
	var curr_dir : String = dir.get_next()
	while curr_dir.empty() == false:
		# ignore base class
		if curr_dir != "sorter.gd":
			assert(curr_dir.begins_with("sorter_"), "sorter scripts should start with 'sorter_'")
			
			var sorter_name : String = curr_dir.substr(7).get_basename()
			_algorithms[sorter_name] = _algo_path + curr_dir
		
		curr_dir = dir.get_next()

func get_dict() -> Dictionary:
	return _algorithms
