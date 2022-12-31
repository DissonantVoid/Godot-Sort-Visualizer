extends Control

signal ok(data) # data : dictionary
signal cancel

onready var _error_panel : PanelContainer = $Error
onready var _error_txt : Label = $Error/HBoxContainer/Label

const _err_show_time : float = 0.3


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
	var tween : SceneTreeTween = get_tree().create_tween()
	tween.tween_property(_error_panel, "modulate:a", 1.0, _err_show_time).from(0.0)
	_error_txt.text = "Error: " + text
	_error_panel.show()
