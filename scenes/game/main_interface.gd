extends CanvasLayer

signal sorter_changed(new_sorter)
signal visualizer_changed(new_visualizer)
signal options_changed(data) # data : dictionary
signal button_pressed(button)
signal ui_visibility_changed(is_visible)

onready var _root_child : MarginContainer = $MarginContainer
onready var _content_container : VBoxContainer = $MarginContainer/VBoxContainer/Content
onready var _selected_sorter_btn : Button = $MarginContainer/VBoxContainer/Content/Upper/MarginContainer/HBoxContainer/Center/HBoxContainer/Sorter
onready var _idle_buttons : HBoxContainer = $MarginContainer/VBoxContainer/Content/Lower/Lower/MarginContainer/VBoxContainer/Idle
onready var _running_buttons : HBoxContainer = $MarginContainer/VBoxContainer/Content/Lower/Lower/MarginContainer/VBoxContainer/Running
onready var _paused_buttons : HBoxContainer = $MarginContainer/VBoxContainer/Content/Lower/Lower/MarginContainer/VBoxContainer/Paused
onready var _restart_buttons : HBoxContainer = $MarginContainer/VBoxContainer/Content/Lower/Lower/MarginContainer/VBoxContainer/Restart

onready var _selected_visualizer_btn : Button = $MarginContainer/VBoxContainer/Content/Upper/MarginContainer/HBoxContainer/Center/HBoxContainer/Visualizer

onready var _grabber : ColorRect = $MarginContainer/VBoxContainer/Grabber

const _options_popup_scene : PackedScene = preload("res://scenes/objects/components/popups/popup_main_interface_options.tscn")
const _sorter_popup_scene : PackedScene = preload("res://scenes/objects/components/popups/popup_main_interface_algorithms.tscn")
const _visualizer_popup_scene : PackedScene = preload("res://scenes/objects/components/popups/popup_main_interface_visualizers.tscn")

var _visualizer_control_buttons : Array # cache for set_ui_active()
const _moving_time : float = 0.85
var _is_moving : bool = false
var _is_hidden : bool = false


# TODO: add keyboard shortcuts

func _ready():
	# NOTE: _running_buttons are not included, because we want to allow
	# user to pause a running visualizer
	for child in _idle_buttons.get_children():
		if child is Button: _visualizer_control_buttons.append(child)
	for child in _paused_buttons.get_children():
		if child is Button: _visualizer_control_buttons.append(child)
	for child in _restart_buttons.get_children():
		if child is Button: _visualizer_control_buttons.append(child)

func setup(visualizer_name : String, sorter_name : String):
	_selected_visualizer_btn.text = tr(visualizer_name)
	_selected_sorter_btn.text = tr(sorter_name)

func sorter_finished():
	_toggle_button_group(_restart_buttons)

func set_ui_active(is_active : bool):
	for btn in _visualizer_control_buttons:
		btn.disabled = !is_active

func show_options_popup(settings):
	var instance := _options_popup_scene.instance()
	instance.connect("ok", self, "_on_options_popup_ok")
	add_child(instance)
	instance.setup(settings)

func _on_sorter_pressed():
	var instance := _sorter_popup_scene.instance()
	add_child(instance)
	instance.connect("ok", self, "_on_sorter_popup_ok")

func _on_visualizer_pressed():
	var instance := _visualizer_popup_scene.instance()
	add_child(instance)
	instance.connect("ok", self, "_on_visualizer_popup_ok")

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
			_grabber.modulate.a = 1
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

func _on_sorter_popup_ok(data : Dictionary):
	emit_signal("sorter_changed", load(data["path"]).new())
	
	_selected_sorter_btn.text = data["name"]
	_toggle_button_group(_idle_buttons)

func _on_visualizer_popup_ok(data : Dictionary):
	emit_signal("visualizer_changed", load(data["path"]).instance())
	
	_selected_visualizer_btn.text = data["name"]
	_toggle_button_group(_idle_buttons)

func _on_options_popup_ok(data : Dictionary):
	emit_signal("options_changed", data["settings"])

# after hiding the interface, hover mouse near the very top of the screen to bring it back
func _on_grabber_mouse_entered():
	if _is_hidden && _is_moving == false:
		_is_moving = true
		_grabber.modulate.a = 0
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
