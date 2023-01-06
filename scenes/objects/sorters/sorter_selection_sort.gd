extends "res://scenes/objects/sorters/sorter.gd"

# https://en.wikipedia.org/wiki/Selection_sort
# this algorithm sorts an array by repeatedly finding the smallest
# element and putting it at the beginning
#
# time complexity: O(N^2)

var _curr_index : int = 0


# override
func setup(data_size : int, priority_callback : FuncRef):
	.setup(data_size, priority_callback)
	
	_curr_index = 0

# override
func next_step() -> Dictionary:
	if _curr_index == _data_size-1: return {"done":true}
	
	var smallest_idx : int = _curr_index
	for j in range(_curr_index+1, _data_size):
		if _priority_callback.call_func(smallest_idx, j):
				smallest_idx = j
	
	var return_ : Dictionary = {"done":false, "indexes":[_curr_index, smallest_idx]}
	_curr_index += 1
	
	return return_

# override
func skip_to_last_step() -> Array:
	var indexes : Array
	indexes.resize(_data_size)
	for i in _data_size: indexes[i] = i
	
	for i in indexes.size():
		var smallest_idx : int = i
		
		for j in range(i+1, indexes.size()):
			if _priority_callback.call_func(indexes[smallest_idx], indexes[j]):
				smallest_idx = j
				
		var temp_i : int = indexes[i]
		indexes[i] = indexes[smallest_idx]
		indexes[smallest_idx] = temp_i
	
	return indexes
