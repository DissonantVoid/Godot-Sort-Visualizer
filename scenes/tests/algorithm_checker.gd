extends MarginContainer

onready var _sorters_container : HFlowContainer = $MarginContainer/VBoxContainer/Sorter/Algorithms/Options
onready var _methods_container : HBoxContainer = $MarginContainer/VBoxContainer/Method/PanelContainer/Method

onready var _run_btn : Button = $MarginContainer/VBoxContainer/InputOutput/VBoxContainer/Run/Button
onready var _console : RichTextLabel = $MarginContainer/VBoxContainer/InputOutput/VBoxContainer/VBoxContainer/Console

var _selected_sorter_name : String
var _use_next_step_func : bool = true
var _array_size : int = 10
var _allow_duplicates : bool = true
var _trace_steps : bool = false

const _max_printable_array_size : int = 30 # _current_input is printed to console as long as it's smaller than this
var _current_input : Array
var _prev_report_end_idx_cache : int = -1

const _bad_color : String = "#a21515"
const _good_color : String = "#92e229"


func _ready():
	# add sorters
	for key in FilesTracker.get_sorters_dict():
		var box : CheckBox = CheckBox.new()
		box.text = key
		box.focus_mode = Control.FOCUS_NONE
		box.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		box.connect("toggled", self, "_on_sorter_toggled", [box])
		_sorters_container.add_child(box)
	
	var first_sorter_box : CheckBox = _sorters_container.get_child(0)
	first_sorter_box.set_pressed_no_signal(true)
	_selected_sorter_name = first_sorter_box.text
	
	# connect methods
	for method_box in _methods_container.get_children():
		method_box.connect("toggled", self, "_on_method_toggled", [method_box])

func _on_sorter_toggled(toggled : bool, box : CheckBox):
	if toggled:
		_toggle_checkbox(box, _sorters_container.get_children())
		_selected_sorter_name = box.text
	else:
		box.set_pressed_no_signal(true)

func _on_method_toggled(toggled : bool, box : CheckBox):
	if toggled:
		_toggle_checkbox(box, _methods_container.get_children())
		if box.name == "Next": _use_next_step_func = true
		elif box.name == "Last": _use_next_step_func = false
	else:
		box.set_pressed_no_signal(true)

func _on_array_size_changed(value : float):
	_array_size = value

func _on_allow_duplicates_toggled(button_pressed : bool):
	_allow_duplicates = button_pressed

func _on_trace_steps_toggled(button_pressed : bool):
	_trace_steps = button_pressed

func _on_run_test_pressed():
	_run_btn.disabled = true
	_prev_report_end_idx_cache = _console.bbcode_text.length()
	
	# setup, populate _current_input
	_current_input.resize(_array_size)
	if _allow_duplicates:
		for i in _array_size:
			_current_input[i] = Utility.rng.randi_range(0, 100)
	else:
		for i in _array_size: _current_input[i] = i
		
		for i in _array_size:
			var rand_idx : int = Utility.rng.randi_range(0, _array_size-1)
			var temp_i : int = _current_input[i]
			_current_input[i] = _current_input[rand_idx]
			_current_input[rand_idx] = temp_i
	
	# setup, sorter
	var sorter_object = load(FilesTracker.get_sorters_dict()[_selected_sorter_name]).new()
	sorter_object.setup(_array_size, funcref(self, "_is_bigger"))
	
	# summery
	_print_console("Running tests for [b]" + _selected_sorter_name + "[/b]")
	if _use_next_step_func:
		_print_console("using [b]sorter.next_step()[/b]")
	else:
		_print_console("using [b]sorter.skip_to_last_step()[/b]")
	
	_print_console("using array of size " + str(_array_size) +
					(", duplicates allowed" if _allow_duplicates else ", no duplicates") )
	if _array_size < _max_printable_array_size:
		_print_console("input array: " + str(_current_input))
	_print_console("")
	
	# run tests
	var original_array : Array = _current_input.duplicate()
	var has_errors : bool = false
	if _use_next_step_func: # next_step()
		var iterations : int = 0
		var can_trace_steps : bool = _trace_steps && _array_size < _max_printable_array_size
		while true:
			var result : Dictionary = sorter_object.next_step()
			if result.has("done") == false:
				_print_console("sorter.next_step() return doesn't contain 'done' entry", _bad_color)
				has_errors = true
				break
			
			if result["done"]: break
			else:
				var incomplete_entry_err : String
				if result.has("action") == false:
					incomplete_entry_err =\
						"sorter.next_step() return doesn't contain 'action' entry"
				elif Sorter.SortAction.values().has(result["action"]) == false:
					incomplete_entry_err =\
						"sorter.next_step() 'action' entry isn't of type Sorter.SortAction"
				elif result.has("indexes") == false:
					incomplete_entry_err =\
						"sorter.next_step() return doesn't contain 'indexes' entry"
				elif result["indexes"].size() != 2:
					incomplete_entry_err =\
						"sorter.next_step() 'indexes' entry must contain 2 entries"
				
				if incomplete_entry_err.empty() == false:
					_print_console(incomplete_entry_err, _bad_color)
					has_errors = true
					break
				
				if result["action"] == Sorter.SortAction.switch:
					Utility.swap(_current_input, result["indexes"][0], result["indexes"][1])
				elif result["action"] == Sorter.SortAction.move:
					Utility.move_element(_current_input, result["indexes"][0], result["indexes"][1])
				
				if can_trace_steps:
					# output _current_input while highlighting the 2 indexes that were switched
					var content_string : String = "["
					for i in _current_input.size():
						var input_str : String = str(_current_input[i]) + ', '
						if i == result["indexes"][0] || i == result["indexes"][1]:
							input_str = "[color=" + _good_color + "]" + input_str + "[/color]"
						content_string += input_str
					content_string += "]"
					
					_print_console("step " + str(iterations) + ": " + content_string)
				
				iterations += 1
		
		if can_trace_steps: _print_console("") # new line after steps
		
		if has_errors:
			_print_console("sorter.next_step() encountered an error after " + str(iterations) + " iterations", _bad_color)
		else:
			_print_console("sorter.next_step() finished after " + str(iterations) + " iterations")
		
	else: # skip_to_last_step()
		var sort_result : Array = sorter_object.skip_to_last_step()
		if sort_result.size() != _current_input.size():
			_print_console(
				"returned array size (" + str(sort_result.size()) +
				") doesn't match input array size (" + str(_current_input.size()) + ")", _bad_color
			)
			has_errors = true
		else:
			var new_arr : Array
			new_arr.resize(sort_result.size())
			
			for i in sort_result.size():
				new_arr[i] = _current_input[sort_result[i]]
			
			_current_input = new_arr
	
	if has_errors == false:
		# validate that items in returned array are the same as items in original array
		var values_record : Dictionary
		for el in original_array:
			if values_record.has(el) == false: values_record[el] = 0
			values_record[el] += 1
		for el in _current_input:
			if values_record.has(el) == false:
				_print_console("sorted array has different elements than input array, data is corrupted", _bad_color)
				has_errors = true
				break
			
			values_record[el] -= 1
		
		if has_errors == false:
			for val in values_record.values():
				if val != 0:
					_print_console("sorted array has different elements than input array, data is corrupted", _bad_color)
					has_errors = true
					break
		
		
	if has_errors == false:
		# validate returned array order
		for i in range(1, _current_input.size()):
			if _current_input[i] < _current_input[i-1]:
				_print_console("sorted array order is wrong", _bad_color)
				has_errors = true
				break
		
		
	if _array_size < _max_printable_array_size:
		_print_console("input array:")
		_print_console(str(original_array))
		_print_console("result array:")
		_print_console(str(_current_input))
	else:
		_print_console(
			"array is too big to print, make array size smaller than " +
			str(_max_printable_array_size) +
			" if you want to see its content"
		)
	
	if has_errors:
		_print_console("sorting finished with errors", _bad_color)
	else:
		_print_console("sorting finished successfully", _good_color)
	
	_print_console("--------------------------------")
	
	_run_btn.disabled = false

func _on_delete_old_reports_pressed():
	if _prev_report_end_idx_cache == -1: return
	
	_console.bbcode_text = _console.bbcode_text.substr(_prev_report_end_idx_cache)
	_prev_report_end_idx_cache = -1

func _is_bigger(idx1 : int, idx2 : int) -> bool:
	return _current_input[idx1] > _current_input[idx2]

func _toggle_checkbox(target : CheckBox, all_boxes : Array):
	for box in all_boxes:
		if box != target:
			box.set_pressed_no_signal(false)

func _print_console(text : String, color_hex : String = ""):
	# TODO: we can't make color_hex of type Color, bacause the color tag
	#       in bbcode doesn't support rgb, I should send an issue about this
	#       so that either Color can return a hex code or the color tag can accept rgb
	if color_hex.empty() == false:
		text = "[color=" + color_hex + "]" + text + "[/color]"
	
	_console.bbcode_text += text + '\n'
