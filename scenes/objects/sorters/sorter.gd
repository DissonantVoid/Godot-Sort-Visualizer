extends Reference

# base class for all sorting algorithms

func setup(items : Array, sort_callback : FuncRef):
	pass

func next() -> bool:
	# return true if we're done sorting
	return false

func all():
	pass
