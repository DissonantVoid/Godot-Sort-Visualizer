extends "res://scenes/objects/components/popups/popup_base.gd"

onready var _visualizers_container : HBoxContainer = $Content/MarginContainer/VBoxContainer/ScrollContainer/PanelContainer/MarginContainer/HBoxContainer
onready var _visualizer_choice : Label = $Content/MarginContainer/VBoxContainer/VisualizerChoice

const _visualizer_data_scene : PackedScene = preload("res://scenes/objects/components/popups/visualizer_data_container.tscn")

var _chosen_visualizer_path : String


func _ready():
	for key in FilesTracker.get_visualizers_dict():
		# TODO: hacky, maybe FilesTracker.get_visualizers_dict should return dict with 2 entries
		#       one for scene and other for script. or maybe return scene name without the extension
		#       so we can add the extension we need, if we do this get_sorters_dict() should do the same
		#       for the sake of consistency
		var metadata : Dictionary = load(
			FilesTracker.get_visualizers_dict()[key].replace(".tscn",".gd")
		).get_metadata()
		
		var instance := _visualizer_data_scene.instance()
		instance.connect("pressed", self, "_on_visualizer_pressed")
		_visualizers_container.add_child(instance)
		instance.setup(
			metadata["title"], metadata["image"], metadata["description"], FilesTracker.get_visualizers_dict()[key]
		)

func _on_ok_pressed():
	if _chosen_visualizer_path.empty():
		_error("no visualizer selected")
		return
	
	emit_signal("ok", {"path":_chosen_visualizer_path, "name":_visualizer_choice.text})
	queue_free()

func _on_visualizer_pressed(title : String, path : String):
	_visualizer_choice.text = title
	_chosen_visualizer_path = path
