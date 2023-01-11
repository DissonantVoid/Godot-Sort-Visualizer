extends CanvasLayer

# TODO: change name, this does more than pick an algorithm,

signal algorithm_changed(new_algorithn)
signal options_changed(data) # data : dictionary
signal button_pressed(button)
signal ui_visibility_changed(is_visible)

onready var _root_child : MarginContainer = $MarginContainer
onready var _content_container : PanelContainer = $MarginContainer/VBoxContainer/Content
onready var _selected_algo_btn : Button = $MarginContainer/VBoxContainer/Content/MarginContainer/HBoxContainer/Center/Algorithm
onready var _idle_buttons : HBoxContainer = $MarginContainer/VBoxContainer/Content/MarginContainer/HBoxContainer/Center/Idle
onready var _running_buttons : HBoxContainer = $MarginContainer/VBoxContainer/Content/MarginContainer/HBoxContainer/Center/Running
onready var _paused_buttons : HBoxContainer = $MarginContainer/VBoxContainer/Content/MarginContainer/HBoxContainer/Center/Paused
onready var _restart_buttons : HBoxContainer = $MarginContainer/VBoxContainer/Content/MarginContainer/HBoxContainer/Center/Restart

const _options_popup_scene : PackedScene = preload("res://scenes/objects/ui_components/popups/algo_picker_options_popup.tscn")
const _algorithms_popup_scene : PackedScene = preload("res://scenes/objects/ui_components/popups/algo_picker_algorithms_popup.tscn")

const _moving_time : float = 0.85
var _is_moving : bool = false
var _is_hidden : bool = false

var _data_to_sort : Array
var _sort_callback : FuncRef


func sorter_finished():
	_toggle_button_group(_restart_buttons)

func set_can_continue(can_continue : bool):
	for child in _paused_buttons.get_children():
		if child is Button: child.disabled = !can_continue
	
	for child in _restart_buttons.get_children():
		if child is Button: child.disabled = !can_continue

func show_options_popup(options : Dictionary):
	var instance := _options_popup_scene.instance()
	instance.connect("ok", self, "_on_options_popup_ok")
	add_child(instance)
	instance.setup(options)

func _on_title_pressed():
		var instance := _algorithms_popup_scene.instance()
		add_child(instance)
		instance.connect("ok", self, "_on_algorithms_popup_ok")

func _on_button_clicked(button : String):
	match button:
		"options":
			emit_signal("button_pressed", button)
		"hide":
			if _is_moving: return
			_is_moving = true
			emit_signal("ui_visibility_changed", false)
			
			var tween : SceneTreeTween = get_tree().create_tween()
			tween.tween_property(_root_child, "rect_position:y", -_content_container.rect_size.y, _moving_time)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
			yield(tween, "finished")
			_is_hidden = true
			_is_moving = false
		
		"start":
			_toggle_button_group(_running_buttons)
			emit_signal("button_pressed", button)
		"next":
			if _idle_buttons.visible:
				_toggle_button_group(_paused_buttons)
			emit_signal("button_pressed", button)
		"pause":
			_toggle_button_group(_paused_buttons)
			emit_signal("button_pressed", button)
		"stop":
			_toggle_button_group(_idle_buttons)
			emit_signal("button_pressed", button)
		"continue":
			_toggle_button_group(_running_buttons)
			emit_signal("button_pressed", button)
		"last":
			_toggle_button_group(_restart_buttons)
			emit_signal("button_pressed", button)
		"restart":
			_toggle_button_group(_idle_buttons)
			emit_signal("button_pressed", button)

func _on_algorithms_popup_ok(data : Dictionary):
	emit_signal("algorithm_changed", load(data["path"]).new())
	
	_selected_algo_btn.text = data["name"]
	_toggle_button_group(_idle_buttons)
	
	for child in _idle_buttons.get_children():
		if child is Button: child.disabled = false

func _on_options_popup_ok(data : Dictionary):
	emit_signal("options_changed", data)

# after hiding this object, hover mouse near the very top of the screen to bring it back
func _on_grabber_mouse_entered():
	if _is_hidden && _is_moving == false:
		_is_moving = true
		emit_signal("ui_visibility_changed", true)
		
		var tween : SceneTreeTween = get_tree().create_tween()
		tween.tween_property(_root_child, "rect_position:y", 0.0, _moving_time)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		
		yield(tween, "finished")
		_is_moving = false
		_is_hidden = false

func _toggle_button_group(group : HBoxContainer):
	_idle_buttons.visible = (group == _idle_buttons)
	_running_buttons.visible = (group == _running_buttons)
	_paused_buttons.visible = (group == _paused_buttons)
	_restart_buttons.visible = (group == _restart_buttons)
