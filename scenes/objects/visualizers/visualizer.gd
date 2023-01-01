extends Control

# base class for all visualizers (objects that are sorted by the algorithms)

signal switched_items # this allows visualizers to take their time to do any effects etc


# override
func reset():
	pass

# override
func get_content_count() -> int:
	# used by sorters to know how many indexes there are
	return 0

# override, is item at idx1 bigger/better/etc.. than item at idx2 ?
func determine_priority(idx1 : int, idx2 : int) -> bool:
	return false

# override
func update_indexes(idx1 : int, idx2 : int):
	emit_signal("switched_items")

# override, this is called after sorter.step_all()
func update_all(new_indexes : Array):
	pass

# override, for additional effects etc.. after sorting is finished
func finish():
	pass
