extends MarginContainer

onready var _idle_buttons : HBoxContainer = $PanelContainer/MarginContainer/HBoxContainer/Center/Idle
onready var _running_buttons : HBoxContainer = $PanelContainer/MarginContainer/HBoxContainer/Center/Running
onready var _paused_buttons : HBoxContainer = $PanelContainer/MarginContainer/HBoxContainer/Center/Paused

const _moving_time : float = 0.85
var _is_moving : bool = false

const _options_popup_scene : PackedScene = preload("res://scenes/objects/ui_components/popups/algo_picker_options_popup.tscn")

func _on_button_clicked(button : String):
	match button:
		"options":
			var instance := _options_popup_scene.instance()
			get_tree().current_scene.add_child(instance)
			#..
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

func _on_title_input(event):
	if event is InputEventMouseButton && event.pressed && event.button_index == BUTTON_LEFT:
		pass

func _toggle_button_group(group : HBoxContainer):
	_idle_buttons.visible = (group == _idle_buttons)
	_running_buttons.visible = (group == _running_buttons)
	_paused_buttons.visible = (group == _paused_buttons)
