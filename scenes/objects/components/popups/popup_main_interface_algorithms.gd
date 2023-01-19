extends "res://scenes/objects/components/popups/popup_base.gd"

onready var _content_container : VBoxContainer = $Content/MarginContainer/VBoxContainer
onready var _options_container : VBoxContainer = $Content/MarginContainer/VBoxContainer/Algorithms/ScrollContainer/PanelContainer/VBoxContainer
onready var _choice_label : Label = $Content/MarginContainer/VBoxContainer/AlgoChoice

var _chosen_algo_path : String


func _ready():
	for key in FilesTracker.get_sorters_dict():
		var btn : Button = Button.new()
		btn.text = key
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.focus_mode = Control.FOCUS_NONE
		btn.theme = preload("res://resources/godot/main_interface_popup_option.tres")
		_options_container.add_child(btn)
		_options_container.add_child(HSeparator.new())
		btn.connect("pressed", self, "_on_algo_option_pressed", [btn])

# override
func _on_ok_pressed():
	if _chosen_algo_path.empty():
		_error("no algorithm selected")
		return
	
	emit_signal("ok", {"path":_chosen_algo_path, "name":_choice_label.text})
	queue_free()

func _on_algo_option_pressed(btn : Button):
	_choice_label.text = btn.text
	_chosen_algo_path = FilesTracker.get_sorters_dict()[btn.text] # since the btn text is also the dict key, we can just use it
