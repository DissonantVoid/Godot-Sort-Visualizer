extends "res://scenes/objects/visualizers/visualizer.gd"

onready var _rects_container : HBoxContainer = $MarginContainer/HBoxContainer

const _rect_count : int = 40
const _rect_width : float = 20.0
const _rect_min_height : float = 10.0
const _rect_max_height : float = 400.0

var _rng : RandomNumberGenerator = RandomNumberGenerator.new()

var _previously_switched : Array

func _ready():
	_rng.randomize()
	
	for i in _rect_count:
		var rect : ColorRect = ColorRect.new()
		rect.size_flags_horizontal = SIZE_EXPAND # no SIZE_NONE ???
		rect.size_flags_vertical = SIZE_SHRINK_END
		rect.rect_min_size.x = _rect_width
		rect.rect_min_size.y = _rect_max_height
		
		_rects_container.add_child(rect)

# override
func reset():
	_clear_colors()
	for child in _rects_container.get_children():
		child.rect_min_size.y = _rng.randf_range(_rect_min_height, _rect_max_height)

# override
func get_content_size() -> int:
	return _rects_container.get_child_count()

# override
func sort_callback(idx1 : int, idx2 : int) -> bool:
	return _rects_container.get_child(idx1).rect_min_size.y > _rects_container.get_child(idx2).rect_min_size.y

# override
func switch_items(idx1 : int, idx2 : int):
	_clear_colors()
	
	var low_idx_child : ColorRect = _rects_container.get_child(min(idx1, idx2))
	var high_idx : int = max(idx1, idx2)
	var high_idx_child : ColorRect = _rects_container.get_child(high_idx)
	
	# coloring
	low_idx_child.color = Color.blue
	high_idx_child.color = Color.red
	_previously_switched.append(low_idx_child)
	_previously_switched.append(high_idx_child)
	
	_rects_container.move_child(high_idx_child, low_idx_child.get_index())
	_rects_container.move_child(low_idx_child, high_idx+1)
	emit_signal("switched_items")

# override
func switch_all(new_indexes : Array):
	var rects : Array
	for i in new_indexes:
		rects.append(_rects_container.get_child(i))
	
	for i in range(_rects_container.get_child_count()-1, -1, -1):
		_rects_container.remove_child(_rects_container.get_child(i))
	
	for rect in rects:
		_rects_container.add_child(rect)

# override
func finish():
	_clear_colors()

func _clear_colors():
	if _previously_switched.empty() == false:
		_previously_switched[0].color = Color.white
		_previously_switched[1].color = Color.white
		_previously_switched.clear()
