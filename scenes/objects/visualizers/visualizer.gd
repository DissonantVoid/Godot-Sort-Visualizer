extends Control

# base class for all visualizers (objects that are sorted by sorters)

# we use these signals to allow visualizers to take their time and do any effects etc
signal updated_indexes
signal updated_all
signal finished

# override
static func get_metadata() -> Dictionary:
	# "name"
	# "image": name and extension of an image in "res://resources/textures/visualizer_images/"
	# "description": short description
	# "is_enabled": visualizer can be used
	return {"name":"", "image":"", "description":"", "is_enabled":false}

# override
func reset():
	return

# override
# used by sorters to know how many indexes there are
func get_content_count() -> int:
	return 0

# override, is item at idx1 bigger/better/etc.. than item at idx2?
# called after each sort, except the last one
func determine_priority(idx1 : int, idx2 : int) -> bool:
	return false

# override
# see Sorter.SortAction for actions
func update_indexes(action : int, idx1 : int, idx2 : int):
	emit_signal("updated_indexes")

# override, this is called after sorter.step_all()
func update_all(new_indexes : Array):
	emit_signal("updated_all")

# override, called when user hides or shows main_interface panel
func set_ui_visibility(is_visible : bool):
	return

# override, for additional effects etc.. after sorting is finished
func finish():
	emit_signal("finished")
