extends Control

# base class for all visualizers (objects that are sorted by the algorithms)

signal switched_items


# override
func reset():
	pass

# override
func get_content() -> Array:
	return []

# override, is item1 bigger than item2 ?
func sort_callback(item1, item2) -> bool:
	return false

# override
func switch_items(first, second):
	emit_signal("switched_items")
