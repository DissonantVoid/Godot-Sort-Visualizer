extends "res://scenes/objects/visualizers/visualizer.gd"

onready var _rects_container : HBoxContainer = $MarginContainer/HBoxContainer

const _h_gap : int = 2
const _rect_count : int = 120
const _rect_min_height : float = 10.0
const _rect_max_height : float = 460.0

var _colored_rects : Array
var _default_clr : Color = Color("ffeecc")
var _selected_high_clr : Color = Color("ff6973")
var _selected_low_clr : Color = Color("00b9be")


func _ready():
	_rects_container.add_constant_override("separation", _h_gap)
	
	# split height gap evenly between rects
	var rect_size_intervals : Array
	rect_size_intervals.resize(_rect_count)
	var v_gap : float = (_rect_max_height - _rect_min_height) / _rect_count
	for i in _rect_count:
		rect_size_intervals[i] = _rect_min_height + v_gap * i
	rect_size_intervals.shuffle() # NOTE: Utility calls randomize() 
	
	var rect_width : float = (Utility.viewport_size.x - _h_gap*_rect_count) / _rect_count
	for i in _rect_count:
		var rect : ColorRect = ColorRect.new()
		rect.color = _default_clr
		rect.size_flags_horizontal = 0 # no SIZE_NONE ???
		rect.size_flags_vertical = SIZE_SHRINK_END
		rect.rect_min_size.x = rect_width
		rect.rect_min_size.y = rect_size_intervals.pop_back()
		
		_rects_container.add_child(rect)

# override
static func get_metadata() -> Dictionary:
	return {
		"title":"VERTICAL_TITLE", "image":"vertical_rects.png",
		"description":"VERTICAL_DESC"
	}

# override
func reset():
	_clear_colors()
	# reshuffle children
	for i in _rects_container.get_child_count():
		var curr_child := _rects_container.get_child(i)
		_rects_container.move_child(curr_child, Utility.rng.randi_range(0, _rects_container.get_child_count()))

# override
func get_content_count() -> int:
	return _rects_container.get_child_count()

# override
func determine_priority(idx1 : int, idx2 : int) -> bool:
	return _rects_container.get_child(idx1).rect_min_size.y > _rects_container.get_child(idx2).rect_min_size.y

# override
func update_indexes(action : int, idx1 : int, idx2 : int):
	_clear_colors()
	
	match action:
		Sorter.SortAction.switch:
			# coloring
			var child1 = _rects_container.get_child(idx1)
			var child2 = _rects_container.get_child(idx2)
			child1.color = _selected_low_clr
			child2.color = _selected_high_clr
			_colored_rects.append(child1)
			_colored_rects.append(child2)
			
			Utility.switch_children(_rects_container, idx1, idx2)
		Sorter.SortAction.move:
			# coloring
			var child = _rects_container.get_child(idx1)
			child.color = _selected_low_clr
			_colored_rects.append(child)
			
			_rects_container.move_child(child, idx2)
	
	emit_signal("updated_indexes")

# override
func update_all(new_indexes : Array):
	var ordered_rects : Array
	for i in new_indexes:
		ordered_rects.append(_rects_container.get_child(i))
	
	for i in range(_rects_container.get_child_count()-1, -1, -1):
		_rects_container.remove_child(_rects_container.get_child(i))
	
	for rect in ordered_rects:
		_rects_container.add_child(rect)
	
	emit_signal("updated_all")

# override
func set_ui_visibility(is_visible : bool):
	return

# override
func finish():
	_clear_colors()
	emit_signal("finished")

func _clear_colors():
	for rect in _colored_rects:
		rect.color = _default_clr
	_colored_rects.clear()


func is_enabled() -> bool:
	return true
