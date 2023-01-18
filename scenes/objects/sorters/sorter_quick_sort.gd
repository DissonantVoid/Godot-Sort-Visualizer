extends "res://scenes/objects/sorters/sorter.gd"

# https://en.wikipedia.org/wiki/Quicksort
# based on the Divide and Conquer paradigm, in this algorithm
# we pick a pivot and partitioning the other elements into two sub-arrays
# according to whether they are less or greater than the pivot
#
# time complexity: O(N log N)

var _pivot_idx : int
var _index : int
var _splits : Array # [{"low":low_bound, "high":high_bound}, ..]
var _curr_split_idx : int


# override
func setup(data_size : int, priority_callback : FuncRef):
	.setup(data_size, priority_callback)
	
	_splits = [ {"low":0, "high":_data_size-1} ] # start with whole array
	_curr_split_idx = 0
	_pivot_idx = _splits[_curr_split_idx]["low"]
	_index = _pivot_idx + 1

# override
func next_step() -> Dictionary:
	var curr_split : Dictionary = _splits[_curr_split_idx]
	
	# skip subarrays of size 1
	while curr_split["low"] == curr_split["high"]:
		_curr_split_idx += 1
		if _curr_split_idx > _splits.size()-1:
			return {"done":true}
		
		curr_split = _splits[_curr_split_idx]
		_pivot_idx = curr_split["low"]
		_index = _pivot_idx + 1
	
	if _index > curr_split["high"]:
		# once we're done with the current split, we split it into 2 arrays (plus the pivot)
		# and go through them one by one
		_splits.remove(_curr_split_idx)
		if _pivot_idx+1 <= curr_split["high"]:
			_splits.insert(_curr_split_idx, {"low":_pivot_idx+1, "high":curr_split["high"]})
		_splits.insert(_curr_split_idx, {"low":_pivot_idx, "high":_pivot_idx})
		if _pivot_idx-1 >= curr_split["low"]:
			_splits.insert(_curr_split_idx, {"low":curr_split["low"], "high":_pivot_idx-1})
		
		curr_split = _splits[_curr_split_idx]
		_pivot_idx = curr_split["low"]
		_index = _pivot_idx + 1
		return next_step()
	
	if _priority_callback.call_func(_pivot_idx, _index):
		var index_to_move : Array = [_index, _pivot_idx]
		_index += 1
		_pivot_idx += 1
		return {"done":false, "action":SortAction.move, "indexes":index_to_move}
	else:
		_index += 1
		return next_step()

# override
func skip_to_last_step() -> Array:
	var indexes : Array
	indexes.resize(_data_size)
	for i in _data_size: indexes[i] = i
	
	return _divide_n_conquer_full(indexes, 0, _data_size-1)

func _divide_n_conquer_full(arr : Array, low_bound : int, high_bound : int) -> Array:
	if low_bound == high_bound:
		return [arr[low_bound]]
	
	# we use first index as a pivot, but there are other approaches
	var pivot_idx : int = low_bound
	for i in range(low_bound+1, high_bound+1):
		if _priority_callback.call_func(arr[pivot_idx], arr[i]):
			var value : int = arr[i]
			arr.remove(i)
			arr.insert(pivot_idx, value)
			pivot_idx += 1
	
	var ordered_arr : Array
	if pivot_idx-1 >= low_bound: ordered_arr.append_array(_divide_n_conquer_full(arr, low_bound, pivot_idx-1))
	ordered_arr.append(arr[pivot_idx])
	if pivot_idx+1 <= high_bound: ordered_arr.append_array(_divide_n_conquer_full(arr, pivot_idx+1, high_bound))
	
	return ordered_arr
