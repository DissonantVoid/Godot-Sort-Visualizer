extends TextureRect

signal moved

onready var _particles : CPUParticles2D = $CPUParticles2D

var _pivot : Vector2
var _initial_size : Vector2
var _size_scale : float
var _rot_speed : float

const _move_to_speed : float = 92.0
var _move_target : Vector2

enum State {rotating, moving_to}
var _curr_state : int = State.rotating


func _ready():
	set_process(false)
	_initial_size = rect_min_size

func _process(delta):
	if _curr_state == State.rotating:
		_rotate(fmod(_rot_speed * delta, 360.0))
	
	elif _curr_state == State.moving_to:
		var direction : Vector2 = (_move_target - rect_global_position).normalized()
		rect_global_position += _move_to_speed * direction * delta
		
		# if close enough, snap into position and call it a day
		if rect_global_position.distance_to(_move_target) <= _move_to_speed/2:
			rect_global_position = _move_target
			_curr_state = State.rotating
			_particles.emitting = false
			
			emit_signal("moved")

func setup(pivot : Vector2, size_scale : float,
			speed : float, start_angle : float):
	# reset
	if _curr_state == State.moving_to:
		_curr_state = State.rotating
		_particles.emitting = false
	
	_size_scale = size_scale
	rect_min_size = _initial_size * size_scale
	
	_pivot = pivot
	_rot_speed = speed
	
	_particles.position = rect_min_size/2
	
	# manual rotation so we can easily switch planets
	_rotate(start_angle)
	
	set_process(true)

func move_to(new_pos : Vector2):
	_move_target = new_pos
	_curr_state = State.moving_to
	_particles.emitting = true

func get_size():
	return _size_scale

func _rotate(angle_deg : float):
	# credit: stackoverflow.com/questions/2259476/rotating-a-point-about-another-point-2d
	var angle_sin = sin(deg2rad(angle_deg))
	var angle_cos = cos(deg2rad(angle_deg))
	
	# translate point back to origin:
	rect_global_position.x -= _pivot.x;
	rect_global_position.y -= _pivot.y;
	
	# rotate point
	var x_new = rect_global_position.x * angle_cos -\
				rect_global_position.y * angle_sin;
	var y_new = rect_global_position.x * angle_sin +\
				rect_global_position.y * angle_cos;
	
	# translate point back:
	rect_global_position.x = x_new + _pivot.x;
	rect_global_position.y = y_new + _pivot.y;
