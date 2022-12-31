extends "res://scenes/objects/sorters/sorter.gd"


# override
func setup(data : Array, sort_callback : FuncRef):
	pass

# override
func next_step() -> bool:
	print("NEXT")
	return false

# override
func step_all():
	pass
