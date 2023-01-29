extends "res://scenes/objects/visualizers/visualizer.gd"

onready var _lines_container : Control = $Lines
onready var _camera : Camera2D = $Camera2D
onready var _scroll : HScrollBar = $CanvasLayer/HScrollBar

const _min_height : float = 100.0
const _max_height : float = 500.0
const _horizontal_gap : float = 45.0
const _lines_count : int = 20
const _line_width : float = 6.2

const _ruler_big_line_width : float = 2.2
const _ruler_small_line_width : float = 0.6
const _ruler_small_lines_count : int = 3
const _ruler_color : Color = Color("32ffeecc")

const _high_color : Color = Color("ff6973")
const _low_color : Color = Color.black

var _lines_order : Array
var _next_x : float
# the order in _lines_order is not based on the starting point of the lines, but rather
# on the order of the last point, the thing is that this last point changes over time as the line
# expands and doesn't always match with the first point's position
# the problem is that when we reset, we need to shuffle _lines_order to produce a new order
# based on first point of each line but (again) _lines_order points to the order of the last points
# the solution is to keep a record of the lines first point position before
# we start sorting and reset _lines_order to it once we're done
var _1st_point_lines_order : Array

# TODO: needs some attention to details, for example update_all() moves all lines to the right
#       position instantly instead of one at a time like update_indexes()
#       also we should probably tween lines from one point to the next in update_indexes()
#       line colors need some work too, especially how the first few line almost match in color
#       the way scrolling works is also pretty stupid

func _ready():
	_lines_order.resize(_lines_count)
	var v_gap : float = (_max_height - _min_height) / _lines_count
	for i in _lines_count:
		var line : Line2D = Line2D.new()
		line.default_color = lerp(_high_color, _low_color, float(i) / _lines_count)
		line.width = _line_width
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		
		_lines_container.add_child(line)
		var y_pos : float = _min_height + v_gap * i
		line.global_position = Vector2(0, y_pos)
		line.add_point(Vector2.ZERO)
		line.set_meta("correct_order", i)
		
		_lines_order[i] = line
	
	_1st_point_lines_order = _lines_order.duplicate()

func _draw():
	# draw ruler
	var start_x : float = stepify(_camera.global_position.x, _horizontal_gap)
	var end_x : float = stepify(
		_camera.global_position.x + Utility.viewport_size.x, _horizontal_gap
	) + _horizontal_gap
	
	# apparently custom drawings won't show unless the node drawing them
	# is visible in the screen
	rect_size.x = end_x
	
	for i in range(start_x, end_x, _horizontal_gap):
		# big line
		var line_start : Vector2 = Vector2(i, Utility.viewport_size.y)
		draw_line(
			line_start,
			line_start - Vector2(0, Utility.viewport_size.y),
			_ruler_color,
			_ruler_big_line_width
		)
		
		# small lines
		for j in range(i, i + _horizontal_gap, _horizontal_gap / (_ruler_small_lines_count+1)):
			var small_line_start : Vector2 = Vector2(j, Utility.viewport_size.y)
			draw_line(
				small_line_start,
				small_line_start - Vector2(0, Utility.viewport_size.y),
				_ruler_color,
				_ruler_small_line_width
			)

# override
static func get_metadata() -> Dictionary:
	return {
		"title":"color bars", "image":"color_bars.png",
		"description":"Horizontal bars that continuously swap position while visually keeping record of their old positions"
	}

# override
func reset():
	# clear points
	for line in _lines_order:
		line.clear_points()
		line.add_point(Vector2.ZERO)
		line.add_point(Vector2(_horizontal_gap, 0))
	
	_next_x = _horizontal_gap * 2
	_lines_order = _1st_point_lines_order
	
	# shuffle, on each step we swap global_position and order in _lines_order
	for i in _lines_order.size():
		var line : Line2D = _lines_order[i]
		
		var rand_idx : int = Utility.rng.randi_range(0, _lines_count-2)
		if rand_idx >= i: rand_idx += 1
		var rand_line : Line2D = _lines_order[rand_idx]
		
		var line_pos : Vector2 = line.global_position
		line.global_position = rand_line.global_position
		rand_line.global_position = line_pos
		
		Utility.swap_elements(_lines_order, i, rand_idx)
	
	_1st_point_lines_order = _lines_order.duplicate()
	
	_camera.global_position.x = 0
	_scroll.value = 0
	update()

# override
func get_content_count() -> int:
	return _lines_count

# override
func determine_priority(idx1 : int, idx2 : int) -> bool:
	return _lines_order[idx1].get_meta("correct_order") >\
		_lines_order[idx2].get_meta("correct_order")

# override
func update_indexes(action : int, idx1 : int, idx2 : int):
	# TODO: simplify
	match action:
		Sorter.SortAction.switch:
			var line1 : Line2D = _lines_order[idx1]
			var line2 : Line2D = _lines_order[idx2]
			var line1_last_p_as_line2_local : Vector2 =\
				_transform_local_point_from_node_to_node(line1, line1.points[-1], line2)
			var line2_last_p_as_line1_local : Vector2 =\
				_transform_local_point_from_node_to_node(line2, line2.points[-1], line1)
			
			# extend both lines to the _next_x
			line1.add_point(Vector2(
				_next_x,
				line2_last_p_as_line1_local.y
			))
			
			line2.add_point(Vector2(
				_next_x,
				line1_last_p_as_line2_local.y
			))
			
			_extend_all_lines(_next_x)
			_next_x += _horizontal_gap
			Utility.swap_elements(_lines_order, idx1, idx2)
		
		Sorter.SortAction.move:
			if idx1 > idx2:
				var idx2_old_pos : Vector2 = _lines_order[idx2].points[-1]
				for i in range(idx2, idx1):
					
					_lines_order[i].add_point(Vector2(
						_next_x,
						_transform_local_point_from_node_to_node(
							_lines_order[i+1], _lines_order[i+1].points[-1], _lines_order[i]
						).y
					))
				
				_lines_order[idx1].add_point(Vector2(
					_next_x,
					_transform_local_point_from_node_to_node(
						_lines_order[idx2], idx2_old_pos, _lines_order[idx1]
					).y
				))
			
			elif idx1 < idx2:
				var idx2_old_pos : Vector2 = _lines_order[idx2-1].points[-1]
				for i in range(idx2-1, idx1, -1):
					
					_lines_order[i].add_point(Vector2(
						_next_x,
						_transform_local_point_from_node_to_node(
							_lines_order[i-1], _lines_order[i-1].points[-1], _lines_order[i]
						).y
					))
				
				_lines_order[idx1].add_point(Vector2(
					_next_x,
					_transform_local_point_from_node_to_node(
						_lines_order[idx2-1], idx2_old_pos, _lines_order[idx1]
					).y
				))
			
			Utility.move_element(_lines_order, idx1, idx2)
			_extend_all_lines(_next_x)
			_next_x += _horizontal_gap
	
	emit_signal("updated_indexes")

# override
func update_all(new_indexes : Array):
	var new_Ys : Array # each entry represents the x of a a to-be-added point to _lines_order[i]
	new_Ys.resize(new_indexes.size())
	for i in new_indexes.size():
		var line : Line2D = _lines_order[i]
		new_Ys[i] = line.global_position.y + line.points[-1].y
	
	for i in new_indexes.size():
		var line : Line2D = _lines_order[new_indexes[i]]
		line.add_point(Vector2(
			_next_x,
			new_Ys[i] - line.global_position.y
		))
	
	_next_x += _horizontal_gap
	emit_signal("updated_all")

# override
func set_ui_visibility(is_visible : bool):
	_scroll.visible = is_visible

# override
func finish():
	# extend one last time
	for line in _lines_order:
		var last_point : Vector2 = line.points[-1]
		line.add_point(last_point + Vector2(_horizontal_gap, 0))
	
	_next_x += _horizontal_gap
	emit_signal("finished")

func _transform_local_point_from_node_to_node(node1 : Node2D, point : Vector2, node2 : Node2D):
	# points array of a Line2D contains points positions in relative space, making it quite painful to work with
	# since we have to convert a point to global space, then to local space of the second line that needs it
	return node1.global_position + point - node2.global_position

func _extend_all_lines(extend_to : float):
	for line in _lines_order:
		var last_point : Vector2 = line.points[-1]
		if last_point.x < extend_to:
			line.add_point(Vector2(extend_to, last_point.y))

func _on_scroll():
	if _next_x > Utility.viewport_size.x:
		_camera.global_position.x = lerp(0, _next_x - Utility.viewport_size.x, _scroll.value)
		update()
	
	# TODO: make scroll bar width dynamic, like in ScrollContainer
	# TODO: we should probably scroll along lines as they're expanding
	#       i.e always keep last point inside view
