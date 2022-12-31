extends Reference

# base class for all sorting algorithms

var _data_size : int
var _sort_callback : FuncRef

# override
func setup(data_size : int, sort_callback : FuncRef):
	# NOTE: this can be called at any time so don't forget to cleanup
	_data_size = data_size
	_sort_callback = sort_callback

# override, return {"done":is done sorting,
#                   "items":2 item indexes that were switched}
func next_step() -> Dictionary:
	return {}

# override, do all sorting
func step_all():
	pass
