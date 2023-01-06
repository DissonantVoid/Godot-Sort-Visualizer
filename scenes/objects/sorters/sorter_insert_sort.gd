extends "res://scenes/objects/sorters/sorter.gd"

# https://en.wikipedia.org/wiki/Insertion_sort
# The array is virtually split into a sorted and an unsorted sides, values from
# the unsorted side are picked and placed at the correct position in the sorted side
#
# time complexity: O(N^2)

var _curr_index : int = 0
var _curr_sub_idx : int = -1


# override
func setup(data_size : int, priority_callback : FuncRef):
	.setup(data_size, priority_callback)
	
	_curr_index = 0
	_curr_sub_idx = -1

# override
func next_step() -> Dictionary:
	if _curr_index == _data_size-1: return {"done":true}
	
	if _curr_sub_idx == -1:
		if _priority_callback.call_func(_curr_index, _curr_index+1):
			_curr_sub_idx = _curr_index
			return {"done":false, "indexes":[_curr_index, _curr_index+1]}
		else: _curr_index += 1
	else:
		if _curr_sub_idx == 0: _curr_sub_idx = -1
			
		for j in range(_curr_sub_idx, 0, -1):
			var indexes_to_switch : Array
			if _priority_callback.call_func(j-1, j):
				indexes_to_switch = [j-1, j]
			
			if j == 1:
				_curr_sub_idx = -1
				_curr_index += 1
			else: _curr_sub_idx -= 1
			
			if indexes_to_switch: return {"done":false, "indexes":indexes_to_switch}
	
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
			var temp_i : int = indexes[i]
			indexes[i] = indexes[i+1]
			indexes[i+1] = temp_i
			# keep swaping backward untill [i] is in the right position
			for j in range(i, 0, -1):
				if _priority_callback.call_func(indexes[j-1], indexes[j]):
					var temp_j : int = indexes[j]
					indexes[j] = indexes[j-1]
					indexes[j-1] = temp_j
	
	return indexes
