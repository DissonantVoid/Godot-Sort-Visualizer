extends "res://scenes/objects/sorters/sorter.gd"

# https://en.wikipedia.org/wiki/Bogosort
# this is more of a joke if anything, we simply shuffle indexes randomly
# and wish for a miracle. keep in mind that there is a non zero
# possibility that a bogo sort will sort your array faster than the majority of other
# algorithm
#
# time complexity: Average: O(N * N!)
#                  Worst:   O(infinity)
#                  Best:    O(N)

# NOTE: using any of the functions below in a large array (by large I mean bigger than 5 or so)
#          will take so long to sort that the game window will stop responding


# override
func next_step() -> Dictionary:
	# check if array is sorted
	var is_sorted : bool = true
	for i in range(1, _data_size):
		if _priority_callback.call_func(i-1, i):
			is_sorted = false
			break
	
	if is_sorted:
		return {"done":true}
	
	var idx1 : int = Utility.rng.randi_range(0, _data_size-1)
	var idx2 : int = Utility.rng.randi_range(0, _data_size-2)
	if idx2 >= idx1: idx2 += 1
	
	return {"done":false, "action":SortAction.switch, "indexes":[idx1, idx2]}

# override
func skip_to_last_step() -> Array:
	var indexes : Array
	indexes.resize(_data_size)
	for i in _data_size: indexes[i] = i
	
	while true:
		# check if array is sorted
		var is_sorted : bool = true
		for i in range(1, indexes.size()):
			if _priority_callback.call_func(indexes[i-1], indexes[i]):
				is_sorted = false
				break
		
		if is_sorted: break
		indexes.shuffle()
	
	return indexes


func is_enabled() -> bool:
	return true


func get_sorter_name() -> String:
	return tr("Bogosort")