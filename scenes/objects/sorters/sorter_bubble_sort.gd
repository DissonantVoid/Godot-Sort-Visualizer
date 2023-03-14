extends "res://scenes/objects/sorters/sorter.gd"

# https://en.wikipedia.org/wiki/Bubble_sort
# the simplest sorting algorithm that works by repeatedly
# swapping adjacent elements if they are in the wrong order
#
# time complexity: Average: O(N^2)
#                  Worst:   O(N^2)
#                  Best:    O(N)

var _index : int


# override
func setup(data_size : int, priority_callback : FuncRef):
	.setup(data_size, priority_callback)
	
	_index = 0

# override
func next_step() -> Dictionary:
	var indexes : Array
	indexes.resize(2)
	
	var changed : bool = false
	for i in range(_index, _data_size-1):
		if _priority_callback.call_func(i, i+1):
			changed = true
			indexes[0] = i
			indexes[1] = i+1
			_index = i+1
			break
	
	# if no change happened then we know we're done
	# but! if we didn't start checking from 0, recheck 
	if changed == false:
		if _index > 0:
			_index = 0
			return next_step()
		else:
			return {"done":true}
	else:
		return {"done":false, "action":SortAction.switch, "indexes":indexes}

# override
func skip_to_last_step() -> Array:
	var indexes : Array
	indexes.resize(_data_size)
	for i in _data_size: indexes[i] = i
	
	while true:
		var changed : bool = false
		for i in indexes.size()-1:
			if _priority_callback.call_func(indexes[i], indexes[i+1]):
				changed = true
				Utility.swap_elements(indexes, i, i+1)
		if changed == false: break
	
	return indexes


func is_enabled() -> bool:
	return true


func get_sorter_name() -> String:
	return tr("Bubble sort")