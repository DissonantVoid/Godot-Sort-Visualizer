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
var _pending_moves : Array # [[idx1, idx2], .. ]


# override
func setup(data_size : int, priority_callback : FuncRef):
	.setup(data_size, priority_callback)
	
	_division_arrays.resize(_data_size)
	for i in _data_size: _division_arrays[i] = [i]
	_pending_moves.clear()

# override
func next_step() -> Dictionary:
	# start with array of arrays (_division_array) where each subarray contains 1 index
	# merge first 2 indexes into 1 array, then next 2. combine them into 4, then merge another 2 and 2 into 4
	# and merge the 4 and 4 into 8 etc.. it's like 2048 the game
	# this way we can merge once, keep record of what has changed in that merge (_pending_moves)
	# and for each call to this func, return 1 move from the record, once the record is empty
	# we merge the next 2 arrays and so on
	if _pending_moves.empty():
		var i : int = 0
		while i < _division_arrays.size()-1:
			# everytime we have 2 subarrays with the same size next to each other we merge them
			# we also merge if we have only 2 arrays left regardless of the size
			if (_division_arrays[i].size() == _division_arrays[i+1].size() ||
					_division_arrays.size() == 2):
				
				# merge the two subarrays
				var merged_divisions : Array = _merge(_division_arrays[i], _division_arrays[i+1])
				
				# covert i from a 2d index where the first element is [0], to 1d index
				# where the first element is the sum of all previous indexes in all previous arrays
				var division_idx_1d : int = Utility.subarr_first_index_to_1d(_division_arrays, i)
				
				# merged_divisions contains ordered merge, and _division_arrays[i] now contains
				# unordered merge, we use the diff between them to fill _pending_moves
				_division_arrays[i].append_array(_division_arrays[i+1])
				_division_arrays.remove(i+1)
				
				# compare merged_divisions to _division_arr[i]
				while true:
					var changed : bool = false
					for j in _division_arrays[i].size():
						if _division_arrays[i][j] == merged_divisions[j]:
							continue
						
						changed = true
						var new_index : int
						for k in merged_divisions.size():
							# NOTE: since we're working with indexes, no 2 entries are the same
							if merged_divisions[k] == _division_arrays[i][j]:
								new_index = k
								Utility.move_element(_division_arrays[i], j, new_index)
								break
						
						_pending_moves.append([
							division_idx_1d + j,
							division_idx_1d + new_index
						])
					
					if changed == false:
						# TEMP
						print(_pending_moves)
						
						break
				
				# commit the ordered merge
				_division_arrays[i] = merged_divisions
				
				break
			
			i += 1
	
	if _division_arrays.size() == 1:
		# TODO: sometimes we end up with _division_arrays looking like [(size 64), (32), (16), (8)]
		#       preventing any further sorts hence the stackoverflow, this shouldn't happen
		return {"done":true}
	elif _pending_moves.empty() == false:
		return {"done":false, "action":SortAction.move, "indexes": _pending_moves.pop_front()}
	else:
#		# TEMP
#		var sizes : Array
#		for subarr in _division_arrays:
#			sizes.append(subarr.size())
#		print(sizes)
			
		return next_step()

# override
func skip_to_last_step() -> Array:
	return _divide_n_conquer_full(0, _data_size-1)

func _divide_n_conquer_full(low_bound : int, high_bound : int) -> Array:
	if low_bound == high_bound: # 1 item left
		return [low_bound]
	else:
		var middle_idx : int = low_bound + (high_bound - low_bound) / 2
		var first_half : Array = _divide_n_conquer_full(low_bound, middle_idx)
		var second_half : Array = _divide_n_conquer_full(middle_idx+1, high_bound)
		
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
