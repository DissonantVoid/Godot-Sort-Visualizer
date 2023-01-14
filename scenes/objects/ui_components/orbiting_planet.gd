extends TextureRect

signal moved

onready var _trail : Line2D = $Trail

const _default_line_width : float = 8.7
const _max_trail_segments : int = 12
const _next_trail_time : float = 0.07
var _next_trail_timer : float

var _initial_size : Vector2
var _pivot : Vector2
var _local_center : Vector2
var _orbit_speed : float

const _move_to_speed : float = 0.6
var _move_start : Vector2
var _move_end : Vector2

const _arc_height : float = 124.0
var _arc_point : Vector2
var _curr_arc_offset : float = 0 # [0 - 1]

enum State {rotating, moving_to}
var _curr_state : int = State.rotating


func _ready():
	# this is a bit hacky and has its problems
	# but I think it's the best we can do
	_trail.set_as_toplevel(true)
	
	# randomize texture
	var tex_offsets : Array = [0, 32]
	texture.region.position.x = tex_offsets[
		Utility.rng.randi_range(0, tex_offsets.size()-1)
	]
	texture.region.position.y = tex_offsets[
		Utility.rng.randi_range(0, tex_offsets.size()-1)
	]
	flip_h = bool(Utility.rng.randi_range(0,1))
	flip_v = bool(Utility.rng.randi_range(0,1))
	
	set_process(false)
	_initial_size = rect_size
	_local_center = rect_size/2

func _process(delta):
	if _curr_state == State.rotating:
		_rotate(deg2rad(_orbit_speed * delta))
	
	elif _curr_state == State.moving_to:
		# we use quadratic bezier curve (see docs.godotengine.org/en/stable/tutorials/math/beziers_and_curves.html)
		# p0 is our pos
		# p1 is half distance between p0 and p1 raised by _arc_height
		# p2 is target pos
		
		var q0 : Vector2 = _move_start.linear_interpolate(_arc_point, _curr_arc_offset)
		var q1 : Vector2 = _arc_point.linear_interpolate(_move_end, _curr_arc_offset)
		var pos : Vector2 = q0.linear_interpolate(q1, _curr_arc_offset)
		rect_global_position = pos
		
		_next_trail_timer -= delta
		if _next_trail_timer <= 0:
			_next_trail_timer = _next_trail_time
			_trail.add_point(get_center())
			if _trail.points.size() > _max_trail_segments:
				_trail.remove_point(0)
		
		_curr_arc_offset += _move_to_speed * delta
		if _curr_arc_offset > 1.0:
			_curr_state = State.rotating
			_trail.clear_points()
			
			emit_signal("moved")

func setup(pivot : Vector2, start_position : Vector2):
	_pivot = pivot
	rect_global_position = start_position

func reset(size_scale : float, orbit_speed : float, start_angle : float):
	# reset
	if _curr_state == State.moving_to:
		_curr_state = State.rotating
		_trail.clear_points()
		_next_trail_timer = 0
	
	rect_size = _initial_size * size_scale
	_local_center = rect_size/2
	_trail.width = _default_line_width  * size_scale
	_orbit_speed = orbit_speed
	
	# manual rotation so we can easily switch planets
	_rotate(deg2rad(start_angle))
	
	set_process(true)

func move_to(other_planet):
	_move_start = get_center()
	_move_end = other_planet.get_center() - rect_size/2 # move our center to the new position
	
	var distance : Vector2 = _move_end - _move_start
	_arc_point = (_move_start + distance/2) + Vector2(0, _arc_height).rotated(distance.normalized().angle())
	
	_curr_arc_offset = 0
	_orbit_speed = other_planet.get_orbit_speed()
	_curr_state = State.moving_to
	
	_next_trail_timer = _next_trail_time

func get_orbit_speed() -> float:
	return _orbit_speed

func get_size() -> Vector2:
	return rect_size

func get_center() -> Vector2:
	return rect_global_position + rect_size/2

func _rotate(angle_rad : float):
	# credit: stackoverflow.com/questions/2259476/rotating-a-point-about-another-point-2d
	var pivot_centered : Vector2 = _pivot - _local_center
	
	var angle_sin : float = sin(angle_rad)
	var angle_cos : float = cos(angle_rad)
	
	# translate point back to pivot:
	rect_global_position -= pivot_centered
	
	# rotate point
	var x_new : float = rect_global_position.x * angle_cos -\
				rect_global_position.y * angle_sin;
	var y_new : float = rect_global_position.x * angle_sin +\
				rect_global_position.y * angle_cos;
	
	# translate point back:
	rect_global_position = Vector2(x_new + pivot_centered.x, y_new + pivot_centered.y);
