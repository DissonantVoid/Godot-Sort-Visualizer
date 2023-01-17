extends "res://scenes/objects/visualizers/visualizer.gd"

onready var _planets_container : Control = $Planets
onready var _star : TextureRect = $Star
onready var _camera : Camera2D = $Camera2D
onready var _background : ColorRect = $Camera2D/Background

onready var _zoom_in_btn : Button = $CanvasLayer/Zoom/HBoxContainer/In
onready var _zoom_out_btn : Button = $CanvasLayer/Zoom/HBoxContainer/Out

const _orbiting_planet_scene : PackedScene = preload("res://scenes/objects/components/orbiting_planet.tscn")

var _window_size : Vector2 = Vector2(
	ProjectSettings.get_setting("display/window/size/width"),
	ProjectSettings.get_setting("display/window/size/height")
)

var _star_center : Vector2
const _planets_count : int = 10
const _planets_offset : float = 140.0 # initial offset from the sun
const _planets_distance : float = 80.0

const _min_planet_scale : float = 0.4
const _max_planet_scale : float = 2.8
const _planets_speed_modifier : float = 0.2
# used to determine planets orbit speed
var _furthest_planet_distance : float =\
	Vector2(_planets_offset + _planets_count * _planets_distance, 0).length()

var _waiting_for_planets : int = 0
var _is_updating_all : bool = false

var _zoom_level : int = 1
const _zoom_min : int = 0
const _zoom_max : int = 3


func _ready():
	_background.rect_size = _window_size * 2
	_background.rect_position = -_background.rect_size/2
	
	# removing the yield will cause _star_center to be 0,0 at start
	# but only if visualizer_planets is not the root node
	# not sure why but I suspect it has something to do with layout
	# not applying untill root control is ready?
	yield(get_tree().root, "ready")
	_star.rect_pivot_offset = _star.rect_size/2
	_star_center = _star.rect_global_position + _star.rect_size/2
	
	for i in _planets_count:
		var planet := _orbiting_planet_scene.instance()
		planet.connect("moved", self, "_on_planet_moved")
		_planets_container.add_child(planet)
		planet.setup(_star_center, 
			_star_center - Vector2(
				_planets_offset + (_planets_distance * i), planet.rect_size.y/2)
			)

# override
func reset():
	for i in _planets_count:
		var planet := _planets_container.get_child(i)
		
		planet.reset(
			Utility.rng.randf_range(_min_planet_scale, _max_planet_scale),
			_planets_speed_modifier * 
				(_furthest_planet_distance - (planet.rect_global_position - _star_center).length()),
			Utility.rng.randf_range(0, 360)
		)

# override
func get_content_count() -> int:
	return _planets_count

# override
func determine_priority(idx1 : int, idx2 : int) -> bool:
	return _planets_container.get_child(idx1).get_size() >\
			_planets_container.get_child(idx2).get_size()

# override
func update_indexes(action : int, idx1 : int, idx2 : int):
	match action:
		Sorter.SortAction.switch:
			var child1 := _planets_container.get_child(idx1)
			var child2 := _planets_container.get_child(idx2)
			child1.move_to(child2)
			child2.move_to(child1)
			
			Utility.switch_children(_planets_container, idx1, idx2)
		
		Sorter.SortAction.move:
			# TODO after implementing merge or quick sort
			pass
	
	_waiting_for_planets = 2

# override
func update_all(new_indexes : Array):
	_is_updating_all = true
	
	var ordered_planets : Array
	for i in new_indexes:
		ordered_planets.append(_planets_container.get_child(i))
	
	# switch planets
	for i in new_indexes.size():
		if i != new_indexes[i]:
			_waiting_for_planets += 1
			var target_child := _planets_container.get_child(i)
			_planets_container.get_child(new_indexes[i]).move_to(target_child)
	
	# no point in moving children in tree since reset() will be called after this anyway

# override
func set_ui_visibility(is_visible : bool):
	_zoom_in_btn.visible = is_visible
	_zoom_out_btn.visible = is_visible

# override
func finish():
	emit_signal("finished")

func _on_planet_moved():
	_waiting_for_planets -= 1
	if _waiting_for_planets == 0:
		if _is_updating_all:
			_is_updating_all = false
			emit_signal("updated_all")
		else:
			emit_signal("updated_indexes")

func _on_zoom_pressed(is_in : bool):
	_zoom_level += -1 if is_in else 1
	
	var zoom_modifier : int = pow(2, _zoom_level)
	_camera.zoom = Vector2.ONE * zoom_modifier
	_background.rect_size = _window_size * zoom_modifier
	_background.rect_position = -_background.rect_size/2
	
	_zoom_out_btn.disabled = _zoom_level == _zoom_max
	_zoom_in_btn.disabled = _zoom_level == _zoom_min
