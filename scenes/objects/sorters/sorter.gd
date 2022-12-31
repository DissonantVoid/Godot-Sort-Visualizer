extends Reference

# base class for all sorting algorithms

# override
func setup(data : Array, sort_callback : FuncRef):
	pass

# override, return true if we're done sorting
func next_step() -> bool:
	return false

# override, do all sorting
func step_all():
	pass
