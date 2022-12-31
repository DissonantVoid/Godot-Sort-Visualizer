extends "res://scenes/objects/ui_components/popups/popup_base.gd"

onready var _content_container : VBoxContainer = $Content/MarginContainer/VBoxContainer
onready var _sure_container : VBoxContainer = $Content/MarginContainer/Sure
onready var _options_container : VBoxContainer = $Content/MarginContainer/VBoxContainer/Algorithms/ScrollContainer/PanelContainer/VBoxContainer
onready var _choice_label : Label = $Content/MarginContainer/VBoxContainer/AlgoChoice

const _algo_path : String = "res://scenes/objects/sorters/"
var _algorithms : Dictionary # {name:path,..}
var _chosen_algo_path : String

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
			
			var btn : Button = Button.new()
			btn.text = sorter_name
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			btn.focus_mode = Control.FOCUS_NONE
			btn.theme = preload("res://resources/godot/algorithm_picker_popup_option.tres")
			_options_container.add_child(btn)
			_options_container.add_child(HSeparator.new())
			btn.connect("pressed", self, "_on_algo_option_pressed", [btn])
		
		curr_dir = dir.get_next()
	

# override
func _on_ok_pressed():
	if _chosen_algo_path.empty():
		_error("no algorithm selected")
		return
	
	_content_container.hide()
	_sure_container.show()

# override
func _on_cancel_pressed():
	emit_signal("cancel")
	queue_free()

func _on_sure_ok_pressed():
	emit_signal("ok", {"path":_chosen_algo_path, "name":_choice_label.text})
	queue_free()

func _on_sure_cancel_pressed():
	_content_container.show()
	_sure_container.hide()

func _on_algo_option_pressed(btn : Button):
	_choice_label.text = btn.text
	_chosen_algo_path = _algorithms[btn.text] # since the btn text is also the dict key, we can just use it
