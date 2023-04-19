extends Node

const _sorters_path : String = "res://scenes/objects/sorters/"
const _visualizers_path : String = "res://scenes/objects/visualizers/"
var _sorters : Dictionary # {name:path, ..}
var _visualizers : Dictionary # {name:{scene:scene path, script:script path}, ..}

const screenshots_path : String = "res://resources/textures/visualizer_images/"

# TODO: we store sorters and visualizers by their names, but we don't check if the name already exists

func _ready():
	var dir : Directory = Directory.new()
	assert(dir.dir_exists(_sorters_path), "sorters path has been removed or changed, either update _sorters_path or stop messing with my code :'(")
	assert(dir.dir_exists(_visualizers_path), "visualizers path has been removed or changed, either update _visualizers_path or stop messing with my code :'(")
	
	# sorters
	dir.open(_sorters_path)
	dir.list_dir_begin(true, true)
	var curr_dir : String = dir.get_next()
	while curr_dir.empty() == false:
		var sorter = load(_sorters_path + curr_dir)
		var metadata : Dictionary = sorter.get_metadata()
		if metadata["is_enabled"]:
			var sorter_name : String = metadata["name"]
			_sorters[sorter_name] = _sorters_path + curr_dir
		
		curr_dir = dir.get_next()
	
	# visualizers
	dir.open(_visualizers_path)
	dir.list_dir_begin(true, true)
	curr_dir = dir.get_next()
	while curr_dir.empty() == false:
		# ignore scripts
		if curr_dir.ends_with(".tscn"):
			var script_name : String = curr_dir.replace(".tscn", ".gd")
			assert(dir.file_exists(script_name), "visualizer " + curr_dir + " has no script, make sure that each visualizer has a script with the same name")
			
			var visualizer = load(_visualizers_path + script_name)
			var metadata : Dictionary = visualizer.get_metadata()
			if metadata["is_enabled"]:
				var visualizer_name : String = metadata["name"]
				_visualizers[visualizer_name] = {
					"scene": _visualizers_path + curr_dir,
					"script": _visualizers_path + script_name
				}
		
		curr_dir = dir.get_next()

func get_sorters_dict() -> Dictionary:
	return _sorters

func get_visualizers_dict() -> Dictionary:
	return _visualizers
