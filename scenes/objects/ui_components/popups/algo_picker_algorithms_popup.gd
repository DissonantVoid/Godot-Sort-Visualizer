extends "res://scenes/objects/ui_components/popups/popup_base.gd"

onready var _content_container : VBoxContainer = $Content/VBoxContainer
onready var _sure_container : VBoxContainer = $Content/Sure
onready var _labels_container : VBoxContainer = $Content/VBoxContainer/Algorithms/ScrollContainer/PanelContainer/VBoxContainer
onready var _choice_label : Label = $Content/VBoxContainer/AlgoChoice

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
			
			var sorter_name : String = curr_dir.substr(7)
			_algorithms[sorter_name] = _algo_path + curr_dir
			
			var label : Label = Label.new()
			label.autowrap = true
			label.align = Label.ALIGN_CENTER
			label.text = sorter_name
			label.mouse_filter = Control.MOUSE_FILTER_STOP
			label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			_labels_container.add_child(label)
			label.connect("gui_input", self, "_on_algo_label_input", [label])
		
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

func _on_algo_label_input(input, label : Label):
	if input is InputEventMouseButton && input.pressed && input.button_index == BUTTON_LEFT:
		_choice_label.text = label.text.get_basename()
		_chosen_algo_path = _algorithms[label.text] # since the label text is also the dict key, we can just use it
