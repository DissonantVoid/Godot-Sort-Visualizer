extends TextureRect

signal moved

onready var _particles : CPUParticles2D = $CPUParticles2D

var _initial_size : Vector2
var _initial_particles_scale : float
var _pivot : Vector2
var _center : Vector2
var _rot_speed : float

const _move_to_speed : float = 92.0
var _move_target : Vector2

enum State {rotating, moving_to}
var _curr_state : int = State.rotating


func _ready():
	set_process(false)
	_initial_size = rect_size
	_initial_particles_scale = _particles.scale_amount
	_center = rect_size/2

func _process(delta):
	if _curr_state == State.rotating:
		_rotate(deg2rad(_rot_speed * delta))
	
	elif _curr_state == State.moving_to:
		var direction : Vector2 = (_move_target - rect_global_position).normalized()
		rect_global_position += _move_to_speed * direction * delta
		
		# if close enough, snap into position and call it a day
		if rect_global_position.distance_to(_move_target) <= _move_to_speed/2:
			rect_global_position = _move_target
			_curr_state = State.rotating
			_particles.emitting = false
			
			emit_signal("moved")

func setup(pivot : Vector2, start_position : Vector2):
	_pivot = pivot
	rect_global_position = start_position

func reset(size_scale : float, speed : float,
			start_angle : float, curr_zoom_modifier : float):
	# reset
	if _curr_state == State.moving_to:
		_curr_state = State.rotating
		_particles.emitting = false
	
	rect_size = _initial_size * size_scale / curr_zoom_modifier
	_center = rect_size/2
	
	_particles.position = _center
	_particles.scale_amount = _initial_particles_scale / curr_zoom_modifier
	
	_rot_speed = speed
	
	# manual rotation so we can easily switch planets
	_rotate(deg2rad(start_angle))
	
	set_process(true)

func move_to(new_pos : Vector2):
	_move_target = new_pos
	_curr_state = State.moving_to
	_particles.emitting = true

func get_size() -> Vector2:
	return rect_size

func modify_star_distance(modifier : float):
	var distance : Vector2 = rect_global_position + _center - _pivot
	rect_size *= modifier
	_center = rect_size/2
	rect_global_position = _pivot + (distance * modifier) - _center
	
	_particles.position = _center
	_particles.scale_amount *= modifier
	
	if _curr_state == State.moving_to:
		# recalculate _move_target
		distance = _move_target - _pivot
		_move_target = _pivot + (distance * modifier)

func _rotate(angle_rad : float):
	# credit: stackoverflow.com/questions/2259476/rotating-a-point-about-another-point-2d
	var pivot_centered : Vector2 = _pivot - _center
	
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
