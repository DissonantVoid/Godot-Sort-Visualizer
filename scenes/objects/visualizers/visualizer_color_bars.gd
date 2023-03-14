extends "res://scenes/objects/visualizers/visualizer.gd"

onready var _lines_container : Control = $Lines
onready var _camera : Camera2D = $Camera2D
onready var _scroll : HScrollBar = $CanvasLayer/HScrollBar
onready var _scroll_graber_box : StyleBox = _scroll.get_stylebox("grabber")
onready var _scroll_graber_hover_box : StyleBox = _scroll.get_stylebox("grabber_highlight")

const _min_height : float = 100.0
const _max_height : float = 520.0
const _horizontal_gap : float = 45.0
const _lines_count : int = 20
const _line_width : float = 6.8
const _line_tween_time : float = 0.06

const _ruler_big_line_width : float = 2.2
const _ruler_small_line_width : float = 0.6
const _ruler_small_lines_count : int = 3
const _ruler_color : Color = Color("32ffeecc")

const _gradient_colors : Array = [Color("ffeecc"), Color("ff6973"), Color.black]

var _active_tweens : Array
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


func _ready():
	_lines_order.resize(_lines_count)
	var v_gap : float = (_max_height - _min_height) / _lines_count
	for i in _lines_count:
		var line : Line2D = Line2D.new()
		line.default_color = Utility.lerp_color_arr(_gradient_colors, float(i) / _lines_count, false)
		line.width = _line_width
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		
		_lines_container.add_child(line)
		var y_pos : float = _min_height + v_gap * i
		line.global_position = Vector2(0, y_pos)
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
		"title":"COLOR_TITLE", "image":"color_bars.png",
		"description":"COLOR_DESC"
	}

# override
func reset():
	for i in range(_active_tweens.size()-1, -1, -1):
		_active_tweens[i].kill()
		_active_tweens.remove(i)
	
	# clear points
	for line in _lines_order:
		line.clear_points()
		# keep first 2 points
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
	
	_scroll.value = _scroll.max_value
	_camera.global_position.x = 0
	_resize_scroll_grabber()
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
	match action:
		Sorter.SortAction.switch:
			var line1 : Line2D = _lines_order[idx1]
			var line2 : Line2D = _lines_order[idx2]
			var line1_last_p_as_line2_local : Vector2 =\
				_transform_local_point_from_node_to_node(line1, line1.points[-1], line2)
			var line2_last_p_as_line1_local : Vector2 =\
				_transform_local_point_from_node_to_node(line2, line2.points[-1], line1)
			
			# extend both lines towards each other's position
			var tween : SceneTreeTween = _make_tweener().set_parallel(true)
			_add_point_and_tween_it(
				tween, line1, Vector2(_next_x, line2_last_p_as_line1_local.y)
			)
			_add_point_and_tween_it(
				tween, line2, Vector2(_next_x, line1_last_p_as_line2_local.y)
			)
			
			Utility.swap_elements(_lines_order, idx1, idx2)
			yield(tween, "finished")
		
		Sorter.SortAction.move:
			var tween : SceneTreeTween = _make_tweener().set_parallel(true)
			if idx1 > idx2:
				# move line at idx1 above line at idx2
				# and shift lines in between down
				var idx2_old_pos : Vector2 = _lines_order[idx2].points[-1]
				for i in range(idx2, idx1):
					var other_line : Line2D = _lines_order[i+1]
					_add_point_and_tween_it(tween, _lines_order[i], Vector2(
							_next_x,
							_transform_local_point_from_node_to_node(
								other_line, other_line.points[-1], _lines_order[i]
							).y
					))
				_add_point_and_tween_it(tween, _lines_order[idx1], Vector2(
						_next_x,
						_transform_local_point_from_node_to_node(
							_lines_order[idx2], idx2_old_pos, _lines_order[idx1]
						).y
				))
			
			elif idx1 < idx2:
				# move line at idx1 above line at idx2
				# and shift lines in between up
				var idx2_old_pos : Vector2 = _lines_order[idx2].points[-1]
				for i in range(idx2, idx1, -1):
					var other_line : Line2D = _lines_order[i-1]
					_add_point_and_tween_it(tween, _lines_order[i], Vector2(
							_next_x,
							_transform_local_point_from_node_to_node(
								other_line, other_line.points[-1], _lines_order[i]
							).y
					))
				_add_point_and_tween_it(tween, _lines_order[idx1], Vector2(
						_next_x,
						_transform_local_point_from_node_to_node(
							_lines_order[idx2], idx2_old_pos, _lines_order[idx1]
						).y
				))
			
			yield(tween, "finished")
			Utility.move_element(_lines_order, idx1, idx2)
	
	yield(_extend_all_lines(_next_x), "completed")
	_next_x += _horizontal_gap
	_resize_scroll_grabber()
	emit_signal("updated_indexes")

# override
func update_all(new_indexes : Array):
	var new_Ys : Array # each entry represents the y of a to-be-added point to _lines_order[i]
	new_Ys.resize(new_indexes.size())
	for i in new_indexes.size():
		var line : Line2D = _lines_order[i]
		new_Ys[i] = line.global_position.y + line.points[-1].y
	
	# extend lines 4 times more than usual so it's not all cluttered in one small space
	_next_x += (_horizontal_gap * 4)
	
	var tween : SceneTreeTween = _make_tweener().set_parallel(true)
	for i in new_indexes.size():
		var line : Line2D = _lines_order[new_indexes[i]]
		_add_point_and_tween_it(
			tween, line, Vector2(_next_x, new_Ys[i] - line.global_position.y)
		)
	yield(tween, "finished")
	
	_next_x += _horizontal_gap
	_resize_scroll_grabber()
	emit_signal("updated_all")

# override
func set_ui_visibility(is_visible : bool):
	_scroll.visible = is_visible

# override
func finish():
	# extend one last time
	yield(_extend_all_lines(_next_x), "completed")
	_next_x += _horizontal_gap
	
	_resize_scroll_grabber()
	emit_signal("finished")

func _transform_local_point_from_node_to_node(node1 : Node2D, point : Vector2, node2 : Node2D):
	# points array of a Line2D contain points positions in relative space, making it quite painful to work with
	# since we have to convert a point to global space, then to local space of the second line that needs it
	return node1.global_position + point - node2.global_position

func _extend_all_lines(extend_to : float):
	var tween : SceneTreeTween = _make_tweener().set_parallel(true)
	for line in _lines_order:
		var last_point : Vector2 = line.points[-1]
		if last_point.x < extend_to:
			_add_point_and_tween_it(tween, line, Vector2(extend_to, last_point.y))
	
	yield(tween, "finished")

func _make_tweener() -> SceneTreeTween:
	# remove inactive tweens
	for i in range(_active_tweens.size()-1, -1, -1):
		if _active_tweens[i].is_valid() == false:
			_active_tweens.remove(i)
	
	var tween : SceneTreeTween = get_tree().create_tween()
	_active_tweens.append(tween)
	return tween

func _add_point_and_tween_it(tween : SceneTreeTween, line : Line2D, point : Vector2):
	var prev_point : Vector2 = line.points[-1]
	line.add_point(prev_point)
	tween.tween_method(self, "_line_point_tween_callback", prev_point, point, _line_tween_time, [line])

func _line_point_tween_callback(position : Vector2, line : Line2D):
	line.points[-1] = position

func _on_scroll():
	if _next_x > Utility.viewport_size.x:
		_camera.global_position.x = lerp(0, _next_x - Utility.viewport_size.x, _scroll.value)
		update()

func _resize_scroll_grabber():
	# if the scroll bar was scrolled to the end, move along new points
	# this is similar to a Twitch chat for example, everytime a new chat appears
	# the bar will auto-scroll to follow it as long as it was previously scrolled
	# all the way down
	var auto_scroll_to_end : bool = (_scroll.value == _scroll.max_value)
	
	# resize grabber
	var new_width : float
	var ratio : float = _next_x / Utility.viewport_size.x
	if ratio <= 1:
		new_width = _scroll.rect_size.x
	else:
		new_width = range_lerp(
			Utility.viewport_size.x, 0, _next_x, 0, _scroll.rect_size.x
		)
	
	_scroll_graber_box.border_width_left = new_width / 2
	_scroll_graber_box.border_width_right = new_width / 2
	_scroll_graber_hover_box.border_width_left = new_width / 2
	_scroll_graber_hover_box.border_width_right = new_width / 2
	
	if auto_scroll_to_end:
		_on_scroll()


func is_enabled() -> bool:
	return true