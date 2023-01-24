extends "res://scenes/objects/components/popups/popup_base.gd"

onready var _visualizers_container : HBoxContainer = $Content/MarginContainer/VBoxContainer/ScrollContainer/PanelContainer/MarginContainer/HBoxContainer
onready var _visualizer_choice : Label = $Content/MarginContainer/VBoxContainer/VisualizerChoice

const _visualizer_data_scene : PackedScene = preload("res://scenes/objects/components/popups/visualizer_data_container.tscn")

var _chosen_visualizer_path : String

# TODO: there is a problem with the scroll container,
#       try to scroll inside the scroll bar of the card with title "singing_lazers"
#       it should scroll the description text without moving cards

func _ready():
	for key in FilesTracker.get_visualizers_dict():
		var curr_visualizer_entry : Dictionary = FilesTracker.get_visualizers_dict()[key]
		
		# TODO: something about this load causes errors in debugger, something to do with shaders??
		#       note that the error never appeared before I made visualizer_singing_lazers
		var metadata : Dictionary = load(
			curr_visualizer_entry["script"]
		).get_metadata()
		
		assert(
			metadata.has("title") && metadata.has("image") && metadata.has("description"),
			"visualizer.get_metadata() must return 3 entries even if empty: 'title' 'image' 'description'"
		)
		
		var instance := _visualizer_data_scene.instance()
		instance.connect("pressed", self, "_on_visualizer_pressed")
		_visualizers_container.add_child(instance)
		instance.setup(
			metadata["title"], metadata["image"], metadata["description"], curr_visualizer_entry["scene"]
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
