class_name Sorter
extends Reference

# base class for all sorting algorithms

var _data_size : int
var _priority_callback : FuncRef

enum SortAction {switch, move}


# override
func setup(data_size : int, priority_callback : FuncRef):
	# NOTE: this is called any time we press restart so don't forget to cleanup
	_data_size = data_size
	_priority_callback = priority_callback

# override, return {"done":is done sorting,
#                   (if "done" is true we don't need to include next entries)
#                   "action": SortAction.switch (switch indexes[0] and [1]),
#                             SortAction.move (move indexes[0] behind [1])
#                   "indexes": array of 2 indexes that were switched}
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


# override, return true if and only if this sorter should be used.
#			If false, the sorter does not appear in the popup
func is_enabled() -> bool:
	return false


# override, return the name of the sorter
func get_sorter_name() -> String:
	return ""