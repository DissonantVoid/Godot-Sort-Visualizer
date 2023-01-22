extends TextureRect

signal disappeared

onready var _line : Line2D = $Line2D

const _move_time : float = 0.5
var _index : int
var _is_brocken : bool


func setup(is_brocken : bool, color : Color, index : int):
	if is_brocken:
		texture.region.position.x = texture.region.size.x
	else:
		_line.material.set_shader_param(
			"offset", Utility.rng.randf_range(0.1, 0.4)
		)
		_line.default_color = color
		_line.show()
	
	_is_brocken = is_brocken
	_index = index
	self_modulate = color

func get_order_index() -> int:
	return _index

func disappear():
	_line.hide()
	
	var tween : SceneTreeTween = get_tree().create_tween()
	tween.tween_property(self, "rect_position:y", rect_size.y, _move_time)
	
	yield(tween, "finished")
	emit_signal("disappeared")

func appear():
	var tween : SceneTreeTween = get_tree().create_tween()
	tween.tween_property(self, "rect_position:y", 0.0, _move_time).from(rect_size.y)
	
	yield(tween, "finished")
	if _is_brocken == false:
		_line.show()
