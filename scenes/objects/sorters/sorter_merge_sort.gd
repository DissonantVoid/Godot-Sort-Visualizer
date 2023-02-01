extends "res://scenes/objects/sorters/sorter.gd"

# https://en.wikipedia.org/wiki/Merge_sort
# a divide-and-conquer sorting algorithm that works by dividing the unsorted list
# into n sub-lists, each containing one element, and then repeatedly merging sub-lists
# into sorted sub-lists until there is only one sub-list remaining
#
# time complexity: Average: O(N log N)
#                  Worst:   O(N log N)
#                  Best:    O(N log N)

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
		var i = 1
		while i < _division_arrays.size():
			# everytime we have 2 subarrays with the same size next to each other we merge them
			# we also merge if we have only 2 arrays left regardless of the size
			if (_division_arrays[i-1].size() == _division_arrays[i].size() || 
					_division_arrays.size() == 2):
				
				# merge the two subarrays
				var merged_divisions : Array = _merge(_division_arrays[i-1], _division_arrays[i])
				
				var division_idx_1d : int = Utility.subarr_first_index_to_1d(_division_arrays, i-1)
				
				# merged_divisions contains ordered merge, and _division_arrays[i-1] now contains
				# unordered merge, we use the diff between them to fill _pending_switches
				_division_arrays[i-1].append_array(_division_arrays[i])
				_division_arrays.remove(i)
				
				# compare merged_divisions to _division_arr[i-1]
				for j in _division_arrays[i-1].size():
					if _division_arrays[i-1][j] == merged_divisions[j]:
						continue
					
					var new_index : int
					for k in merged_divisions.size():
						# NOTE: since we're working with indexes, no 2 entries are the same
						if merged_divisions[k] == _division_arrays[i-1][j]:
							new_index = k
							break
					
					_pending_switches.append([
						# biggest index first because [1,0] is not the same as [0,1]
						division_idx_1d + max(j,new_index),
						division_idx_1d + min(j,new_index)
					])
				
				# TEMP: note that everything untill here is working as intended,
				#       problems happen after this point 
				
				# remove duplicates
				for j in _pending_switches.size():
					for k in range(j+1, _pending_switches.size()):
						if _pending_switches[j] == _pending_switches[k]:
							_pending_switches.remove(k)
							break
				
				# commit the ordered merge
				_division_arrays[i-1] = merged_divisions
				
				if _pending_switches.empty():
					# arrays merged perfectly without having to change indexes i,e [1,2,3] + [4,5,6]
					should_skip_to_next = true
				
				# TEMP
				print("content:" + str(_division_arrays))
				print("switches:" + str(_pending_switches))
				break
			
			i += 1
	
	if should_skip_to_next:
		return next_step()
	elif _pending_switches.empty():
		# still empty? we're done
		return {"done":true}
	else:
		var indexes_to_switch : Array = _pending_switches.pop_front()
		
		# update entries in indexes_to_switch
#		if indexes_to_switch[0] > indexes_to_switch[1]:
#			for switch in _pending_switches:
#				for i in switch.size():
#					if switch[i] == indexes_to_switch[0]: switch[i] = indexes_to_switch[1]
#					elif switch[i] >= indexes_to_switch[1] && switch[i] < indexes_to_switch[0]:
#						switch[i] += 1
#		elif indexes_to_switch[0] < indexes_to_switch[1]:
#			for switch in _pending_switches:
#				for i in switch.size():
#					if switch[i] == indexes_to_switch[0]: switch[i] = indexes_to_switch[1]-1
#					elif switch[i] > indexes_to_switch[1] && switch[i] < indexes_to_switch[0]:
#						switch[i] -= 1
		
		print("switches changed to: ", str(_pending_switches))
		return {"done":false, "action":SortAction.move, "indexes": indexes_to_switch}

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
