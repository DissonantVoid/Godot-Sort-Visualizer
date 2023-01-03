extends MarginContainer

# TODO: add button to clear console

onready var _algo_options_container : HFlowContainer = $MarginContainer/VBoxContainer/Sorter/Algorithms/Options
onready var _methods_container : HBoxContainer = $MarginContainer/VBoxContainer/Method/PanelContainer/Method

onready var _run_btn : Button = $MarginContainer/VBoxContainer/InputOutput/VBoxContainer/Run/Button
onready var _console : RichTextLabel = $MarginContainer/VBoxContainer/InputOutput/VBoxContainer/VBoxContainer/Console

var _selected_algorithm_name : String
var _use_next_step_func : bool = true
var _array_size : int = 10
var _allow_duplicates : bool = false

const _max_printable_array_size : int = 30 # _current_arr is printed to console as long as it's smaller than this
var _current_arr : Array
var _rng : RandomNumberGenerator = RandomNumberGenerator.new()

func _ready():
	_rng.randomize()
	
	# algorithms
	for key in AlgorithmsTracker.get_dict():
		var box : CheckBox = CheckBox.new()
		box.text = key
		box.focus_mode = Control.FOCUS_NONE
		box.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		box.connect("toggled", self, "_on_algo_option_toggled", [box])
		_algo_options_container.add_child(box)
	
	var first_algorithm_box : CheckBox = _algo_options_container.get_child(0)
	first_algorithm_box.set_pressed_no_signal(true)
	_selected_algorithm_name = first_algorithm_box.text
	
	# method
	for method_box in _methods_container.get_children():
		method_box.connect("toggled", self, "_on_method_toggled", [method_box])

func _on_algo_option_toggled(toggled : bool, box : CheckBox):
	if toggled:
		_toggle_checkbox(box, _algo_options_container.get_children())
		_selected_algorithm_name = box.text
	else:
		box.set_pressed_no_signal(true)

func _on_method_toggled(toggled : bool, box : CheckBox):
	if toggled:
		_toggle_checkbox(box, _methods_container.get_children())
		# TODO: hacky, lazy and prone to error
		_use_next_step_func = (box.text == "next_step()")
	else:
		box.set_pressed_no_signal(true)

func _on_array_size_changed(value : float):
	_array_size = value

func _on_allow_duplicates_toggled(button_pressed : bool):
	_allow_duplicates = button_pressed

# TODO: what a mess
func _on_run_test_pressed():
	_run_btn.disabled = true
	
	# setup
	_current_arr.resize(_array_size)
	if _allow_duplicates:
		for i in _array_size:
			_current_arr[i] = _rng.randi_range(0, 100)
	else:
		for i in _array_size: _current_arr[i] = i
		
		for i in _array_size:
			var rand_idx : int = _rng.randi_range(0, _array_size-1)
			var temp_i : int = _current_arr[i]
			_current_arr[i] = _current_arr[rand_idx]
			_current_arr[rand_idx] = temp_i
	
	var sorter_object = load(AlgorithmsTracker.get_dict()[_selected_algorithm_name]).new()
	sorter_object.setup(_array_size, funcref(self, "_is_bigger"))
	
	# run tests
	_print_console("Running tests for [b]" + _selected_algorithm_name + "[/b]")
	if _use_next_step_func:
		_print_console("using [b]sorter.next_step()[/b]")
	else:
		_print_console("using [b]sorter.skip_to_last_step()[/b]")
	
	_print_console("using array of size " + str(_array_size) +
					(", duplicates allowed" if _allow_duplicates else ", no duplicates") )
	_print_console("")
	
	var original_array : Array = _current_arr.duplicate()
	var has_errors : bool = false
	if _use_next_step_func: # next_step()
		var iterations : int = 0
		while true:
			var result : Dictionary = sorter_object.next_step()
			if result.has("done") == false:
				_print_console("sorter.next_step() return doesn't contain 'done' entry", true)
				has_errors = true
				break
			if result["done"]: break
				
			else:
				if result.has("indexes") == false:
					_print_console("sorter.next_step() return doesn't contain 'indexes' entry", true)
					has_errors = true
					break
				elif result["indexes"].size() != 2:
					_print_console("sorter.next_step() 'indexes' return contains more or less than 2 entries", true)
					has_errors = true
					break
				
				var temp_idx1 : int = _current_arr[result["indexes"][0]]
				_current_arr[result["indexes"][0]] = _current_arr[result["indexes"][1]]
				_current_arr[result["indexes"][1]] = temp_idx1
				iterations += 1
		if has_errors:
			_print_console("sorter.next_step() encountered an error after " + str(iterations) + " iterations", true)
		else:
			_print_console("sorter.next_step() finished after " + str(iterations) + " iterations")
	else: # skip_to_last_step()
		var new_indexes : Array = sorter_object.skip_to_last_step()
		if new_indexes.size() != _current_arr.size():
			_print_console("returned array size doesn't match input array size", true)
			has_errors = true
		else:
			var new_current_arr : Array
			new_current_arr.resize(new_indexes.size())
			
			for i in new_indexes.size():
				new_current_arr[i] = _current_arr[new_indexes[i]]
			
			_current_arr = new_current_arr
	
	
	if has_errors == false:
		# check new returned array validity
		for i in range(1, _current_arr.size()):
			if _current_arr[i] < _current_arr[i-1]:
				_print_console("sorted array is not sorted right", true)
				has_errors = true
				break
		
		if _array_size < _max_printable_array_size:
			_print_console("input array:")
			_print_console(str(original_array))
			_print_console("result array:")
			_print_console(str(_current_arr))
		else:
			_print_console(
				"array is too big to print, make array size smaller than " +
				str(_max_printable_array_size) +
				" if you want to see its content"
			)
	
	_print_console("sorting finished " + 
					("with errors" if has_errors else "successfully"),
					has_errors
	)
	_print_console("--------------------------------")
	
	_run_btn.disabled = false

func _is_bigger(idx1 : int, idx2 : int) -> bool:
	return _current_arr[idx1] > _current_arr[idx2]

func _toggle_checkbox(target : CheckBox, all_boxes : Array):
	for box in all_boxes:
			if box != target:
				box.set_pressed_no_signal(false)

func _print_console(text : String, is_err : bool = false):
	if is_err:
		text = "[color=red]" + text + "[/color]"
	
	_console.bbcode_text += text + '\n'
