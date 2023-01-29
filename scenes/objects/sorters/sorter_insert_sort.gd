extends "res://scenes/objects/sorters/sorter.gd"

# https://en.wikipedia.org/wiki/Insertion_sort
# The array is virtually split into a sorted and an unsorted sides, values from
# the unsorted side are picked and placed at the correct position in the sorted side
#
# time complexity: O(N^2)

var _index : int
var _sub_idx : int


# override
func setup(data_size : int, priority_callback : FuncRef):
	.setup(data_size, priority_callback)
	
	_index = 0
	_sub_idx = -1

# override
func next_step() -> Dictionary:
	if _index == _data_size-1: return {"done":true}
	
	if _sub_idx == -1:
		if _priority_callback.call_func(_index, _index+1):
			_sub_idx = _index
			return {"done":false, "action":SortAction.switch, "indexes":[_index, _index+1]}
		else: _index += 1
	else:
		if _sub_idx == 0: _sub_idx = -1
		
		for j in range(_sub_idx, 0, -1):
			var indexes_to_switch : Array
			if _priority_callback.call_func(j-1, j):
				indexes_to_switch = [j-1, j]
			
			if j == 1:
				_sub_idx = -1
				_index += 1
			else: _sub_idx -= 1
			
			if indexes_to_switch: return {"done":false, "action":SortAction.switch, "indexes":indexes_to_switch}
	
	# if we reached this point, it means that i and i+1 are sorted,
	# or all indexes before i are sorted
	return next_step()

# override
func skip_to_last_step() -> Array:
	var indexes : Array
	indexes.resize(_data_size)
	for i in indexes.size(): indexes[i] = i
	
	for i in indexes.size()-1: # NOTE: size()-1 is actually size()-2 because 'in' is exclusive
		if _priority_callback.call_func(indexes[i], indexes[i+1]):
			Utility.swap_elements(indexes, i, i+1)
			# keep swaping backward untill [i] is in the right position
			for j in range(i, 0, -1):
				if _priority_callback.call_func(indexes[j-1], indexes[j]):
					Utility.swap_elements(indexes, j, j-1)
	
	return indexes
