extends MarginContainer

# TODO: after running tests multiple times with failure show a button called "cry"

onready var _sorters_container : HFlowContainer = $MarginContainer/VBoxContainer/Sorter/Algorithms/Options
onready var _methods_container : HBoxContainer = $MarginContainer/VBoxContainer/Method/PanelContainer/Method

onready var _run_btn : Button = $MarginContainer/VBoxContainer/InputOutput/VBoxContainer/Run/MarginContainer/HBoxContainer/Run
onready var _run_util_err_btn : Button = $MarginContainer/VBoxContainer/InputOutput/VBoxContainer/Run/MarginContainer/HBoxContainer/RunUntilErr
onready var _console : RichTextLabel = $MarginContainer/VBoxContainer/InputOutput/VBoxContainer/VBoxContainer/Console

const _starting_sorter : String = "bubble_sort"
var _selected_sorter_name : String
var _use_next_step_func : bool = true
var _array_size : int = 10
var _allow_duplicates : bool = true
var _trace_steps : bool = false

const _max_printable_array_size : int = 30 # _current_input is printed to console as long as it's smaller than this
const _continuous_test_max_loops : int = 100
var _current_input : Array
var _prev_report_end_idx_cache : int = -1
var _dash_char_width : float

const _good_color : String = "#92e229"
const _warn_color : String = "#c9c14b"
const _bad_color : String = "#a21515"


func _ready():
	var font : Font = _console.get_font("normal_font")
	_dash_char_width = font.get_char_size(ord('-')).x
	
	# add sorters
	for key in FilesTracker.get_sorters_dict():
		var box : CheckBox = CheckBox.new()
		box.text = key
		box.focus_mode = Control.FOCUS_NONE
		box.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		box.connect("toggled", self, "_on_sorter_toggled", [box])
		_sorters_container.add_child(box)
	
	# pick one sorter by default
	_selected_sorter_name = _starting_sorter
	for sorter_box in _sorters_container.get_children():
		if sorter_box.text == _starting_sorter:
			sorter_box.set_pressed_no_signal(true)
			break
	
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
	_run_util_err_btn.disabled = true
	_prev_report_end_idx_cache = _console.bbcode_text.length()
	
	# setup
	_setup_test_input()
	_print_test_summery(true)
	
	# setup, sorter
	var sorter_object = load(FilesTracker.get_sorters_dict()[_selected_sorter_name]).new()
	sorter_object.setup(_array_size, funcref(self, "_test_callback"))
	
	var original_input : Array = _current_input.duplicate()
	var succeeded : bool = _run_single_test(sorter_object, original_input)
	
	if _array_size < _max_printable_array_size:
		_console_print("input array:")
		_console_print(str(original_input))
		_console_print("result array:")
		_console_print(str(_current_input))
	
	if succeeded:
		_console_print("sorting finished successfully", _good_color)
	else:
		_console_print("sorting finished with errors", _bad_color)
	
	_console_separate()
	
	_run_btn.disabled = false
	_run_util_err_btn.disabled = false

func _on_run_test_until_err_pressed():
	_run_btn.disabled = true
	_run_util_err_btn.disabled = true
	_prev_report_end_idx_cache = _console.bbcode_text.length()
	
	# setup
	_setup_test_input()
	_print_test_summery(false)
	
	# setup, sorter
	var sorter_object = load(FilesTracker.get_sorters_dict()[_selected_sorter_name]).new()
	sorter_object.setup(_array_size, funcref(self, "_test_callback"))
	
	# run tests
	var succeeded : bool
	var iteration : int = 0
	while iteration <= _continuous_test_max_loops:
		# report
		succeeded = _run_single_test(sorter_object, _current_input.duplicate())
		if succeeded == false: break
		
		iteration += 1
		_setup_test_input()
		sorter_object.setup(_array_size, funcref(self, "_test_callback"))
	
	if iteration == _continuous_test_max_loops:
		_console_print("continuous testing reached max attemps without errors", _good_color)
	elif succeeded == false:
		_console_print("continuous testing encountered an error after " + str(iteration) + " iterations", _bad_color)
	
	if succeeded:
		_console_print("sorting finished successfully", _good_color)
	else:
		_console_print("sorting finished with errors", _bad_color)
	
	_console_separate()
	
	_run_btn.disabled = false
	_run_util_err_btn.disabled = false

func _on_delete_old_reports_pressed():
	if _prev_report_end_idx_cache == -1: return
	
	_console.bbcode_text = _console.bbcode_text.substr(_prev_report_end_idx_cache)
	_prev_report_end_idx_cache = -1

func _setup_test_input():
	# populate _current_input
	_current_input.resize(_array_size)
	if _allow_duplicates:
		for i in _array_size:
			_current_input[i] = Utility.rng.randi_range(0, _array_size-1)
	else:
		for i in _array_size: _current_input[i] = i
		
		for i in _array_size:
			var rand_idx : int = Utility.rng.randi_range(0, _array_size-1)
			var temp_i : int = _current_input[i]
			_current_input[i] = _current_input[rand_idx]
			_current_input[rand_idx] = temp_i

func _print_test_summery(is_running_once : bool):
	# print summery based on class variables
	_console_print("running tests for [b]" + _selected_sorter_name + "[/b]")
	if _use_next_step_func:
		_console_print("using [b]sorter.next_step()[/b]")
	else:
		_console_print("using [b]sorter.skip_to_last_step()[/b]")
	
	_console_print("using array of size " + str(_array_size) +
					(", duplicates allowed" if _allow_duplicates else ", no duplicates") )
	if is_running_once && _array_size < _max_printable_array_size:
		_console_print("input array: " + str(_current_input))
	if is_running_once == false:
		_console_print("this test will run [b]repeatedly[/b] until an error occurs or it has run " + str(_continuous_test_max_loops) + " times")
	
	if _array_size >= _max_printable_array_size:
		_console_print(
				"NOTE: array is too big to print, make array size smaller than " +
				str(_max_printable_array_size) +
				" if you want to see input/output content"
			)
	
	_console_print("")

func _run_single_test(sorter_object : Sorter, original_input : Array) -> bool:
	# step 1: run tests
	if _use_next_step_func: # next_step()
		var has_errors : bool = false
		var iterations : int = 0
		var can_trace_steps : bool = _trace_steps && _array_size < _max_printable_array_size
		while true:
			var result : Dictionary = sorter_object.next_step()
			if result.has("done") == false:
				_console_print("sorter.next_step() return doesn't contain 'done' entry", _bad_color)
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
					_console_print(incomplete_entry_err, _bad_color)
					has_errors = true
					break
				
				if result["indexes"][0] == result["indexes"][1]:
					_console_print(
						"sorter.next_step() 'indexes' both values are the same," +
						"this is pointless and can cause issues with some visualizers",
						 _warn_color
					)
				
				if result["action"] == Sorter.SortAction.switch:
					Utility.swap_elements(_current_input, result["indexes"][0], result["indexes"][1])
				elif result["action"] == Sorter.SortAction.move:
					Utility.move_element(_current_input, result["indexes"][0], result["indexes"][1])
				
				if can_trace_steps:
					# output _current_input while highlighting the 2 indexes that were switched
					var content_string : String = "["
					for i in _current_input.size():
						var input_str : String = str(_current_input[i]) + ', '
						
						if i == result["indexes"][0]:
							input_str = "[color=" + _good_color + "]" + input_str + "[/color]"
						elif i == result["indexes"][1]:
							input_str = "[color=" + _bad_color + "]" + input_str + "[/color]"
						
						content_string += input_str
					content_string += "]"
					
					_console_print("step " + str(iterations) + ": " + content_string)
				
				iterations += 1
		
		if can_trace_steps: _console_print("") # new line after steps
		
		if has_errors:
			_console_print("sorter.next_step() encountered an error after " + str(iterations) + " iterations", _bad_color)
			return false
		else:
			_console_print("sorter.next_step() finished after " + str(iterations) + " iterations")
		
	else: # skip_to_last_step()
		var sort_result : Array = sorter_object.skip_to_last_step()
		if sort_result.size() != _current_input.size():
			_console_print(
				"returned array size (" + str(sort_result.size()) +
				") doesn't match input array size (" + str(_current_input.size()) + ")", _bad_color
			)
			return false
		else:
			# reorder _current_input
			var new_arr : Array
			new_arr.resize(sort_result.size())
			
			for i in sort_result.size():
				new_arr[i] = _current_input[sort_result[i]]
			
			_current_input = new_arr
	
	# step 2: validation
	# validate that items in returned array are the same as items in original array
	var values_record : Dictionary
	for el in original_input:
		if values_record.has(el) == false: values_record[el] = 0
		values_record[el] += 1
	for el in _current_input:
		if values_record.has(el) == false:
			_console_print("sorted array has different elements than input array, data is corrupted", _bad_color)
			return false
		
		values_record[el] -= 1
	
	for val in values_record.values():
		if val != 0:
			_console_print("sorted array has different elements than input array, data is corrupted", _bad_color)
			return false
	
	# validate returned array order
	for i in range(1, _current_input.size()):
		if _current_input[i] < _current_input[i-1]:
			_console_print("sorted array order is wrong", _bad_color)
			return false
	
	return true

func _test_callback(idx1 : int, idx2 : int) -> bool:
	# just like visualizer.determine_priority()
	return _current_input[idx1] > _current_input[idx2]

func _console_print(text : String, color_hex : String = ""):
	# TODO: make an issue about how it isn't obvious how Color.to_html() returns a hex string
	if color_hex.empty() == false:
		text = "[color=" + color_hex + "]" + text + "[/color]"
	
	_console.bbcode_text += text + '\n'

func _console_separate():
	# not the most accurate, but this calculates how many chars we need to fill a line
	var console_width : float = _console.rect_size.x
	if _console.get_v_scroll().visible: console_width -= _console.get_v_scroll().rect_size.x
	
	for i in floor(console_width / _dash_char_width) - 1:
		_console.bbcode_text += '-'
		
	_console.bbcode_text += '\n'

func _toggle_checkbox(target : CheckBox, all_boxes : Array):
	for box in all_boxes:
		if box != target:
			box.set_pressed_no_signal(false)
