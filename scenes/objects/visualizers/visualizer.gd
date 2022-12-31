extends Control

# base class for all visualizers (objects that are sorted by the algorithms)

signal switched_items # we relly on this to allow visualizers to have fancy long animations


# override
func reset():
	pass

# override
func get_content_size() -> int:
	# sorters work with indexes and sort callback
	# so the size is needed
	return 0

# override, is item at idx1 bigger than item at idx2 ?
func sort_callback(idx1 : int, idx2 : int) -> bool:
	return false

# override
func switch_items(idx1 : int, idx2 : int):
	emit_signal("switched_items")

# override, this is called after sorter.step_all()
func switch_all(new_indexes : Array):
	pass

# override, for additional effects etc.. after sorting is finished
func finish():
	pass
