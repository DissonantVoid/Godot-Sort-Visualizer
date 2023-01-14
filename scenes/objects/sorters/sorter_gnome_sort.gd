extends "res://scenes/objects/sorters/sorter.gd"

# https://en.wikipedia.org/wiki/Gnome_sort
# almost the same as insert_sort, except that we use
# a single loop to iterate instead of nested loops
#
# time complexity: O(N^2)

var _curr_index : int = 0


# override
func setup(data_size : int, priority_callback : FuncRef):
	.setup(data_size, priority_callback)
	
	_curr_index = 0

# override
func next_step() -> Dictionary:
	# really surprised by how much simpler next_step() is compared to
	# insert_sort.next_step(), such big difference just by changing one rule
	
	if _curr_index == _data_size-1: return {"done":true}
	
	if _priority_callback.call_func(_curr_index, _curr_index+1):
		var indexes_to_change : Array = [_curr_index, _curr_index+1]
		
		if _curr_index > 0: _curr_index -= 1
		else: _curr_index += 1
		return {"done":false, "indexes":indexes_to_change}
	else: 
		_curr_index += 1
		return next_step()

# override
func skip_to_last_step() -> Array:
	var indexes : Array
	indexes.resize(_data_size)
	for i in indexes.size(): indexes[i] = i
	
	# we rely on i+1, so there should be at least 2 items in the array
	if indexes.size() < 2: return indexes
	
	var i : int = 0
	while true:
		if i == _data_size-1:
			return indexes
		
		if _priority_callback.call_func(indexes[i], indexes[i+1]):
			_swap(indexes, i, i+1)
			if i > 0: i -= 1
			else: i += 1
		else:
			i += 1
	
	return indexes