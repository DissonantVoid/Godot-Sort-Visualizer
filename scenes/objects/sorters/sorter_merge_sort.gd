extends "res://scenes/objects/sorters/sorter.gd"

# https://en.wikipedia.org/wiki/Merge_sort
# based on the Divide and Conquer paradigm
# in this algorithm, the array is initially divided into two equal halves
# and then they are combined in a sorted manner
#
# time complexity: O(N log N)

var _division_arrays : Array
var _pending_switches : Array # [[idx1, idx2], .. ]


# override
func setup(data_size : int, priority_callback : FuncRef):
	.setup(data_size, priority_callback)
	
	_division_arrays.resize(_data_size)
	for i in _data_size: _division_arrays[i] = [i]
	_pending_switches.clear()

# override
# TODO: THIS IS UNFINISHED, the impementation is almost done but not yet complete
#       I have already wasted too much time getting this one function to work
#       as much as I like a good challenge, I also know my limits, and have
#       to leave it for now and come back in the future,
func next_step() -> Dictionary:
	# start with array of arrays (_division_array) where each subarray contains 1 index
	# merge first 2 indexes into 1 array, then next 2. combine them into 4, then merge another 2 and 2 into 4
	# and merge the 4 and 4 into 8 etc.. it's like 2048 the game
	# this way we can merge once, keep record of what has changed in that merge (_pending_switches)
	# and for each call to this func, return 1 switch from the record, once the record is empty
	# we merge the next 2 arrays and so on
	var should_skip_to_next : bool = false
	if _pending_switches.empty():
		var prev_subarrs_size : int = 0 # size of all previous subarrays before _division_array[i-1]
										# in other words this converts the index of first element in current subarray
										# from 2d to 1d
		for i in range(1, _division_arrays.size()):
			# everytime we have 2 subarrays with the same size next to each other we merge them
			# we also merge if we have only 2 arrays left regardless of the size
			if (_division_arrays[i-1].size() == _division_arrays[i].size() || 
					_division_arrays.size() == 2):
				
				# merge the two subarrays
				_division_arrays[i-1] = _merge(_division_arrays[i-1], _division_arrays[i])
				_division_arrays.remove(i)
				
				for j in _division_arrays[i-1].size():
					var original_index : int = _division_arrays[i-1][j]
					var new_index : int = prev_subarrs_size + j
					
					if original_index == new_index: continue
					
					# get rid of inverted duplicates i.e [ [0,1], [1,0] ]
					if  _pending_switches.has([new_index, original_index]) == false:
						_pending_switches.append([original_index, new_index])
					
				if _pending_switches.empty() && _division_arrays.size() > 1:
					# arrays merged perfectly without having to change indexes i,e [1,2,3] + [4,5,6]
					should_skip_to_next = true
				
				print("switches:" + str(_pending_switches)) # TEMP
				break
			else:
				prev_subarrs_size += _division_arrays[i-1].size()
	
	if should_skip_to_next:
		return next_step()
	elif _pending_switches.empty():
		# still empty? we're done
		return {"done":true}
	else:
		var indexes_to_switch : Array
		indexes_to_switch.resize(2)
		indexes_to_switch[0] = _pending_switches[0][0]
		indexes_to_switch[1] = _pending_switches[0][1]
		
		# THIS is where we have a problem
		# for example let's say that the array to sort is [7, 6, 3, 4, 0, 2, 1, 9, 5, 8]
		# and _pending_switches = [[8, 0], [4, 2], [0, 3], [6, 5], [3, 7], [9, 8], [7, 9]]
		# by the time we apply to 4th switch [3, 7], we would have already applied the 2nd switch
		# [0, 3] meaning that the index 3 in [3, 7] will not be the same because it was switched with
		# something else previously
		
		_pending_switches.remove(0)
		
		print("switch changed to: " + str(_pending_switches)) # TEMP
		return {"done":false, "indexes": [indexes_to_switch[0], indexes_to_switch[1]]}

# override
func skip_to_last_step() -> Array:
	return _divide_n_conquer_full(0, _data_size-1)

func _divide_n_conquer_full(low_bound : int, high_bound : int) -> Array:
	if low_bound == high_bound: # 1 item left
		return [low_bound]
	else:
		var middle : int = low_bound + (high_bound - low_bound) / 2
		var first_half : Array = _divide_n_conquer_full(low_bound, middle)
		var second_half : Array = _divide_n_conquer_full(middle+1, high_bound)
		
		return _merge(first_half, second_half)

func _merge(first_half : Array, second_half : Array):
	# merge 2 arrays together, merging is done by comparing the first item of one array
	# to the first item of another, we move the smaller into 'combined' and increment
	# its index (first_h_idx or second_h_idx depending on which item is bigger) and so on..
	# note that since arrays are already ordered (first item is smallest and last is largest)
	# we end up with an ordered combined array
	var combined : Array
	var first_h_idx : int = 0
	var second_h_idx : int = 0
	while first_h_idx < first_half.size() && second_h_idx < second_half.size():
		if _priority_callback.call_func(first_half[first_h_idx], second_half[second_h_idx]):
			combined.append(second_half[second_h_idx])
			second_h_idx += 1
		else:
			combined.append(first_half[first_h_idx])
			first_h_idx += 1
	
	# we may end up with items remaining in one of the arrays, in that case we just
	# dump them into 'combined' since we know they're bigger than any item in 'combined'
	if first_h_idx < first_half.size():
		combined.append_array(first_half.slice(first_h_idx, first_half.size()-1))
	if second_h_idx < second_half.size():
		combined.append_array(second_half.slice(second_h_idx, second_half.size()-1))
	
	return combined
