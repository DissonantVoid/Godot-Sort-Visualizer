extends Node # can't be a reference since godot automaticaly adds a node to autoload scripts

var rng : RandomNumberGenerator = RandomNumberGenerator.new()
var viewport_size : Vector2 = Vector2(ProjectSettings.get_setting("display/window/size/width"), ProjectSettings.get_setting("display/window/size/height"))

class MultiSignalYield:
	signal all_signals_yielded
	var awaiting : int = 0
	
	func add_signal(object : Object, signal_ : String):
		awaiting += 1
		object.connect(signal_, self, "on_signal_done")
	
	func on_signal_done():
		awaiting -= 1
		if awaiting == 0:
			emit_signal("all_signals_yielded")

func _init():
	randomize()
	rng.randomize()

func swap_elements(arr : Array, idx1 : int, idx2 : int):
	assert(idx1 >= 0 && idx1 < arr.size() && idx2 >= 0 && idx2 < arr.size(), "index out of bound")
	
	var temp = arr[idx1]
	arr[idx1] = arr[idx2]
	arr[idx2] = temp

func switch_children(parent : Node, child1_idx : int, child2_idx : int):
	var low_idx_child := parent.get_child(min(child1_idx, child2_idx))
	var high_idx : int = max(child1_idx, child2_idx)
	var high_idx_child := parent.get_child(high_idx)
	
	parent.move_child(high_idx_child, low_idx_child.get_index())
	parent.move_child(low_idx_child, high_idx)

func move_element(arr : Array, el_idx : int, el_new_idx : int):
	assert(el_idx >= 0 && el_idx < arr.size(), "el_idx must be >= 0 and < arr.size()")
	assert(el_new_idx >= 0 && el_new_idx <= arr.size(), "el_new_idx must be >= 0 and <= arr.size()")
	
	var element = arr[el_idx]
	arr.remove(el_idx)
	if el_idx < el_new_idx:
		arr.insert(el_new_idx-1, element)
	else:
		arr.insert(el_new_idx, element)

func subarr_first_index_to_1d(arr : Array, subarr_idx : int) -> int:
	assert(subarr_idx >= 0 && subarr_idx < arr.size(), "index out of bound")
	
	# NOTE: only checks 1 depth (array of arrays), doesn't work on array of arrays of arrays and so on
	var index_1d : int = 0
	for i in subarr_idx:
		assert(arr[i] is Array, "array must contains arrays")
		index_1d += arr[i].size()
	
	return index_1d

func lerp_color_arr(gradient : Array, weight : float, can_loop : bool) -> Color:
	var index_decimal : float = weight * (gradient.size()-1)
	var index : int = int(index_decimal)
	index_decimal -= floor(index_decimal)
	
	if can_loop == false && index == gradient.size()-1:
		return gradient[index]
	
	var curr_color : Color = gradient[index]
	var next_color : Color = gradient[(index + 1) % gradient.size()]
	return lerp(curr_color, next_color, index_decimal)

func await_multiple_signals(objects_n_signals : Array) -> MultiSignalYield:
	# objects_n_signals: [object1,signal1,object2,signal2 etc...]
	# this helps with the multi yield issues in godot where you can't await more than 1 signal because
	# some signals may emit before others making the yield order problematic
	# Usage: yield(Utility.await_multiple_signals([...]), "all_signals_yielded")
	# note that this method doesn't return any information about the signal's arguments so it's
	# only reliable to yield multiple signals and nothing more
	var multi_signal_yield : MultiSignalYield = MultiSignalYield.new()
	var assert_message : String = "items in objects_n_signals should be in the order: [object1, signal name1, object2, signal name2, ...]"
	
	assert(objects_n_signals.size() % 2 == 0, assert_message)
	for i in objects_n_signals.size():
		if i%2 == 0:
			assert(objects_n_signals[i] is Object, assert_message)
			multi_signal_yield.add_signal(objects_n_signals[i], objects_n_signals[i+1])
		else:
			assert(objects_n_signals[i] is String, assert_message)
	
	return multi_signal_yield
