extends Control

# base class for all visualizers (objects that are sorted by sorters)

# we use these signals to allow visualizers to take their time and do any effects etc
signal updated_indexes
signal updated_all
signal finished

# override
static func get_metadata() -> Dictionary:
	# "title"
	# "image": name and extension of an image in "res://resources/textures/visualizer_images/"
	# "description": short description
	return {}

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


# override, return true if and only if this visualizer should be used.
#			If false, the visualizer does not appear in the popup
func is_enabled() -> bool:
	return false


func get_visualizer_name() -> String:
	return get_metadata()["title"]
