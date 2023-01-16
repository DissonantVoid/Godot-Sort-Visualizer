extends Control

signal ok(data) # data : dictionary
signal cancel

onready var _error_panel : MarginContainer = $Error
onready var _error_txt : Label = $Error/Error/HBoxContainer/Label

const _fade_in_time : float = 0.08
const _max_fade_depth : int = 3 # fade in nodes as long as they're not this deep in tree
const _err_show_time : float = 0.3


func _ready():
	# recursively animate elements showing up
	var content_container : PanelContainer = $Content
	var tween : SceneTreeTween = get_tree().create_tween()
	yield(get_tree(),"idle_frame") # wait in case derived classes add nodes in _ready
	for child in content_container.get_children():
		_tween_children(child, tween, 0)

func _tween_children(node : CanvasItem, tween : SceneTreeTween, depth : int):
	if depth <= _max_fade_depth:
		for child in node.get_children():
			if child is CanvasItem:
				_tween_children(child, tween, depth+1)
		
		node.self_modulate.a = 0
		tween.tween_property(node, "self_modulate:a", 1.0, _fade_in_time)
	else:
		node.modulate.a = 0
		tween.tween_property(node, "modulate:a", 1.0, _fade_in_time)

func _on_background_gui_input(event):
	if event is InputEventMouseButton && event.pressed && event.button_index == BUTTON_LEFT:
		emit_signal("cancel")
		queue_free()

# override and do error checking
func _on_ok_pressed():
	emit_signal("ok", {})
	queue_free()

# override
func _on_cancel_pressed():
	emit_signal("cancel")
	queue_free()

func _on_close_error_pressed():
	_error_panel.hide()

func _error(text : String):
	if _error_panel.visible == false:
		var tween : SceneTreeTween = get_tree().create_tween()
		tween.tween_property(_error_panel, "modulate:a", 1.0, _err_show_time).from(0.0)
	
	_error_txt.text = "Error: " + text
	_error_panel.show()
