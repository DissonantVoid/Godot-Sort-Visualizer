extends "res://scenes/objects/sorters/sorter.gd"

# https://en.wikipedia.org/wiki/Shellsort
# similar to insertion sort, it first sorts elements that are far apart
# from each other and progressively reduces the gap between the elements
# to be sorted
#
# time complexity: Average: (depends on the sequence used) O(N^(4/3)) in our case
#                  Worst:   O(N^2)
#                  Best:    O(N log N)

var _gap : int
var _index : int
var _sub_idx : int


# override
func setup(data_size : int, priority_callback : FuncRef):
	.setup(data_size, priority_callback)
	
	_gap = data_size / 2
	_index = _gap
	_sub_idx = -1

# override
func next_step() -> Dictionary:
	if _index >= _data_size:
		_gap /= 2
		_index = _gap
		if _gap == 0:
			return {"done":true}
	
	if _sub_idx == -1:
		if _priority_callback.call_func(_index-_gap, _index):
			var indexes_to_switch : Array = [_index-_gap, _index]
			_sub_idx = _index-_gap-_gap
			if _sub_idx < 0:
				_index += 1
				_sub_idx = -1
			return {"done":false, "action":SortAction.switch, "indexes":indexes_to_switch}
		else:
			_index += 1
	else:
		var indexes_to_switch : Array
		if _priority_callback.call_func(_sub_idx, _sub_idx+_gap):
			indexes_to_switch = [_sub_idx, _sub_idx+_gap]
		
		_sub_idx -= _gap
		if _sub_idx < 0:
			_index += 1
			_sub_idx = -1
		
		if indexes_to_switch: return {"done":false, "action":SortAction.switch, "indexes":indexes_to_switch}
	
	return next_step()

# override
func skip_to_last_step() -> Array:
	var indexes : Array
	indexes.resize(_data_size)
	for i in _data_size: indexes[i] = i
	
	# we use half the size as a gap and increment linearly (Natural sequence)
	# but there are other more efficent sequences like Marcin Ciura's sequence and Knuth Sequence (see wiki link above)
	var gap : int = indexes.size() / 2
	while gap > 0:
		for i in range(gap, indexes.size()):
			if _priority_callback.call_func(indexes[i-gap], indexes[i]):
				Utility.swap_elements(indexes, i-gap, i)
				for j in range(i-gap-gap, -1, -gap):
					if _priority_callback.call_func(indexes[j], indexes[j+gap]):
						Utility.swap_elements(indexes,j ,j+gap )
		
		gap /= 2
	
	return indexes


func is_enabled() -> bool:
	return true


func get_sorter_name() -> String:
	return "SHELLSORT"