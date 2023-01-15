extends Control

# base class for all visualizers (objects that are sorted by the algorithms)

# we use these signals to allow visualizers to take their time and do any effects etc
signal updated_indexes
signal updated_all
signal finished

# override
# NOTE: reset is called after an algorithm is chosen, so we can show a "default"
#       visual in _ready before this is called (see visualizer_rect for example)
func reset():
	pass

# override
# used by sorters to know how many indexes there are
func get_content_count() -> int:
	return 0

# override, is item at idx1 bigger/better/etc.. than item at idx2?
# called after each sort, except the last one
func determine_priority(idx1 : int, idx2 : int) -> bool:
	return false

# override
func update_indexes(idx1 : int, idx2 : int):
	emit_signal("updated_indexes")

# override, this is called after sorter.step_all()
func update_all(new_indexes : Array):
	emit_signal("updated_all")

# override, called when user hides or shows main_interface panel
func set_ui_visibility(is_visible : bool):
	pass

# override, for additional effects etc.. after sorting is finished
func finish():
	emit_signal("finished")
