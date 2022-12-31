extends Control

export(NodePath) var _visualizer_path : NodePath

var _visualizer : Control
onready var _algo_picker : MarginContainer = $AlgorithmPicker


func _ready():
	assert(_visualizer_path != null)
	_visualizer = get_node(_visualizer_path)
	
	# setup
	_algo_picker.setup(_visualizer.get_content(), funcref(_visualizer, "sort_callback"))
