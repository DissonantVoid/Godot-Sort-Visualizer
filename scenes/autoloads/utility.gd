extends Node # can't be a reference since godot automaticaly adds a node to autoload scripts

var rng : RandomNumberGenerator = RandomNumberGenerator.new()

func _init():
	rng.randomize()

func swap(arr : Array, idx1 : int, idx2 : int):
	assert(idx1 >= 0 && idx1 < arr.size() && idx2 >= 0 && idx2 < arr.size(), "index out of bound")
	
	var temp = arr[idx1]
	arr[idx1] = arr[idx2]
	arr[idx2] = temp

static func switch_children(parent : Node, child1_idx : int, child2_idx : int):
	var low_idx_child := parent.get_child(min(child1_idx, child2_idx))
	var high_idx : int = max(child1_idx, child2_idx)
	var high_idx_child := parent.get_child(high_idx)
	
	parent.move_child(high_idx_child, low_idx_child.get_index())
	parent.move_child(low_idx_child, high_idx)

static func move_element(arr : Array, el_idx : int, el_new_idx : int):
	assert(el_idx >= 0 && el_idx < arr.size(), "el_idx must be >= 0 and < arr.size()")
	assert(el_new_idx >= 0 && el_new_idx <= arr.size(), "el_new_idx must be >= 0 and <= arr.size()")
	
	var element = arr[el_idx]
	arr.remove(el_idx)
	if el_idx < el_new_idx:
		arr.insert(el_new_idx-1, element)
	else:
		arr.insert(el_new_idx, element)

static func subarr_first_index_to_1d(arr : Array, subarr_idx : int) -> int:
	assert(subarr_idx >= 0 && subarr_idx < arr.size(), "index out of bound")
	
	# NOTE: only checks 1 depth (array of arrays), doesn't work on array of arrays of arrays and so on
	var index_1d : int = 0
	for i in range(0, subarr_idx):
		assert(arr[i] is Array, "array must contains arrays")
		index_1d += arr[i].size()
	
	return index_1d
