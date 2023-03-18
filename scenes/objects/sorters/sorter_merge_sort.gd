extends "res://scenes/objects/sorters/sorter.gd"

# https://en.wikipedia.org/wiki/Merge_sort
# a divide-and-conquer sorting algorithm that works by dividing the unsorted list
# into n sub-lists, each containing one element, and then repeatedly merging sub-lists
# into sorted sub-lists until there is only one sub-list remaining
#
# time complexity: Average: O(N log N)
#                  Worst:   O(N log N)
#                  Best:    O(N log N)

enum Action {
	SPLIT,
	MERGE,
}

# _pending_moves contains the moves to perform to sort the whole array. The next move is at the end of the array
# It contains "tuples" starting with the action.
#	If the action is SPLIT, the remaining data are 	the index of the first element of the sub-array to split
#												and the size of the sub-array
# 	If the action is MERGE, the remaining data are	the index of the first element of the first sub-array
#													the size of the first sub-array
#													the index of the first element of the second sub-array
#												and the size of the second sub-array
var _pending_moves : Array # [[action, idx1, idx2], .. ]


# override
func setup(data_size : int, priority_callback : FuncRef):
	.setup(data_size, priority_callback)
	
	_pending_moves.clear()
	# The first move is to split in half the whole array
	_pending_moves.append([Action.SPLIT, 0, _data_size])

# override
func next_step() -> Dictionary:
	if _pending_moves.empty():
		return {"done": true}
	
	var move = _pending_moves.pop_back()

	if move[0] == Action.SPLIT:
		var start_subarray: int = move[1]
		var size_subarray: int = move[2]

		var size_first: int = floor(size_subarray / 2.0)
		var size_second: int
		if size_first * 2 != size_subarray:
			size_second = size_first + 1
		else:
			size_second = size_first

		var start_second := start_subarray + size_first

		_pending_moves.append([Action.MERGE, start_subarray, start_second, size_first, size_second])
		if size_second > 1:
			_pending_moves.append([Action.SPLIT, start_second, size_second])
		if size_first > 1:
			_pending_moves.append([Action.SPLIT, start_subarray, size_first])

		return next_step()

	else: # move[0] == Action.MERGE
		var start_first: int = move[1]
		var start_second: int = move[2]
		var size_first: int = move[3]
		var size_second: int = move[4]
		
		if size_first == 0 || size_second == 0 || start_second >= _data_size:
			# Only one of the array contains values
			# As the other array is already sorted, we have nothing to do
			return next_step()

		# Both arrays contain values. We pick the smallest value between start_first and start_second
		# if array[_start_first] < array[_start_second]
		if _priority_callback.call_func(start_second, start_first):
			# We do not have to swap anything as the smallest value is already at the front
			_pending_moves.append([Action.MERGE, start_first + 1, start_second, size_first - 1, size_second])
			return next_step()
		else:
			# This time, we have to move the head of the second array to where the head of the first array currently lies
			# As we move every unsorted value to the right, the index of the first array also moves to the right
			_pending_moves.append([Action.MERGE, start_first + 1, start_second + 1, size_first, size_second - 1])
			return {"done":false, "action":SortAction.move, "indexes": [start_second, start_first]}


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


func is_to_use() -> bool:
	return true


func get_sorter_name() -> String:
	return tr("MERGESORT")
