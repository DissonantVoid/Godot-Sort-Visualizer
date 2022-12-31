extends "res://scenes/objects/sorters/sorter.gd"

var _curr_index : int = 0

# override
func setup(data_size : int, sort_callback : FuncRef):
	.setup(data_size, sort_callback)
	
	_curr_index = 0

# override
func next_step() -> Dictionary:
	var changed : bool = false
	var items : Array
	
	while true:
		for i in range(_curr_index, _data_size):
			for j in range(i+1, _data_size):
				if _sort_callback.call_func(i, j):
					changed = true
					items.append(j)
					items.append(i)
					_curr_index = i+1
					break
			if changed == true: break
		
		# if no change happened but we didn't start from 0, recheck 
		if changed == false && _curr_index > 0:
			_curr_index = 0
		else:
			break
	
	return {"done":!changed, "items":items}

# override
func step_all() -> Array:
	var indexes : Array
	for i in _data_size: indexes.append(i)
	
	while true:
		var changed : bool = false
		for i in range(0, _data_size):
			for j in range(i+1, _data_size):
				if _sort_callback.call_func(indexes[i], indexes[j]):
					changed = true
					var temp_i = indexes[i]
					indexes[i] = indexes[j]
					indexes[j] = temp_i
		
		if changed == false: break
	
	return indexes
