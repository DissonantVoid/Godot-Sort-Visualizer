extends Node # can't be a reference since godot automaticaly adds a node to autoload scripts

var rng : RandomNumberGenerator = RandomNumberGenerator.new()

func _init():
	rng.randomize()

# should this be in visualizer.gd just like _swap() is in sorter.gd ?
static func switch_children(parent : Node, child1_idx : int, child2_idx : int):
	var low_idx_child := parent.get_child(min(child1_idx, child2_idx))
	var high_idx : int = max(child1_idx, child2_idx)
	var high_idx_child := parent.get_child(high_idx)
	
	parent.move_child(high_idx_child, low_idx_child.get_index())
	parent.move_child(low_idx_child, high_idx)
