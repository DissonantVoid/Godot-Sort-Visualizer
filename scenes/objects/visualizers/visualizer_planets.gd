extends "res://scenes/objects/visualizers/visualizer.gd"

# TODO: this is still brocken, mess arround long enough (not that long)
#       and things will start to break, planets will not switch places
#       order will be all wrong, I don't even know man
#       most of these issues can be fixed by using a camera to zoom
#       with a background that follows and scales with the camera,
#       instead of all this smart-assing

# TODO: this needs some more attention like planet speed changing
#       based on zoom level, rotation speed based on distance from star
#       diffrent planet art etc..
#       of course that's future me's problem and I'm not future me

onready var _planets_container : Control = $Planets
onready var _star : TextureRect = $Star

onready var _zoom_in_btn : Button = $Zoom/HBoxContainer/In
onready var _zoom_out_btn : Button = $Zoom/HBoxContainer/Out

const _orbiting_planet_scene : PackedScene = preload("res://scenes/objects/ui_components/orbiting_planet.tscn")

var _rng : RandomNumberGenerator = RandomNumberGenerator.new()
var _star_center : Vector2
const _planets_count : int = 8
const _planets_offset : float = 98.0 # initial offset from the sun
const _planets_distance : float = 70.0

const _min_planet_scale : float = 0.4
const _max_planet_scale : float = 2.1
const _min_planet_speed : float = 4.0
const _max_planet_speed : float = 36.0

var _waiting_for_planets : int = 0
var _is_updating_all : bool = false

var _zoom_level : int = 4
const _zoom_max : int = 4
const _zoom_min : int = 1


func _ready():
	_rng.randomize()
	
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
		
		var zoom_modifier : float
		match _zoom_level: # is this a stupid way to do this?
			4: zoom_modifier = 1
			3: zoom_modifier = 2
			2: zoom_modifier = 4
			1: zoom_modifier = 6
		
		planet.reset(
			_rng.randf_range(_min_planet_scale, _max_planet_scale),
			_rng.randf_range(_min_planet_speed, _max_planet_speed), _rng.randf_range(0, 360),
			zoom_modifier
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
	
	low_idx_child.move_to(high_idx_child.rect_global_position + high_idx_child.rect_size/2)
	high_idx_child.move_to(low_idx_child.rect_global_position + low_idx_child.rect_size/2)
	_waiting_for_planets = 2

# override
func update_all(new_indexes : Array):
	# TODO: order is not right
	_is_updating_all = true
	for i in new_indexes.size():
		if i != new_indexes[i]:
			_waiting_for_planets += 1
			var target_child : Control = _planets_container.get_child(new_indexes[i])
			_planets_container.get_child(i).move_to(target_child.rect_global_position + target_child.rect_size/2)

# override
func set_ui_visibility(is_visible : bool):
	_zoom_in_btn.visible = is_visible
	_zoom_out_btn.visible = is_visible

# override
func finish():
	pass

func _on_planet_moved():
	_waiting_for_planets -= 1
	if _waiting_for_planets == 0:
		if _is_updating_all:
			emit_signal("updated_all")
		else:
			emit_signal("updated_indexes")

func _on_zoom_pressed(is_in : bool):
	_zoom_level += 1 if is_in else -1
	var modifier_value : float = 2.0 if is_in else 0.5
	
	_star.rect_scale *= modifier_value
	_star.rect_pivot_offset = _star.rect_size/2
	for planet in _planets_container.get_children():
		# shrink distance to star
		planet.modify_star_distance(modifier_value)
	
	if _zoom_out_btn.disabled:
		_zoom_out_btn.disabled = false
	elif _zoom_level == _zoom_min:
		_zoom_out_btn.disabled = true
	
	if _zoom_in_btn.disabled:
		_zoom_in_btn.disabled = false
	elif _zoom_level == _zoom_max:
		_zoom_in_btn.disabled = true
