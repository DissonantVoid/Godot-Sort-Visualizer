extends "res://scenes/objects/sorters/sorter.gd"

# https://en.wikipedia.org/wiki/Heapsort
# similar to selection sort, we split the array virtualy into a
# sorted and not sorted halves, each step we take the smallest value
# in the unsorted half and move it ... 
# but instead of linearly iterating over the unsorted half, we use a heap
# data structure
# NOTE: in Array.sort(), godot seems to use heap-sort as well as quick-sort
#       mixed together in an intro-sort. I could be wrong but this is what
#       I can see here: github.com/godotengine/godot/blob/master/core/templates/sort_array.h
#
# time complexity: O(N LOG N)

var _index : int
var _heap_arr : Array


# override
func setup(data_size : int, priority_callback : FuncRef):
	.setup(data_size, priority_callback)
	
	_index = 0
	
	_heap_arr.clear()
	_heap_arr.resize(_data_size)
	for i in _data_size: _heap_arr[i] = i
	_heapify(_heap_arr)

# override
func next_step() -> Dictionary:
	if _index == _data_size: return {"done":true}
	
	var smallest_idx : int = _h_pop_root(_heap_arr)
	
	# once the smallest index is poped, and the visualizer switches the 2 children
	# we update the index in _heap_arr to sync with the content of the visualizer
	var index_pos_in_heap : int = _heap_arr.find(_index)
	if index_pos_in_heap != -1:
		_heap_arr[index_pos_in_heap] = smallest_idx
	
	_index += 1
	
	if smallest_idx == _index-1:
		return next_step()
	else:
		return {"done":false, "action":SortAction.switch, "indexes":[_index-1, smallest_idx]}

# override
func skip_to_last_step() -> Array:
	var indexes : Array
	indexes.resize(_data_size)
	for i in _data_size: indexes[i] = i
	_heapify(indexes)
	
	var sorted_arr : Array
	sorted_arr.resize(_data_size)
	for i in sorted_arr.size():
		sorted_arr[i] = _h_pop_root(indexes)
	
	return sorted_arr

func _heapify(arr : Array):
	# NOTE: this is a min-heap implementation, meaning the root is the smallest value
	# start from the middle, because the middle point is guaranteed to be the last non-leaf node
	for i in range((arr.size()/2)-1, -1, -1):
		_h_sift_down(arr, i)

func _h_pop_root(arr : Array) -> int:
	var root_idx : int = arr[0]
	
	# swap root with last element, then descend new root down the tree untill it's in the right spot
	Utility.swap_elements(arr, 0, arr.size()-1)
	# delete previous root
	arr.remove(arr.size()-1)
	_h_sift_down(arr, 0)
	
	return root_idx

func _h_sift_down(arr : Array, index : int): # no I didn't loose my teeth, it's sift not shift
	# ascend the tree untill parent is smaller or we're root
	# NOTE: it is common when implementing a heap sort to not actually use a binary tree object
	#       instead we simply use an array, we can then traverse the array as if it was a tree
	#       for example to find the parent of an index we can do (index - 1) / 2
	#       and to find the left child (as we do bellow) we can do index * 2 + 1 and so on
	var left_child : int
	var right_child : int
	while true:
		left_child = index * 2 + 1
		if left_child >= arr.size(): left_child = -1
		
		right_child = index * 2 + 2
		if right_child >= arr.size(): right_child = -1
		
		# find the smallest child if any
		var smallest_idx : int
		if left_child == -1 && right_child == -1:
			break
		elif left_child == -1:
			smallest_idx = right_child
		elif right_child == -1:
			smallest_idx = left_child
		else:
			if _priority_callback.call_func(arr[right_child], arr[left_child]):
				smallest_idx = left_child
			else:
				smallest_idx = right_child
		
		# swap with the smallest child
		
		if (_priority_callback.call_func(arr[index], arr[smallest_idx])):
			Utility.swap_elements(arr, index, smallest_idx)
			index = smallest_idx
			continue
		
		# if we reach this, both children are bigger
		break


func is_enabled() -> bool:
	return true


func get_sorter_name() -> String:
	return tr("Heap sort")