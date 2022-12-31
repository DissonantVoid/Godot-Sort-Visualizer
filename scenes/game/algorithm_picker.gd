extends MarginContainer

onready var _selected_algo_label : Label = $PanelContainer/MarginContainer/HBoxContainer/Center/Algorithm
onready var _idle_buttons : HBoxContainer = $PanelContainer/MarginContainer/HBoxContainer/Center/Idle
onready var _running_buttons : HBoxContainer = $PanelContainer/MarginContainer/HBoxContainer/Center/Running
onready var _paused_buttons : HBoxContainer = $PanelContainer/MarginContainer/HBoxContainer/Center/Paused

const _moving_time : float = 0.85
var _is_moving : bool = false

const _options_popup_scene : PackedScene = preload("res://scenes/objects/ui_components/popups/algo_picker_options_popup.tscn")
const _algorithms_popup_scene : PackedScene = preload("res://scenes/objects/ui_components/popups/algo_picker_algorithms_popup.tscn")

var _curren_sorter = null
var _data_to_sort : Array
var _sort_callback : FuncRef

func setup(data : Array, sort_callback : FuncRef):
	_data_to_sort = data
	_sort_callback = sort_callback

# TODO: disable input untill stup is called
func _on_button_clicked(button : String):
	match button:
		"options":
			var instance := _options_popup_scene.instance()
			get_tree().current_scene.add_child(instance)
			instance.connect("ok", self, "_on_options_popup_ok")
		"hide":
			if _is_moving: return
			_is_moving = true
			
			var tween : SceneTreeTween = get_tree().create_tween()
			tween.tween_property(self, "rect_position:y", -rect_size.y, _moving_time)
			yield(tween, "finished")
			_is_moving = false
		
		
		"start":
			_toggle_button_group(_running_buttons)
		"next":
			if _idle_buttons.visible:
				_toggle_button_group(_paused_buttons)
		"pause":
			_toggle_button_group(_paused_buttons)
		"stop":
			_toggle_button_group(_idle_buttons)
		"continue":
			_toggle_button_group(_running_buttons)
		"last":
			_toggle_button_group(_idle_buttons)

func _on_options_popup_ok(data : Dictionary):
	pass

func _on_title_input(event):
	if event is InputEventMouseButton && event.pressed && event.button_index == BUTTON_LEFT:
		var instance := _algorithms_popup_scene.instance()
		get_tree().current_scene.add_child(instance)
		instance.connect("ok", self, "_on_algorithms_popup_ok")

func _on_algorithms_popup_ok(data : Dictionary):
	_curren_sorter = load(data["path"])
	_selected_algo_label.text = data["name"]
	
	for child in _idle_buttons.get_children():
		if child is Button: child.disabled = false
	
	for child in _running_buttons.get_children():
		if child is Button: child.disabled = false
	
	for child in _paused_buttons.get_children():
		if child is Button: child.disabled = false

func _toggle_button_group(group : HBoxContainer):
	_idle_buttons.visible = (group == _idle_buttons)
	_running_buttons.visible = (group == _running_buttons)
	_paused_buttons.visible = (group == _paused_buttons)
