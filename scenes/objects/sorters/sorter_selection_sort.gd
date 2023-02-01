extends "res://scenes/objects/sorters/sorter.gd"

# https://en.wikipedia.org/wiki/Selection_sort
# the array is virtually split into a sorted and an unsorted sides, each time we
# move the smallest element from the unsorted half to the end of the sorted half
# untill all elements are sorted
#
# time complexity: Average: O(N^2)
#                  Worst:   O(N^2)
#                  Best:    O(N^2)

var _index : int


# override
func setup(data_size : int, priority_callback : FuncRef):
	.setup(data_size, priority_callback)
	
	_index = 0

# override
func next_step() -> Dictionary:
	if _index == _data_size: return {"done":true}
	
	var smallest_idx : int = _index
	for j in range(_index+1, _data_size):
		if _priority_callback.call_func(smallest_idx, j):
				smallest_idx = j
	
	_index += 1
	if smallest_idx == _index-1:
		return next_step()
	else:
		return {"done":false, "action":SortAction.switch, "indexes":[_index-1, smallest_idx]}

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
				
		Utility.swap_elements(indexes, i, smallest_idx)
	
	return indexes
