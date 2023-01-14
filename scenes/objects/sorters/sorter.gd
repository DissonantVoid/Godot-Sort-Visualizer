extends Reference

# base class for all sorting algorithms

var _data_size : int
var _priority_callback : FuncRef

# override
func setup(data_size : int, priority_callback : FuncRef):
	# NOTE: this can be called at any time so don't forget to cleanup
	_data_size = data_size
	_priority_callback = priority_callback

# override, return {"done":is done sorting,
#                   "indexes":(if "done" is true), array of 2 indexes that were switched}
# NOTE: in "indexes" the first index should preferably be smaller than the second, some visualizers
#       use that, like visualizer_rect which uses that for accurate coloring
#       also indexes[0] should never equal to indexes[1]
func next_step() -> Dictionary:
	return {}

# override, do all sorting and return new indexes
#           this is where you implement the pure sorting algorithm
#           without all the state keeping needed for next_step()
func skip_to_last_step() -> Array:
	return []
