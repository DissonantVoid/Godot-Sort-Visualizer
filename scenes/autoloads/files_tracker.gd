extends Node

const _sorters_path : String = "res://scenes/objects/sorters/"
const _visualizers_path : String = "res://scenes/objects/visualizers/"
var _sorters : Dictionary # {name:path, ..}
var _visualizers : Dictionary # {name:{scene:scene path, script:script path}, ..}

const screenshots_path : String = "res://resources/textures/visualizer_images/"


func _ready():
	var dir : Directory = Directory.new()
	assert(dir.dir_exists(_sorters_path), "sorters path has been removed or changed, either update _sorters_path or stop messing around")
	assert(dir.dir_exists(_visualizers_path), "visualizers path has been removed or changed, either update _visualizers_path or stop messing around")
	
	# sorters
	dir.open(_sorters_path)
	dir.list_dir_begin(true, true)
	var curr_dir : String = dir.get_next()
	while curr_dir.empty() == false:
		var scene = load(_sorters_path + curr_dir).new()
		if scene.is_enabled():
			var sorter_name : String = scene.get_sorter_name()
			_sorters[sorter_name] = _sorters_path + curr_dir
		
		curr_dir = dir.get_next()
	
	# visualizers
	dir.open(_visualizers_path)
	dir.list_dir_begin(true, true)
	curr_dir = dir.get_next()
	while curr_dir.empty() == false:
		# ignore scripts and base class
		if curr_dir.ends_with(".tscn"):
			var script_name : String = curr_dir.replace(".tscn", ".gd")
			assert(dir.file_exists(script_name), "visualizer " + curr_dir + " has no script, make sure that each visualizer has a script with the same name")

			var scene = load(_visualizers_path + script_name).new()
			if scene.is_enabled():
				var visualizer_name : String = curr_dir.substr(11).get_basename()
				_visualizers[visualizer_name] = Dictionary()
				_visualizers[visualizer_name]["scene"] = _visualizers_path + curr_dir
				_visualizers[visualizer_name]["script"] = _visualizers_path + script_name
		
		curr_dir = dir.get_next()

func get_sorters_dict() -> Dictionary:
	return _sorters

func get_visualizers_dict() -> Dictionary:
	return _visualizers
