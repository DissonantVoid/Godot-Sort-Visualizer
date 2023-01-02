extends "res://scenes/objects/visualizers/visualizer.gd"

onready var _planets_container : Control = $Planets
onready var _star : TextureRect = $Star

const _orbiting_planet_scene : PackedScene = preload("res://scenes/objects/ui_components/orbiting_planet.tscn")

var _rng : RandomNumberGenerator = RandomNumberGenerator.new()
var _star_center : Vector2
const _planets_count : int = 8
const _planets_offset : float = 98.0 # initial offset from the sun
const _planets_distance : float = 50.0

const _min_planet_scale : float = 0.1
const _max_planet_scale : float = 2.0
const _min_planet_speed : float = 4.0
const _max_planet_speed : float = 36.0

var _waiting_for_planets : int = 0
var _is_updating_all : bool = false

func _ready():
	_rng.randomize()
	
	# removing this line will cause _star_center to be 0,0 at start
	# but only if visualizer_planets is not the root node
	# not sure why but I suspect it has something to do with layout
	# not applying untill root control is ready?
	yield(get_tree().root, "ready")
	_star_center = _star.rect_global_position + _star.rect_size/2
	
	for i in _planets_count:
		var planet := _orbiting_planet_scene.instance()
		planet.rect_global_position = _star_center - Vector2(_planets_offset + (_planets_distance * i), 0)
		planet.connect("moved", self, "_on_planet_moved")
		_planets_container.add_child(planet)

func _on_planet_moved():
	_waiting_for_planets -= 1
	if _waiting_for_planets == 0:
		if _is_updating_all:
			emit_signal("updated_all")
		else:
			emit_signal("updated_indexes")

# override
func reset():
	for i in _planets_count:
		var planet := _planets_container.get_child(i)
		planet.setup(
			_star_center, _rng.randf_range(_min_planet_scale, _max_planet_scale),
			_rng.randf_range(_min_planet_speed, _max_planet_speed), _rng.randf_range(0, 360)
		)

# override
func get_content_count() -> int:
	return _planets_count

# override
func determine_priority(idx1 : int, idx2 : int) -> bool:
	return _planets_container.get_child(idx1).get_size() >\
			_planets_container.get_child(idx2).get_size()

# override
func update_indexes(idx1 : int, idx2 : int):
	var low_idx_child := _planets_container.get_child(min(idx1, idx2))
	var high_idx : int = max(idx1, idx2)
	var high_idx_child := _planets_container.get_child(high_idx)
	
	_planets_container.move_child(high_idx_child, low_idx_child.get_index())
	_planets_container.move_child(low_idx_child, high_idx)
	
	low_idx_child.move_to(high_idx_child.rect_global_position)
	high_idx_child.move_to(low_idx_child.rect_global_position)
	_waiting_for_planets = 2

# override
func update_all(new_indexes : Array):
	# TODO: order is not right
	_is_updating_all = true
	for i in new_indexes:
		if i != new_indexes[i]:
			_waiting_for_planets += 1
			_planets_container.get_child(i).move_to(
				_planets_container.get_child(new_indexes[i]).rect_global_position
			)

# override
func finish():
	pass
