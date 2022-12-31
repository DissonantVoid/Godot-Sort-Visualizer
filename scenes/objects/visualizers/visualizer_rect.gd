extends "res://scenes/objects/visualizers/visualizer.gd"

onready var _rects_container : HBoxContainer = $Rects

const _rect_count : int = 40
const _rect_width : float = 20.0
const _rect_min_height : float = 10.0
const _rect_max_height : float = 400.0

var _rng : RandomNumberGenerator = RandomNumberGenerator.new()

func _ready():
	_rng.randomize()
	
	for i in _rect_count:
		var rect : ColorRect = ColorRect.new()
		rect.size_flags_horizontal = SIZE_EXPAND # no SIZE_NONE ???
		rect.size_flags_vertical = SIZE_SHRINK_END
		rect.rect_min_size.x = _rect_width
		rect.rect_min_size.y = _rng.randf_range(_rect_min_height, _rect_max_height)
		
		_rects_container.add_child(rect)

# override
func get_content() -> Array:
	var content : Array
	for rect in _rects_container.get_children():
		content.append(rect.rect_min_size.y)
	
	return content

# override
func sort_callback(item1, item2) -> bool:
	return item1 > item2

# override
func switch_items(first, second):
	emit_signal("switched_items")
