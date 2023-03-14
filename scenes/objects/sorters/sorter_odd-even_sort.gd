extends "res://scenes/objects/sorters/sorter.gd"

# https://en.wikipedia.org/wiki/Odd%E2%80%93even_sort
# similar to bubble sort, but instead of comparing each element to the next
# we iterate over even and odd indexes separately
#
# time complexity: Average: O(N^2)
#                  Worst:   O(N^2)
#                  Best:    O(N)

var _is_even : bool
var _index : int
var _ordered_halves : int # 1=the even or odd half is sorted, 2=both are sorted


# override
func setup(data_size : int, priority_callback : FuncRef):
	.setup(data_size, priority_callback)
	
	_index = 0
	_is_even = true
	_ordered_halves = 0

# override
func next_step() -> Dictionary:
	var indexes : Array
	indexes.resize(2)
	
	var changed : bool = false
	for i in range(_index, _data_size-1, 2):
		if _priority_callback.call_func(i, i+1):
			changed = true
			indexes[0] = i
			indexes[1] = i+1
			_index = i+1
			# if one half was order, it is now no longer ordered
			_ordered_halves = 0
			break
	
	# if no change happened then we know 1 half is sorted
	# we're only truly done when both even and odd halves are sorted (_ordered_halves == 2)
	if changed == false:
		# but! if we didn't start checking from the first index, recheck
		if _index > (0 if _is_even else 1):
			_index = 0 if _is_even else 1
			return next_step()
		else:
			_ordered_halves += 1
			if _ordered_halves == 2:
				return {"done":true}
			else:
				# we've sorted 1 half! but another remains
				_is_even = !_is_even
				_index = 0 if _is_even else 1
				return next_step()
	else:
		return {"done":false, "action":SortAction.switch, "indexes":indexes}

# override
func skip_to_last_step() -> Array:
	var indexes : Array
	indexes.resize(_data_size)
	for i in _data_size: indexes[i] = i
	
	while true:
		var changed : bool = false
		for i in range(0, indexes.size()-1, 2):
			if _priority_callback.call_func(indexes[i], indexes[i+1]):
				changed = true
				Utility.swap_elements(indexes, i, i+1)
		
		for i in range(1, indexes.size()-1, 2):
			if _priority_callback.call_func(indexes[i], indexes[i+1]):
				changed = true
				Utility.swap_elements(indexes, i, i+1)
		
		if changed == false: break
	
	return indexes


func is_enabled() -> bool:
	return true


func get_sorter_name() -> String:
	return "ODDEVENSORT"