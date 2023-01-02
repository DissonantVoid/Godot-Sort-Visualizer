extends Control

# base class for all visualizers (objects that are sorted by the algorithms)

signal updated_indexes # this allows visualizers to take their time to do any effects etc
signal updated_all

# override
# NOTE: reset is called after an algorithm is chosen, so we can show a "default"
#       visual before it's called (see visualizer_rect for example)
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
	emit_signal("updated_indexes")

# override, this is called after sorter.step_all()
func update_all(new_indexes : Array):
	emit_signal("updated_all")

# override, called when user hides of shows algorithm_picker panel
func set_ui_visibility(is_visible : bool):
	pass

# override, for additional effects etc.. after sorting is finished
func finish():
	pass
