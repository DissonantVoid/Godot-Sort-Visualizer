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
#                   "items":(if "done" is true), 2 item indexes that were switched}
func next_step() -> Dictionary:
	return {}

# override, do all sorting and return new indexes
func skip_to_last_step() -> Array:
	return []
