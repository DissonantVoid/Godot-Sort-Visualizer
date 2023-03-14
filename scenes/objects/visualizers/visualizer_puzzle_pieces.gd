extends "res://scenes/objects/visualizers/visualizer.gd"

onready var _board : TextureRect = $MarginContainer/MarginContainer/Board
onready var _pieces_container : GridContainer = $MarginContainer/MarginContainer/Pieces
onready var _margin : MarginContainer = $MarginContainer/MarginContainer

const _piece_size : int = 32 # can also be 16, 64 etc..
var _order : Array # idx : piece,   idx 0 is top left piece, idx size-1 is bottom right piece

const _switch_all_tween_time : float = 0.8
const _pieces_scale_factor : float = 0.8 # scale down to make space for the interface


func _ready():
	_board.hide()
	var board_size : Vector2 = _board.texture.get_size()
	_pieces_container.columns = board_size.x/_piece_size
	
	# split board image into pieces
	for x in board_size.x/_piece_size:
		for y in board_size.y/_piece_size:
			var tex_rect : TextureRect = TextureRect.new()
			var texture : ImageTexture = ImageTexture.new()
			var image : Image = Image.new()
			# BUG?? for some reason FORMAT_RGBA8 only works if the png image has at least
			# one transparent pixel, otherwise we have to use FORMAT_RGB8
			# is this a godot issue or png specification issue?
			image.create(_piece_size, _piece_size, false, Image.FORMAT_RGB8)
			image.blit_rect(
				_board.texture.get_data(), Rect2(
					# NOTE: y first or the grid will be rotated
					y * _piece_size, x * _piece_size, _piece_size, _piece_size
				), Vector2.ZERO
			)
			texture.create_from_image(image, 0)
			tex_rect.texture = texture
			tex_rect.expand = true
			tex_rect.rect_min_size = Vector2.ONE * _piece_size * _pieces_scale_factor 
			
			_order.append(tex_rect)
			_pieces_container.add_child(tex_rect)

# override
static func get_metadata() -> Dictionary:
	return {
		"title":"PUZZLE_TITLE", "image":"puzzle_pieces.png",
		"description":"PUZZLE_DESC"
	}

# override
func reset():
	_pieces_container.add_constant_override("hseparation", 2)
	_pieces_container.add_constant_override("vseparation", 2)
	
	# shuffle pieces
	for i in _pieces_container.get_child_count():
		_pieces_container.move_child(
			_pieces_container.get_child(i), Utility.rng.randi_range(0, _pieces_container.get_child_count()-1)
		)

# override
func get_content_count() -> int:
	return _pieces_container.get_child_count()

# override
func determine_priority(idx1 : int, idx2 : int) -> bool:
	return _order.find(_pieces_container.get_child(idx1)) >\
			_order.find(_pieces_container.get_child(idx2))

# override
func update_indexes(action : int, idx1 : int, idx2 : int):
	match action:
		Sorter.SortAction.switch:
			Utility.switch_children(_pieces_container, idx1, idx2)
		Sorter.SortAction.move:
			_pieces_container.move_child(_pieces_container.get_child(idx1), idx2)
	
	emit_signal("updated_indexes")

# override
func update_all(new_indexes : Array):
	var ordered_pieces : Array
	for i in new_indexes:
		ordered_pieces.append(_pieces_container.get_child(i))
	
	# tween each child to its new position before removing children from tree
	# so that once we add them back they continue to tween, giving the illusion that they're
	# being sorted
	var tween : SceneTreeTween = get_tree().create_tween()
	tween.connect("finished", self, "_on_switch_all_tween_finished")
	for i in new_indexes.size():
		var first_child : TextureRect = _pieces_container.get_child(new_indexes[i])
		var second_child : TextureRect = _pieces_container.get_child(i)
		tween.tween_property(
			first_child, "rect_position", second_child.rect_position, _switch_all_tween_time
		).from(first_child.rect_position)
		tween.parallel()
	
	for i in range(_pieces_container.get_child_count()-1, -1, -1):
		_pieces_container.remove_child(_pieces_container.get_child(i))
	
	for piece in ordered_pieces:
		_pieces_container.add_child(piece) 

# override
func set_ui_visibility(is_visible : bool):
	return

# override
func finish():
	_pieces_container.add_constant_override("hseparation", 0)
	_pieces_container.add_constant_override("vseparation", 0)
	emit_signal("finished")

func _on_switch_all_tween_finished():
	emit_signal("updated_all")


func is_enabled() -> bool:
	return true
